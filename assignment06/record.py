import sounddevice as sd
import soundfile as sf

samplerate = 44100  # Hertz
duration = 80  # seconds
filename = 'output.wav'

mydata = sd.rec(int(samplerate * duration), samplerate=samplerate,
                channels=1, blocking=True)
sf.write(filename, mydata, samplerate)