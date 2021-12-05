import serial
import time
import numpy as np
from matplotlib import pyplot as plt

def send_data(arduino, msg, recv_addr):
  arduino.write(f'm[{msg}\0,{recv_addr}]\n'.encode()) #send message to device with given address

def padded(msg, size): #payload size -1 to accomodate for the \0-termination.
  if size == 1: #lower with msg[-padlen:] does not work for size 1 since msg[-0:] does not truncate to size 0 (more specifically, does not truncate at all).
    return ""
  else:
    padlen = size - 1
    return msg[(-1) * padlen:].rjust(padlen, '0')

def get_stats(values):
  x_bar = np.mean(values) 
  std = np.std(values)
  n = len(values)
  z = 1.96 # for a 95% CI

  lower = x_bar - (z * (std/math.sqrt(n)))
  upper = x_bar + (z * (std/math.sqrt(n)))
  med = np.median(price)
  return lower, med, upper, np.average(values), std

def compute_throughput_delay(timestamps, num_measuments, payload_size):
  total_throughput = 0.0 #system saturation throughput (bits per second)
  delays = np.zeros(len(timestamps)) #system saturation delay measurements (second)
  np_timestamps = np.asarray(timestamps)
  delays = np_timestamps[1:] - np_timestamps[:-1]

  total_throughput = num_measuments*payload_size/((timestamps[-1]-timestamps[0]) * 8) # convert to bit 
  return total_throughput, delays

def log(throughput, delays, payload_size):
  print("System saturation total throughput (b/s): ", throughput)
  print("System saturation average delay (s): ", np.average(delays))
  print("Packet size (bit): ", payload_size / 8)

def transmission_control(arduino, recv_addr, payload_size, timestamps, num_measuments):
  trans_message = 0
  recv_message = ''

  send_data(arduino, trans_message, recv_addr)
  timestamps.append(time.time())

  while trans_message < repetitions:
    try: 
      byte = arduino.read(1) #read one byte (blocks until data available or timeout reached) 
      if byte==b'\n': #if termination character reached
        if recv_message=='m[D]':
          timestamps.append(time.time())
          time.sleep(0.010)
          trans_message += 1
          send_data(arduino, padded(str(trans_message), payload_size), recv_addr)
          recv_message = '' #reset message
          if trans_message == num_measuments: # num of desired measurements reached 
            break
        else:
          recv_message = '' #reset message
      else:
        recv_message = recv_message + byte.decode() #concatenate the message 
    except serial.SerialException: 
      continue #on timeout try to read again

ttyACMindex = '/dev/ttyACM' + input("Enter serial port index of device (0, 1): ")
arduino = serial.Serial(port=ttyACMindex, baudrate=115200, timeout=1) #opens a serial port (resets the device!) 
time.sleep(2) #give the device some time to startup (2 seconds)
arduino.write(f'a[AA]\n'.encode()) #set the device address
time.sleep(1) #wait for settings to be applied
arduino.write('c[1,0,5]\n'.encode()) #set number of retransmissions to 5
time.sleep(1) #wait for settings to be applied
arduino.write('c[0,1,30]\n'.encode()) #set FEC threshold to 30 (apply FEC to packets with payload >= 30)
time.sleep(1) #wait for settings to be applied

recv_addr = input('Enter desired receive address: ')
num_measuments = int(input('Enter desired number of measurements for each packet size: '))

payload_sizes = [1, 10, 50, 100, 150, 200] # (Byte)
for p_size in payload_sizes:
  timestamps = []
  transmission_control(arduino, recv_addr, p_size, timestamps, num_measuments)
  throughput, delays = compute_throughput_delay(timestamps, num_measuments, p_size)
  log(throughput, delays, p_size)

# fig, ax = plt.subplots()
# for col in range(y.shape[1]):
#   ax.plot(timestamps[1:], delay_ppayload)
#   ax.fill_between(x, (y[:,col]-ci), (y[:,col]+ci), alpha=.1)
