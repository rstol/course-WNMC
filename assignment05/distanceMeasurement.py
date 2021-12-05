import serial
import time
import numpy as np

def send_data(arduino, msg, recv_addr):
  arduino.write(f'm[{msg}\0,{recv_addr}]\n'.encode()) #send message to device with given address

def padded(msg, size): #payload size -1 to accomodate for the \0-termination.
  if size == 1: #lower with msg[-padlen:] does not work for size 1 since msg[-0:] does not truncate to size 0 (more specifically, does not truncate at all).
    return ""
  else:
    padlen = size - 1
    return msg[(-1) * padlen:].rjust(padlen, '0')

def visualization(payload_size, timestamps):
  data_pts = len(timestamps)
  np_timestamps = np.asarray(timestamps)
  throughput = np.zeros(data_pts-1) #data packets per second
  delay = np.zeros(data_pts-1)

  delay = np_timestamps[1:] - np_timestamps[:-1] 
  throughput = 1.0/delay

  print(f"[{payload_size}] Delay: ", delay)
  print(f"[{payload_size}] Throughput: ", throughput)
  print(f"[{payload_size}] Standard deviation delay: ", np.std(delay))
  print(f"[{payload_size}] Standard deviation throughput: ", np.std(throughput))

def transmission_control(arduino, recv_addr, payload_size, timestamps, repetitions):
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
        else:
          recv_message = '' #reset message
      else:
        recv_message = recv_message + byte.decode() #concatenate the message 
    except serial.SerialException: 
      continue #on timeout try to read again


arduino = serial.Serial(port='/dev/COM4', baudrate=115200, timeout=1) #opens a serial port (resets the device!) 
time.sleep(2) #give the device some time to startup (2 seconds)
arduino.write(f'a[AA]\n'.encode()) #set the device address
time.sleep(0.1) #wait for settings to be applied
arduino.write('c[1,0,5]\n'.encode()) #set number of retransmissions to 5
time.sleep(0.1) #wait for settings to be applied
arduino.write('c[0,1,30]\n'.encode()) #set FEC threshold to 30 (apply FEC to packets with payload >= 30)
time.sleep(0.1) #wait for settings to be applied

timestamps = [[], [], [], [], [], []]
payload_sizes = [1, 10, 50, 100, 150, 200]
repetitions = 50

# payload_size = int(input('Enter desired packet data size (Byte): '))
recv_addr = input('Enter desired receive address: ')

try:
  for i in range(0, len(payload_sizes)): transmission_control(arduino, recv_addr, payload_sizes[i], timestamps[i], repetitions)
except KeyboardInterrupt:
  print("Interrupted! Continuing with collected data:")

for i in range(0, len(payload_sizes)): visualization(payload_sizes[i], timestamps[i])

#TODO: plot packet size vs throughput & delay (for each distance)
#TODO: maybe add detection for ACK vs TIMEOUT to get better data insight (can also observe receiving device for this)