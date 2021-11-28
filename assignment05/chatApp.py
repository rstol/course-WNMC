import serial
from queue import Queue
from threading import Thread, Event

#read from the device’s serial port
def receive_data(should_stop):
  message = ""
  while not should_stop.is_set():
    try: 
      byte = arduino.read(1) #read one byte (blocks until data available or timeout reached) 
      if byte=='\n': #if termination character reached
        print(f"Output: {message}") #print message
        message = "" #reset message
      else:
        message = message + byte #concatenate the message 
    except serial.SerialException: 
      continue #on timeout try to read again

def read_data(queue_, should_stop):
  print("Start chatting using VLC: ")
  while not should_stop.is_set():
      # read data to send from console
      message = input("\nInput: ")
      if message:
        queue_.put(message)

def send_data(queue_, recv_addr, should_stop):
  while not should_stop.is_set():
      msg = queue_.get()
      arduino.write(f"m[{msg}\0,{recv_addr}]\n".encode()) #send message to device with given address

def tell_when_to_stop(should_stop):
  # detect when to stop, and set the Event. 
  # wait for 5 seconds and then ask all to stop
  time.sleep(5)
  should_stop.set()

queue_ = Queue()
should_stop = Event()
arduino = serial.Serial(port='COM4', baudrate=115200, timeout=1) #opens a serial port (resets the device!) 
time.sleep(2) #give the device some time to startup (2 seconds) 

recv_addr = "FF" # default broadcast address

# initialize arduino
addr = input("Enter the device address: ")
# TODO: address validation
arduino.write(f"a[{addr}]\n".encode()) #set the device address
time.sleep(0.1) #wait for settings to be applied
recv_addr = input("Enter the receiving device address (defaults to FF): ")
# TODO: address validation
arduino.write("c[1,0,5]\n".encode()) #set number of retransmissions to 5
time.sleep(0.1) #wait for settings to be applied
arduino.write("c[0,1,30]\n".encode()) #set FEC threshold to 30 (apply FEC to packets with payload >= 30)
time.sleep(0.1) #wait for settings to be applied

thread_stop_decider = Thread(target=tell_when_to_stop, args=(should_stop,))
thread_read = Thread(target=read_data, args=(queue_, should_stop))
thread_send = Thread(target=send_data, args=(queue_, recv_addr, should_stop))
thread_receive = Thread(target=receive_data, args=(should_stop))

thread_read.start()
thread_send.start()
thread_receive.start()
thread_stop_decider.start()

try:
  while thread_read.is_alive():
    thread_read.join(1)
except KeyboardInterrupt:
  should_stop.set()

thread_read.join()
thread_send.join()
thread_receive.join()
thread_stop_decider.join()