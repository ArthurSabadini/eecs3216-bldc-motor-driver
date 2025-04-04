This project was made for the course EECS3216 at York University. Here we implemented a BLDC motor driver using the SVPWM algorithm implemented in verilog, and intended for the DE10-Lite.
We implemented our own circuit driver for a BLDC motor, controlling it using the DE10-Lite FPGA.

- This repository contains a runnable project that can be compiled using the Quartus Prime editor. The main file is Driver.sv, note we did not upload the simulation files as those would be toolarge.

- Outputs of the module are Arduino Pins D0-D5, note the output is inverted! As extra circuitry had to be implemented  on the input to level up the logic level of the FPGA (3.3v).
