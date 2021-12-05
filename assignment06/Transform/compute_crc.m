function crc = compute_crc(bits,polynomial)

% computes the cyclic redundany code over the finite field GF(2) for the given bits and generator
% polynomial 

crc_len = length(polynomial)-1;
bits_len = length(bits);
bits = [bits; zeros(crc_len,1)];
for i = 1:bits_len
    if(bits(i) == 1)
        bits(i:i+crc_len) = xor(bits(i:i+crc_len), polynomial);
    end
end
crc = bits(end-(crc_len-1):end);

end