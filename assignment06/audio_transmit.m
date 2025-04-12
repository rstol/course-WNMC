function audio_transmit(aTextMessage,aSoundFile)
%TRANSMIT embeds data into a song
%   
%   Example use:
%   >>  audio_transmit('message.txt','hello.wav')

disp(' ');
disp('Mobile Computing: Audiocom transmitter.');

cd Transform

%% MODIFY HERE
embed_and_save('mono','message',aTextMessage, 'theSoundFile',aSoundFile, 'redundancy_coding',true,'redundancy_factor',3)

%%
cd ..

end

