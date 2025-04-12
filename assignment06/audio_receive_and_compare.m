function audio_receive_and_compare(aTextMessage,aSoundFile)


disp('Mobile Computing: Audiocom receiver.');

cd Transform

%% MODIFY HERE
extract_recorded('message',aTextMessage, 'theSoundFile',aSoundFile, 'redundancy_coding',true,'redundancy_factor',3)

cd ..

end

