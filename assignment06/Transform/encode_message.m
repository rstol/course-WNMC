function encoded_message = encode_message(message, params)

message_len = length(message); % bit
crc_len = length(params.crc_polynomial)-1; % bit
content_len = params.packet_size/params.redundancy_factor - crc_len; % bit

packet_idx = 1:content_len:message_len; 
m = mod(message_len,content_len);
message = [message; zeros(content_len-m,1)]; %padding to packet_size
%number of packets to embed
num_packets = numel(packet_idx);
num_encoded_bits = num_packets*params.packet_size;
encoded_message = zeros(num_encoded_bits,1);
% go through message, compute crc and construct reduncancy coded
% message
j = 1;
%progress bar
h = waitbar(0,'Encoding message ...');

for i=packet_idx
    bits = message(i:i+content_len-1);
    crc = compute_crc(bits,params.crc_polynomial);
    encoded_message(j:j+params.packet_size-1) = repmat([bits; crc],params.redundancy_factor,1);
    j = j + params.packet_size;
    if(mod(i,10000))
        waitbar(i/message_len);
    end
end
close(h);
end