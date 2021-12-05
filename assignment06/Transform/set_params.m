function params = set_params(varargin)
% SET_PARAMS - set parameters for phase coding
%
%   param_struct = SET_PARAMS('paramName1',value1, 'paramName2', value2, ..., 'paramNameN', valueN)
%
%   Sets the given parameters to the given values, the other parameters will be set to their default values.
%   Please refer to the source to learn about available parameters and their default values
%   The parameters will be returned as a struct.
%

% paths
audio_files_path = ['..' filesep];
audio_msg_files_path = ['..' filesep];
audio_rec_files_path = ['..' filesep 'Out' filesep];
plots_path = ['..' filesep 'Plots' filesep];
results_path = ['..' filesep 'Results' filesep];
imp_resp_path = ['..' filesep 'Imp_resp' filesep];

% general parameters
filename = 'carrier';                   % default filename
message = ones(1e6,1);                  % default message
Fs = 44100;                             % sampling rate
N = 4096;                               % block size
lower_freq_limit = 5900;                % lower data frequency limit
upper_freq_limit = 10050;               % upper data frequency limit
code = [-1 1 -1 1]';                    % spreading code
use_sync_blocks = false;                % use packets -> sync code blocks at the start of each packet (decoding only implemented in iOS app)
%sync_code = [1 -1 -1 1]';               % spreading code to mark start of a packet
%sync_block_interval_samples = 20480;    % number of samples between sync code blocks
sync_code = [1 -1 1 -1]';               % spreading code to mark start of a packet
sync_block_interval_samples = N;    % number of samples between sync code blocks
precompiledParametersForSpeedUp = false;


% plotting parameters
make_plot = false;     % enable plotting
plot_range_min = 100; % min block number
plot_range_max = 200; % max block number

% encoding paramters
redundancy_coding = true;              % redundancy coding (repetition codes)
redundancy_factor = 3;                  % each bit is repeated this number of times
crc_polynomial = logical([1 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1]'); % x^16+x^12+x^5+1, MSB first

% decoding parameters
impulse_response = '';                  % simulate transmission over an acoustic channel before decoding
sim_daad_conv = false;                  % simulate digital-analog-analog-digital conversion with shift of 0.5 samples (worst case)
write_wav = true;                       % write files to disk
write_sim_wav = false;                  % write channel simulated file to disk                     
write_statistics = false;               % write statistics file to disk
cancel_interf = true;                   % interference cancellation (always on if phase_coding_method 1 or 2 is used)

phase_coding_method = 2;                % phase coding method
                                        % 0: absolute coding
                                        % 1: subband relative coding
                                        % 2: block relative coding
block_selection = false;                 % block selection: use only certain (strong) blocks for data 
                                        % thresholds that determine if a block is used for data embedding or not. the values should be in the range of [0,1].
T1 = 0.1;                               % squared coefficients bigger than T1 times the median of all squared coefficients are valid
T2 = 0.8;                               % if more than T2 times the number of coefficients in a block are valid, the block is valid
T3 = 0.2;                               % determines the minimum amount of correlation with the start/end block delimiter for a block to mark the start/end of a data block
num_sync_coeffs = 50;                   % number of sync offset positions taken into account for verification
num_sync_runs = 30;                     % number of verification runs for the largest sync coefficients


% new input parser to parse params
p = inputParser;

% setup parser and add default params
p.addParamValue('audio_files_path',audio_files_path,@(x) exist(x,'dir'));
p.addParamValue('audio_msg_files_path',audio_msg_files_path,@(x) exist(x,'dir'));
p.addParamValue('audio_rec_files_path',audio_rec_files_path,@(x) exist(x,'dir'));
p.addParamValue('plots_path',plots_path,@(x) exist(x,'dir'));
p.addParamValue('results_path',results_path,@(x) exist(x,'dir'));
p.addParamValue('imp_resp_path',imp_resp_path,@(x) exist(x,'dir'));
p.addParamValue('theSoundFile',filename);
p.addParamValue('message',message);
p.addParamValue('Fs',Fs,@(x) isnumeric(x) && any(x == [11025,22050,44100,88200,12000,24000,48000,96000]));
p.addParamValue('N',N,@(x) isnumeric(x) && any(x == [256,512,1024,2048,4096,8192,16384]));
p.addParamValue('lower_freq_limit',lower_freq_limit,@(x) isnumeric(x) && x>0 && x<=p.Results.Fs/2);
p.addParamValue('upper_freq_limit',upper_freq_limit,@(x) isnumeric(x) && x>0 && x<=p.Results.Fs/2 && x>p.Results.lower_freq_limit);
p.addParamValue('code',code,@(x) isvector(x));
p.addParamValue('sync_code',sync_code,@(x) isvector(x));
p.addParamValue('use_sync_blocks',use_sync_blocks,@(x) islogical(x));
p.addParamValue('sync_block_interval_samples',sync_block_interval_samples, @(x) isnumeric(x));
p.addParamValue('cancel_interf',cancel_interf, @(x) islogical(x));
p.addParamValue('phase_coding_method',phase_coding_method, @(x) isnumeric(x) && any(x == [0,1,2]));
p.addParamValue('block_selection',block_selection, @(x) islogical(x));
p.addParamValue('T1',T1,@(x) isnumeric(x) && x>=0 && x<=1);
p.addParamValue('T2',T2,@(x) isnumeric(x) && x>=0 && x<=1);
p.addParamValue('T3',T3,@(x) isnumeric(x) && x>=0 && x<=1);
p.addParamValue('redundancy_coding',redundancy_coding, @(x) islogical(x));
p.addParamValue('redundancy_factor',redundancy_factor, @(x) isnumeric(x));
p.addParamValue('crc_polynomial',crc_polynomial, @(x) islogical(x));
p.addParamValue('num_sync_coeffs',num_sync_coeffs, @(x) isnumeric(x));
p.addParamValue('num_sync_runs',num_sync_runs, @(x) isnumeric(x));
p.addParamValue('make_plot',make_plot, @(x) islogical(x));
p.addParamValue('plot_range_min',plot_range_min, @(x) isnumeric(x));
p.addParamValue('plot_range_max',plot_range_max, @(x) isnumeric(x));
p.addParamValue('impulse_response',impulse_response, @(x) exist([p.Results.imp_resp_path x '.mat'],'file') || strcmp(x,'') || strcmp(x,'0m'));
p.addParamValue('sim_daad_conv',sim_daad_conv, @(x) islogical(x));
p.addParamValue('write_wav',write_wav, @(x) islogical(x));
p.addParamValue('write_sim_wav',write_sim_wav, @(x) islogical(x));
p.addParamValue('write_statistics',write_statistics, @(x) islogical(x));
p.addParamValue('precompiledParametersForSpeedUp',precompiledParametersForSpeedUp, @(x) islogical(x));

p.parse(varargin{:});    
params = p.Results;

if(ischar(params.message))
    %read message from file
    
    cd ..;
    urlname = ['file:///' fullfile(pwd,params.message)];    
    cd Transform;
    try
        str = urlread(urlname);
    catch err
        disp(err.message)
    end
    
    if strncmp(str,'[',1)
        %closed caption in file for LucidDreams
        params.closed_caption_active = true;
        params.message = str;
    else
        %normal text in file
        %convert to bit vector
        params.closed_caption_active = false;
        bits = dec2bin(unicode2native(str,'UTF-8'),8) - '0';
        %bits = bits(:,end:-1:1); %reverse bit order
        bits = bits';
        params.message = bits(:); 
    end
    
else
    %transpose if necessary
    params.message = params.message(:);
end

if(strcmp(params.impulse_response,''))
    params.impulse_response = '0m';
end

%transpose if necessary
params.code = params.code(:);
params.sync_code = params.sync_code(:);

% set further parameters according to the chosen configuration
if(params.phase_coding_method && ~params.cancel_interf)
    params.cancel_interf = true;
    warning('MATLAB:set_params','Interference cancellation (cancel_interf) was automatically turned on for the phase difference method to work');
end
    
if(params.cancel_interf)
    freq_band_spacing = 2;
    params.block_spacing = 2;
    params.sync_block_spacing = 2;
else
    freq_band_spacing = 1;
    params.block_spacing = 1;
    params.sync_block_spacing = 10;
    params.block_selection = false; % can't do block selection here
end

% build spreading code sequences for the message
params.code_len = length(params.code);
assert(length(params.code) == length(params.sync_code));
params.sync_block_interval = floor(params.sync_block_interval_samples/params.N);

% convert frequency limits to indices for mclt subbands
lower_freq_index = ceil(params.lower_freq_limit/(params.Fs/2)*params.N); 
upper_freq_index = floor(params.upper_freq_limit/(params.Fs/2)*params.N);
bands = lower_freq_index:freq_band_spacing:upper_freq_index;
bands = bands(1:end-mod(length(bands), params.code_len));

params.data_bands = bands;
params.sync_bands = params.data_bands;
params.sync_seq = 2*((rand(length(params.sync_bands),1) > 0.5)-0.5);
params.ref_seq = -ones(length(bands),1);
num_codes = length(bands)/params.code_len;
half_num_codes = floor(num_codes/2);
params.packet_size_bytes = params.sync_block_interval_samples/params.N*num_codes/8;

% delimiters for block selection (obsolete)
params.start_delimiter = repmat([ones(params.code_len,1); -ones(params.code_len,1)],half_num_codes,1);
if(2*half_num_codes < num_codes)
    params.start_delimiter = [params.start_delimiter; ones(params.code_len,1)];
end
params.end_delimiter = -params.start_delimiter;
params.packet_size = params.packet_size_bytes*8;

real_redundancy_factor = 1;
if params.redundancy_coding
    real_redundancy_factor = params.redundancy_factor;
end

% unique name for this configuration
params.config_name = [...
    params.theSoundFile ...
    '_N-' num2str(params.N) ...
    '_CI-' num2str(params.cancel_interf) ...
    '_PC-' num2str(params.phase_coding_method) ...
    '_LF-' num2str(params.lower_freq_limit) ...
    '_HF-' num2str(params.upper_freq_limit) ...
    '_CL-' num2str(params.code_len) ...
    '_RF_' num2str(real_redundancy_factor) ...
];
%params.full_config_name = [params.config_name '_IR-' num2str(params.impulse_response)];
params.full_config_name = [params.config_name '_mono'];

end
