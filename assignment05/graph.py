import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('distance data.csv')
distances = [0, 10, 20, 30, 35, 40, 45]
frames = []
distance = "Distance (cm +- 1cm)"
psize = "Packet Size (b)"
loss = "Loss (%)"
throughput = "Throughput (b/s)"
delay = "Average Delay (s)"
stddev = "Std Dev Delay (s)"

for d in distances: frames.append(df[df[distance] == d])
for d in frames:
    plt.plot(pd.to_numeric(d.loc[:,psize], errors='coerce'), pd.to_numeric(d.loc[:,throughput], errors='coerce'), label =f"{throughput} at {d.iat[0,0]} cm +- 1cm")
    plt.errorbar(pd.to_numeric(d.loc[:,psize], errors='coerce'), pd.to_numeric(d.loc[:,delay], errors='coerce'), label = f"{delay} at {d.iat[0,0]} cm +- 1cm", yerr = pd.to_numeric(d.loc[:,stddev], errors='coerce'), linestyle = (0, (5,2)))

plt.title('Total Throughput and Average Packet Delay vs Packet Size per Distance for VLC')
plt.xlabel(psize)
plt.ylabel(throughput + ' and ' + delay)

plt.legend(loc='best')

plt.show()