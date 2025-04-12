# Assignment 6
Romeo Stoll, 19-917-749

## Step 1
1. Does acoustic communication rely on electromagnetic waves?

	No.
2. How fast do acoustic waves travel through the air (estimate)?

	343 m/s
3. When sampling at 10 kHz, what is the resolution that a time-of-flight distance measurement could achieve in theory (estimate, leave out implementation details)?

	The resolution would be 3.43cm.   

4. At the same sampling rate, what would be the precision with electromagnetic waves? 

	Assuming that electromagnetic waves travel at the speed of light (in vacuum), the resolution is: 30km. It is much less precise for this sampling rate than acoustic waves.

5. What changes if the sampling rate is doubled to 20 kHz instead (for both, acoustic and electromagnetic waves)?

	The resolution get's more precise by a factor of two for both acoustic and electromagnetic waves.

6. What is the typical bandwidth (measured in Hertz) of an acoustic sound that is used in media such as broadcast, television, cinemas, or recorded with a cellphone?

	44100 Hz
7. What is the frequency range at which humans perceive sound (from ... to ..., measured in Hertz)?

	From 20 Hz to about 20 kHz. For older humans the higher bound is lower, depending on the age.

## Step 2
1. Is MobileComp1 or MobileComp2 more suited to carry the data?
	
MobileComp2 is more suited to carry the data, as it has almost no time periods where the sound is quiet. This can be seen by looking at the amplitude in the time domain graph, where MobileComp1 has parts where the amplitude is very small (quiet) and MobileComp2 has a high amplitude(loud) most of the time. 

__Graphs for MobileComp1__

![](./figures/step2/MobileComp1_time_domain.png)
![](./figures/step2/MobileComp1_freq_domain.png)
![](./figures/step2/MobileComp1_spectrogram.png)

__Graphs for MobileComp2__

![](./figures/step2/MobileComp2_time_domain.png)
![](./figures/step2/MobileComp2_freq_domain.png)
![](./figures/step2/MobileComp2_spectrogram.png)

2. Which frequencies should be used to encode the data?
	
	The higher frequencies right at about 20kHz could be used as the natural high-frequency hearing loss causes humans to not perceive changes in those high frequencies. 

3. Is there a perceivable change of the audio file? Does the sound quality remain?

	In MobComp2 amost no change can be perceived and the sound quality is similar. The MobComp1 did sound a little bit worse (some distorted echoes/sounds are present) as without the embedded message and the quality is a bit worse. 

## Step 3
1. For both sound files: Are there bit errors? Why?

	MobileComp1 doesn't have any bit errors. MobileComp2 has 6 bit errors and a BER of ~0.1%. This is because at the start of MobileComp2 is silence, and that's where the bit errors occur. During silence we cannot transmit data bits.

2. Over the air measurements:

	I took the measurements with different microphones and at 44100 Hz in an indoor setting. The bit error rate was always at about 50%. I don't know why it didn't work better. The following is an example log from applying audio_receive_and_compare to one over the air recording:

__Log__
```Mobile Computing: Audiocom receiver.
urlname = file:///Users/romeostoll/Documents/CS/ETH/Semester5/MobileComp/assignment06/Messages/kinglouie.txt
Bit per block: 96
Bit per second (b/s): 516.7969
Extracting message ...
block offset: 883
Sync offset: 1
Max sync coefficient: 0.23378
Elapsed time decoding: 14.2317
3199 Bit Errors => Bit Error Rate (BER): 0.51266
ORIGINAL: Bu-ba-do-do-do-be-do - Now I'm the king of the swingers, - Oh, the jungle VIP, - I've reached the top and had to stop, - And that's what botherin' me. - I wanna be a man, mancub, - And stroll right into town, - And be just like the other men, - I'm tired of monkeyin' around! - Oh, oobee doo, (Oop-de-we) - I wanna be like you, (Hop-de-do-be-do-bow) - I wanna walk like you, - Talk like you, too! (We-be-de-be-de-boo) - You'll see it's true, (Shoo-be-de-do) - An ape like me, (Scooby-do-be-do-be) - Can learn to be human too. - Now don't try to kid me, mancub, - I made a deal with you. - What I desire is man's red fire, - To make my dream come true! - Give me the secret, mancub, - Come on, - Clue me what to do, - Give me the power of man's red flower, - So I can be like you!
�x�\󏮞槃Q�}��!T�mD=�]{b�N�Q*��U��$�kw�   b�}+�[��f-���Y�
     �(�]r��xWS�W8��z��xC��[H
                             �T8y��\��W^�p����Uc5L߃I�d�=ty=](���$)��x�<?�mr�!��\� Ч�1���=��En|
               J}+Ӿ�����d��J>x��C��[��=��0y�Q���7zR\E��
ǶS@��L�n�^�z���E���^��<ٽ${āH9�540�f�V}z]
��"FĜ6,��p��� �������:�)m!�
��Q��z&�EFj~=>B[5Э�I���mY`b̙j���+�T1�$��_��9�᰾\�pB"M���7��<�|��=��՜��l�'����I�8���i�TpXI�
                                      2���M@
i�`WӚ׷�8���#HvR�q�#,탆ĺ�7[�0=7�Z�^��9�I��\!)�6��#|�8h%��Jh�Rl]�;�C���Izp�ؙ�M��ڂ�:�S�>�1�R�/R�}gȅ������3?ˊ�   nvϻY���!-�-�XI؋ٝ���%��F��TԎ��Gy(�k���T���?ذ���n?```