import serial
import time

def send_data(arduino, msg, recv_addr):
  arduino.write(f'm[{msg}\0,{recv_addr}]\n'.encode()) #send message to device with given address

def padded(msg, size): #payload size -1 to accomodate for the \0-termination.
  if size == 1: #lower with msg[-padlen:] does not work for size 1 since msg[-0:] does not truncate to size 0 (more specifically, does not truncate at all).
    return ""
  else:
    padlen = size - 1
    return msg[(-1) * padlen:].rjust(padlen, '0')

def transmission_control(arduino, recv_addr, payload_size, timestamps):
  trans_message = 0
  recv_message = ''

  send_data(arduino, trans_message, recv_addr)
  timestamps.append(time.time())

  while True:
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

ttyACMindex = '/dev/ttyACM' + input("Enter serial port index of device (0, 1): ")
arduino = serial.Serial(port=ttyACMindex, baudrate=115200, timeout=1) #opens a serial port (resets the device!) 
time.sleep(2) #give the device some time to startup (2 seconds)
arduino.write(f'a[AA]\n'.encode()) #set the device address
time.sleep(0.1) #wait for settings to be applied
arduino.write('c[1,0,5]\n'.encode()) #set number of retransmissions to 5
time.sleep(0.1) #wait for settings to be applied
arduino.write('c[0,1,30]\n'.encode()) #set FEC threshold to 30 (apply FEC to packets with payload >= 30)
time.sleep(0.1) #wait for settings to be applied

timestamps = []

payload_size = int(input('Enter desired packet data size (Byte): '))
recv_addr = input('Enter desired receive address: ')

try:
  transmission_control(arduino, recv_addr, payload_size, timestamps)
except KeyboardInterrupt:
  prev = timestamps.pop(0)
  for e in timestamps:
    print(str(e - prev))
    prev = e