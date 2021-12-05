function extract_recorded(varargin)

params = set_params(varargin{:});
%disp(params);
message = params.message;

%transmission capacity in bits per second
bpf = length(params.data_bands)/params.code_len;
bps = params.Fs/params.N*bpf/(params.cancel_interf + 1)*(1 - (1-params.cancel_interf)/params.sync_block_spacing);
disp(['Bit per block: ', num2str(bpf)]);
disp(['Bit per second (b/s): ', num2str(bps)]);

%load audio file
sig_with_msg = audioread([params.audio_rec_files_path params.full_config_name '.wav']);
sig_with_msg = sig_with_msg(:,1); %use mono signal

%decode
disp('Extracting message ...');
tic;
[rec_msg, plot_data] = extract_message_mclt(sig_with_msg, params);
duration_de = toc;
disp(['Elapsed time decoding: ', num2str(duration_de)]);

corr_coeffs = xcorr(double(message),double(rec_msg(:,1)),length(rec_msg)-1);
[~,idx] = max(corr_coeffs);
offset = idx - length(rec_msg) + 1;
if(offset < 0)
    rec_msg = rec_msg(-offset:end,:);
    message2compare = message(1:min(length(message),length(rec_msg)));
elseif(offset > 1)
    message2compare = message(offset:min(length(message),length(rec_msg)+offset-1));
else
    message2compare = message(1:min(length(message),length(rec_msg)));
end

if length(rec_msg) > length(message2compare)
    rec_msg = rec_msg(1:length(message2compare),:);
end
% if length(message2compare) > length(rec_msg)
%     message2compare = message2compare(1:length(rec_msg));
% end


%only compare bits above a certain correlation coefficient
confident_bits = abs(rec_msg(:,2)) > -0.01; % make sure all are used.

%calculate and print error percentage
bit_errors = sum(rec_msg(confident_bits,1) ~= message2compare(confident_bits));
bit_error_rate = bit_errors/length(rec_msg(confident_bits));

disp([num2str(bit_errors) ' Bit Errors => Bit Error Rate (BER): ', num2str(bit_error_rate)]);

disp(['ORIGINAL: ' char(bin2dec(int2str(reshape(message2compare,8,length(message2compare)/8)')))']);
disp(['RECEIVED: ' char(bin2dec(int2str(reshape(rec_msg(:,1)   ,8,length(rec_msg(:,1))/8)')))']);

% 
% bad = message2compare ~= rec_msg(:,1);
% errors = reshape(bad,bpf,length(bad)/bpf);
% 
% i = 1;
% period = 0.5;
% num_blocks = length(errors);
% dur = length(sig_with_msg)/params.Fs;
% num_periods = dur/period;
% errors = [zeros(bpf,floor(50-offset/bpf)) errors, zeros(bpf,100-floor(50-offset/bpf))];
% 
% % p = audioplayer(sig_with_msg,params.Fs);
% % set(p,'TimerFcn',@step);
% % set(p,'TimerPeriod',period);
% % p.playblocking;
% 
% % hold off;
% 
% %plot phases/phase differences
% if(params.make_plot && ~isempty(plot_data))
%     plot_phases_figure(plot_data, 1:size(plot_data,1), params.N, params.Fs, [params.plots_path params.full_config_name]);
% end
% 
%     function step(~,~)
%         block = ceil(i/num_periods*num_blocks);
%         spy(errors(:,block:block+100));
%         hold on;
%         plot(50,1:bpf,'r','LineWidth',2);
%         hold off;
%         i = i+1;
%         refresh;
%     end

end