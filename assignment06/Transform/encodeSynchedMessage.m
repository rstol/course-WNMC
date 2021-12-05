function [encoded_message,block_selection]= encodeSynchedMessage(params, block_selection)
% %% message to encode including time stamps and text
% %% system parameters
% %% index of time blocks that will be used to carry data
    
    nofCaptions = length(strfind(params.message,'['));

    InputText=textscan(params.message,'[%f:%f:%f]{%s',nofCaptions,'delimiter','}'); % Read header line
    assert(size(InputText{1},1) == nofCaptions,'closed captions file has wrong format.');
    
    startingBlocks = convertTimeIntoBlock(InputText,params);
    messages_Cell = InputText{4};
    
    bpb = length(params.data_bands)/params.code_len;
    bps = params.Fs/params.N*bpb/(params.block_spacing)*(1 - (1-params.cancel_interf)/params.sync_block_spacing);
    data_percentage = (params.packet_size/params.redundancy_factor - (length(params.crc_polynomial)-1))/params.packet_size;
    
    numDataBytesPerBlock = floor((data_percentage*bpb)/8);
    assert(numDataBytesPerBlock > 0 ,'a Block has to contain at least 1 Byte.');
    
    encoded_message = zeros(8,(size(block_selection,2)*numDataBytesPerBlock)/2);
    
    nofMessages = size(messages_Cell,1);
    next_msg_index = 2;
    index_inside_current_message = 1;
    size_of_current_message = size(messages_Cell{next_msg_index-1},2);
    
    caracter_count = 1;
    
    for i=1:2:size(block_selection,2)
        %next message needs to be triggered
        if i>startingBlocks(next_msg_index,1)
            if index_inside_current_message < size_of_current_message
                lastwarn('message %n had to be cut',next_msg_index-1);
            end
            next_msg_index = next_msg_index + 1;
            index_inside_current_message = 1;
            size_of_current_message = size(messages_Cell{next_msg_index-1},2);
            
        end
        %run out of messages
        if next_msg_index > nofMessages+1
            %should never happen
            break;
        end
        if block_selection(1,i) == 1; %block found that can contain data.
            for j=1:numDataBytesPerBlock
                if i<startingBlocks(1,1)
                    tempMat = zeros(1,8);
                elseif index_inside_current_message > size_of_current_message
                    %message to short start padding
                    tempMat = dec2bin(unicode2native(messages_Cell{next_msg_index-1}(size_of_current_message),'UTF-8'),8) - '0';
                else
                    %append next caracter
                    tempMat = dec2bin(unicode2native(messages_Cell{next_msg_index-1}(index_inside_current_message),'UTF-8'),8) - '0';
                end
                encoded_message(:,caracter_count) = tempMat;
                caracter_count = caracter_count +1;
                index_inside_current_message = index_inside_current_message + 1;
            end
        end
    end

    encoded_message = reshape(encoded_message,size(encoded_message,1)*size(encoded_message,2),1);
end


function block_time_delimiters = convertTimeIntoBlock(InputText,params)
    inputCell = InputText(1:3);
%   stringCell = InputText(4);
    %crc_len = length(params.crc_polynomial)-1; %bit  
    %redundancy = params.redundancy_factor;
  
    num_time_stamps = size(inputCell{1},1);
    block_time_delimiters = -1*ones(num_time_stamps+1,2);
    for i=1:num_time_stamps
    
        hour = inputCell{1}(i);
        minute = inputCell{2}(i);
        seconds = inputCell{3}(i);
        
        block_time = hour*3600 + minute *60 + seconds;
        secsPerBlock = params.N/params.Fs;
        
        start_block = block_time / secsPerBlock;
        block_time_delimiters(i,1) = floor(start_block);
        
        %%count size of string
%         line = stringCell{1}(i); line = line{1};
%         size_bit = lenght(line)*8;
%         payload_per_block = 96/redundancy - crc_len
    end
    block_time_delimiters(num_time_stamps+1,1) = intmax('int32');
end