function fix_stm32_can_fifo_release_hook(modelName)
% Remove the second FIFO release emitted by the STM32 Hardware Interrupt
% block. MW_CAN_ReceiveMessage calls HAL_CAN_GetRxMessage, which already
% releases exactly one FIFO entry. Releasing RFOM0 again drops the next CAN
% frame when messages are queued back-to-back.

if nargin < 1 || isempty(modelName)
    % PostCodeGenCommand executes with pwd set to this build's *_ert_rtw
    % folder. Discover the generated model source instead of using a name
    % baked into the callback, so Save As / model renaming stays buildable.
    candidates = dir(fullfile(pwd, '*.c'));
    matchingFiles = strings(0, 1);
    for index = 1:numel(candidates)
        candidate = fullfile(candidates(index).folder, candidates(index).name);
        candidateText = fileread(candidate);
        if contains(candidateText, 'MW_CAN_ReceiveMessage') && ...
                contains(candidateText, 'CAN1 RX FIFO0 MSG pending')
            matchingFiles(end + 1, 1) = string(candidate); %#ok<AGROW>
        end
    end
    assert(numel(matchingFiles) == 1, ...
        'Expected one generated CAN model source in %s, found %d.', ...
        pwd, numel(matchingFiles));
    sourceFile = char(matchingFiles);
else
    build = RTW.getBuildDir(modelName);
    sourceFile = fullfile(build.BuildDirectory, [modelName '.c']);
end

assert(isfile(sourceFile), 'Generated model source not found: %s', sourceFile);

text = fileread(sourceFile);
marker = 'FIFO release suppressed: HAL_CAN_GetRxMessage already releases one entry.';
if contains(text, marker)
    fprintf('CAN_FIFO_PATCH_ALREADY_PRESENT=%s\n', sourceFile);
    return;
end

pattern = ['(?m)^[ \t]*/\* Clear occurred CAN1 RX FIFO0 MSG pending event \*/\r?\n' ...
    '[ \t]*SET_BIT\(CAN1->RF0R,CAN_RF0R_RFOM0\);\r?\n'];
matches = regexp(text, pattern, 'match');
assert(numel(matches) == 1, ...
    'Expected exactly one generated CAN FIFO release, found %d in %s', ...
    numel(matches), sourceFile);

receiveAt = strfind(text, 'MW_CAN_ReceiveMessage');
releaseAt = strfind(text, 'SET_BIT(CAN1->RF0R,CAN_RF0R_RFOM0)');
assert(~isempty(receiveAt) && numel(releaseAt) == 1 && receiveAt(1) < releaseAt(1), ...
    'Generated ISR shape changed; refusing an unsafe patch.');

replacement = sprintf('    /* %s */\n', marker);
patched = regexprep(text, pattern, replacement, 'once');
fid = fopen(sourceFile, 'wt');
assert(fid ~= -1, 'Cannot open generated source for update: %s', sourceFile);
closer = onCleanup(@() fclose(fid)); %#ok<NASGU>
count = fwrite(fid, patched, 'char');
assert(count == numel(patched), 'Incomplete write while patching %s', sourceFile);
fprintf('CAN_FIFO_PATCH_APPLIED=%s\n', sourceFile);
end
