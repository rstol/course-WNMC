function block_selection = select_blocks(MCLT, params)

num_data_bands = length(params.data_bands);     % number of subbands per MCLT block
noblocks = size(MCLT,2);                        % number of MCLT blocks in given signal
even_noblocks = mod(noblocks,2) == 0;           % number of even MCLT blocks in given signal

if(params.block_selection)
    % examine the carrier for blocks suited for embedding data
    abs_MCLT = abs(MCLT(params.data_bands(1)-1:params.data_bands(end)+1,:)).^2;
    median_coeff = median(abs_MCLT(:));
    block_selection = single(sum(abs_MCLT > median_coeff*params.T1,1)/(2*num_data_bands+1) > params.T2);

    % go through block_select vector and find connected sequences of useful blocks
    % and mark them with 2 (reference block), 3 and -3 (delimiter blocks),
    % 1 (data block), 0 (empty block)
    % bad blocks will always be empty, sequences of good blocks will have a
    % reference block at the beginning. Then comes a start delimiter block
    % followed by a number of data blocks and an end delimiter block
    state = 0;
    min_length = 10;
    block_selection(1) = 0;
    if(even_noblocks)
        block_selection(end-1) = 0;
    end
    block_selection(end) = 0;
    next = block_selection(3);
    for i=3:2:length(block_selection)-3
        prev = next;
        curr = block_selection(i);
        next = block_selection(i+1);
        is_good_block = (prev && curr && next);
        if(is_good_block && state == 0)
            start_idx = i-1;
            state = 1;
        elseif(~is_good_block && state == 1)
            if((i - start_idx + 1) < min_length)
                block_selection(start_idx:i) = 0;
            else
                if(params.phase_coding_method == 2)
                    block_selection(start_idx+1) = 2;
                    block_selection(start_idx+3) = 3;
                else
                    block_selection(start_idx+1) = 3;
                end
                block_selection(i-2) = -3;
                block_selection(i) = 0;
            end
            state = 0;
        elseif(~is_good_block && state == 0)
            block_selection(i-1:i) = 0;
        end
    end

    % last step
    i = i+2;
    prev = next;
    curr = block_selection(i);
    next = block_selection(i+1);
    is_good_block = (prev && curr && next);
    if(is_good_block && state == 0)
        block_selection(i) = 0;
    elseif(~is_good_block && state == 0)
        block_selection(i-1:i) = 0;
    elseif(state == 1)
        if((i - start_idx + 1) < min_length)
            block_selection(start_idx:i) = 0;
        else
            if(params.phase_coding_method == 2)
                block_selection(start_idx+1) = 2;
                block_selection(start_idx+3) = 3;
            else
                block_selection(start_idx+1) = 3;
            end
            
            if(is_good_block)
                block_selection(i) = -3;
            else
                block_selection(i-2) = -3;
                block_selection(i) = 0;
            end
        end
    end
    
    used_blocks_perc = sum(block_selection(3:2:noblocks-2) == 1)/floor((noblocks-3)/2);
    disp(['Percentage of selected blocks: ', num2str(used_blocks_perc)]);
else
    % block selection is not active
    % use the 3rd block as the reference block (2) and the following ones as
    % data blocks(2). if sync blocks are used, mark them (-1) 
    block_selection = ones(1,noblocks);
    block_selection(1) = 0;
    
    if(params.phase_coding_method == 2)
        block_selection(3) = 2;
        if(params.use_sync_blocks)
            block_selection(5:params.sync_block_interval*2:end) = -1;
        end
    end
    
    block_selection(end) = 0;
    if(mod(noblocks, 2) == 0)
        block_selection(end-1) = 0;
    end
end

end