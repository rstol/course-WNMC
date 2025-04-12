function decoded_message = decode_message(corr_coeffs, params)

% decodes a redundancy coded message and checks its crc
% currently invalid messages are not marked

decoded_message = [];
len = length(corr_coeffs);
crc_len = length(params.crc_polynomial)-1;
content_len = params.packet_size/params.redundancy_factor - crc_len;
m = mod(len, params.packet_size);
len = len - m;
corr_coeffs = corr_coeffs(1:len);

for i=1:params.packet_size:len
    probs = corr_coeffs(i:i+params.packet_size-1);
    probs_sum = sum(reshape(probs,content_len+crc_len, params.redundancy_factor),2);
    bits = logical(probs_sum > 0);
    crc = compute_crc(bits,params.crc_polynomial);
    error = sum(crc) > 0;
    %if(~error)
    decoded_message = [decoded_message; bits(1:content_len), probs_sum(1:content_len)/params.redundancy_factor];
    %end
end

end