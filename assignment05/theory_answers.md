# Step 2
1. What is the bandwidth of the optical spectrum?

    The frequency range of visible light lies at around 430 - 750 THz. [1] This constitutes a band 320 THz in size, which by Prof. Mangold's bandwidth estimation guidelines corresponds to 320 Tb/s.

2. Is the visible spectrum regulated?

    No.

3. What is the difference between infrared and visible light?

    Infrared light is light at a frequency lower than the lowest frequency visible to the human eye. (This also implies a lower energy of the wave.)

4. Can infrared light penetrate water? Can visible light?

    Infrared light _can_ penetrate water for a limited range, however water _does_ have IR-absorbing properties, making it inefficient/ineffective at long-range underwater communication. Higher-power visible light, such as blue or violet light, is less-absorbed and as such a better frequency to communicate underwater with.

5. How do submarines communicate through the ocean, when they operate below water surface?

    Sound waves, microwaves, blue LED/lasers (i.e. high-energy visible light). (Lecture 06: VLC)

6. How can an LED be used as a receiver?

    LEDs lose charge more quickly while in contact with photons. This allows for charge depletion rate comparisons to detect if another LED was lit up (e.g. transmitting a 1-bit, depending on implementation) or not.

7. What are the benefits of using an LED instead of a photodiode as a receiver in consumer electronics?

    Price/practicality. Installing both an LED and a photodiode for two-way communication would be both more expensive (added product) as well as more challenging to implement. (Design: only need to place 1 LED instead of both components. Hardware: Photodiode may require a more complicated microcontroller. Price: Beyond additional design costs, the hardware of the photodiode itself obviously adds to manufacturing cost.)
    Additionally, many consumer electronics already contain some kind of LED, allowing for communication implementation by just changing microcontroller programming rather than re-designing hardware.

[1] https://www.britannica.com/science/color/The-visible-spectrum
