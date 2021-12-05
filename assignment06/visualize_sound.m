    %VISUALIZE_SOUND visualizes a sound file for a given time interval
    %   
    %   Example use:
    %   >> clear all; clear functions; close all; cd Audiocom/audio_files/;visualize_sound('MobileComp2_L',[0 10])
    %
    % Based on: M.Sc. Eng. Hristo Zhivomirov  10/29/12 %
    % Edited by: Dr.-Ing. Stefan Mangold 11/10/14    %

function visualize_sound(aWavFile,time_interval_s)
    %VISUALIZE_SOUND visualizes a sound file for a given time interval
    %   
    %   Example use:
    %   >> clear all; clear functions; close all; cd Audiocom/audio_files/;visualize_sound('MobileComp2_L',[0 10])

  warning ("off", "Octave:future-time-stamp")

  pkg load signal;
  
  [x,fs] = audioread([aWavFile '.wav']);   % get a section of the sound file

  if (min(time_interval_s)==0)
    time_interval_s(1) = time_interval_s(1) + 0.001;
  end

  time_interval_samples = round(time_interval_s * fs);

  [x,fs] = audioread([aWavFile '.wav'], time_interval_samples);

  x = x(:,1); % get the first channel
  xmax = max(abs(x)); % find the maximum value
  x = x/xmax; % scaling the signal

  N = length(x); % time & discretization parameters
  t=(0:N-1)/fs; 

  aLineWidth=2;
  FontSize=12;
  aMarkerSize=7;

  figName = ([ aWavFile '_time_domain']);
  figure('NumberTitle', 'on', 'Name', figName,'PaperPositionMode', 'auto','Position', [20 400 700 300],'Pointer', 'arrow');
  box on; set(gcf, 'color', 'white'); set(gcf, 'InvertHardCopy', 'off'); set(gca,'Position',[0.1,0.14,0.88,0.82]);
  plot(t,x);
  xlim([0 max(t)]); ylim([-1.1*max(abs(x)) 1.1*max(abs(x))]);
  grid on;
  xlabel('Time [s]');
  ylabel('Normalized Amplitude');
  set(gca,'FontSize',FontSize);
  set(gca,'FontName','Helvetica'); 

  figName = ([aWavFile '_freq_domain']);
  figure('NumberTitle', 'on', 'Name', figName,'PaperPositionMode', 'auto','Position', [120 300 700 300],'Pointer', 'arrow');
  box on; axis on; set(gcf, 'color', 'white'); set(gcf, 'InvertHardCopy', 'off'); set(gca,'Position',[0.1,0.14,0.88,0.82]);
				% FFT

  win = hanning(N);
  K = sum(win)/N; % coherent amplification of the window
  X = abs(fft(x.*win)); % fast fourier transform
  Xm = X(1:round(N/2)); % getting a first half of the spectrum without Nyquist frequency at N/2+1
  Xm = Xm/(round(N/2)); % computing of the amplitudes 
  Xm(1,1) = Xm(1,1)/2; % correction of the DC component
  Xm = Xm/K; % correction due to coherent amplification
	     % plotting of the spectrum
  f = (0:round(N/2)-1)*fs/N;
  plot(f/1000, 20*log10(Xm))
  xlim([min(f/1000) max(f/1000)])
  grid on
  xlabel('Frequency [kHz]')
  ylabel('Amplitude [dBV]')
  set(gca,'FontSize',FontSize);
  set(gca,'FontName','Helvetica'); 


  figName = ([ aWavFile '_spectrogram']);
  figure('NumberTitle', 'on', 'Name', figName,'PaperPositionMode', 'auto','Position', [220 200 700 300],'Pointer', 'arrow');
  set(gcf, 'color', 'white'); set(gcf, 'InvertHardCopy', 'off'); set(gca,'Position',[0.09,0.14,0.84,0.82]);

  specgram(x,512,fs) % 97% overlapping
  xlabel('Time [s]')
  ylabel('Frequency [kHz]')
  box on; h = colorbar;
  ylabel(h, 'Magnitude [dB]');
    
  set(gca,'YTickLabel',get(gca,'YTick')/1000);
  set(gca,'FontSize',FontSize);
  set(gca,'FontName','Helvetica'); 
