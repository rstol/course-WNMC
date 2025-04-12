function embed_and_save(audioFormat, varargin)

% create params struct according to varargig
% (defaults for unspecified)
params = set_params(varargin{:});

% extract message and carrier filename from params struct
message = params.message;
filename = params.theSoundFile;
precompiledData = params.precompiledParametersForSpeedUp;


if(precompiledData)
    settingsFileName = ['load ',filename,'Settings.mat'];
    eval(settingsFileName);
    
else
    % mono or stereo? (set correct config name)
    if (strcmp(audioFormat,'mono'))
        params.config_name = [params.config_name '_mono'];
        params.full_config_name = [params.full_config_name '_mono'];
    end
    
    % compute statistics
    bpb = length(params.data_bands)/params.code_len;
    bps = params.Fs/params.N*bpb/(params.block_spacing)*(1 - (1-params.cancel_interf)/params.sync_block_spacing);
    data_percentage = (params.packet_size/params.redundancy_factor - (length(params.crc_polynomial)-1))/params.packet_size;
    disp(['Bits per block: ', num2str(bpb)]);
    disp(['Bits per second (b/s): ', num2str(bps)]);
    if(params.redundancy_coding)
        disp(['Data bits per block: ', num2str(data_percentage*bpb)]);
        disp(['Data bits per second (b/s): ', num2str(data_percentage*bps)]);
    end
    
    %load audio file (dolby, stereo or mono)
    if(strcmp(audioFormat,'dolby'))
        carrier(:,1) = audioread([params.audio_files_path  filename '.L' '.wav']);
        carrier(:,2) = audioread([params.audio_files_path  filename '.R' '.wav']);
        carrier(:,3) = audioread([params.audio_files_path  filename '.C' '.wav']);
        carrier(:,4) = audioread([params.audio_files_path  filename '.Ls' '.wav']);
        carrier(:,5) = audioread([params.audio_files_path  filename '.Rs' '.wav']);
    else
        carrier = audioread([params.audio_files_path  filename '.wav']);
        if(strcmp(audioFormat,'mono'))
            % use only left track in case original file is stereo, but we want to process only one channel (mono).
            carrier = carrier(:,1);
        end
    end
    
    % sound(carrier,44100,16)
    
    %cut zeros at the beginning and the end of the audio file
    i = 1;
    while(~all(carrier(i,:)))
        i = i+1;
    end
    j = length(carrier);
    while(~all(carrier(j,:)))
        j = j-1;
    end
    % save beginning and ending for later
    beginning = carrier(1:i-1,:);
    ending = carrier(j+1:end,:);
    
    % cut beginning and ending
    carrier = carrier(i:j,:);
    
    num_channels = size(carrier,2);
    
end

% embed message into audio file
disp('Embedding message ...');
tic;
for i=1:num_channels
    disp(strcat('Channel: ',num2str(i)));
    carrier(:,i) = embed_message_mclt(carrier(:,i), message, params);
end
duration_en = toc;

% put back beginning and ending
carrier = [beginning; carrier; ending];

%limit signal (prevent clipping)
wav_limit = 0.99996948242188;
clipping_mask = abs(carrier) > wav_limit;
carrier(clipping_mask) = wav_limit*sign(carrier(clipping_mask));
disp(['Elapsed time encoding (in seconds): ', num2str(duration_en)]);

%write audio file with message to disk
if(params.write_wav)
    disp('Writing audio file to disk ...');
    
    [aPathstr,aName,anExt] = fileparts(params.config_name);
    
    if(strcmp(audioFormat,'dolby'))
        audiowrite([params.audio_rec_files_path aName '_L.wav'], carrier(:,1), params.Fs);
        audiowrite([params.audio_rec_files_path aName '_R.wav'], carrier(:,2), params.Fs);
        audiowrite([params.audio_rec_files_path aName '_C.wav'], carrier(:,3), params.Fs);
        audiowrite([params.audio_rec_files_path aName '_Ls.wav'], carrier(:,4), params.Fs);
        audiowrite([params.audio_rec_files_path aName '_Rs.wav'], carrier(:,5), params.Fs);
    else
        audiowrite([params.audio_rec_files_path aName '.wav'], carrier, params.Fs);
    end
end
