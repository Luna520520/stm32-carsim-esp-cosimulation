function [error, valid, matched_local] = match_mz(local_mz, tx_seq, remote_mz, rx_seq)
%#codegen
persistent mz_cache seq_cache slot_valid
if isempty(mz_cache)
    mz_cache = zeros(256,1);
    seq_cache = zeros(256,1,'uint16');
    slot_valid = false(256,1);
end
tx_idx = double(bitand(uint16(tx_seq),uint16(255))) + 1;
mz_cache(tx_idx) = double(local_mz);
seq_cache(tx_idx) = uint16(tx_seq);
slot_valid(tx_idx) = true;
rx_idx = double(bitand(uint16(rx_seq),uint16(255))) + 1;
if slot_valid(rx_idx) && seq_cache(rx_idx) == uint16(rx_seq) && uint16(rx_seq) ~= uint16(0)
    matched_local = mz_cache(rx_idx);
    error = matched_local - double(remote_mz);
    valid = true;
else
    matched_local = 0;
    error = 0;
    valid = false;
end
