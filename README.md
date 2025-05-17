# BLDC Motor Driver 

This project was made for the course EECS3216 at York University. Here we implemented a BLDC motor driver using the SVPWM algorithm implemented in verilog, and intended for the DE10-Lite.
We implemented our own circuit driver for a BLDC motor, controlling it using the DE10-Lite FPGA.

- This repository contains a runnable project that can be compiled using the Quartus Prime editor. The main file is Driver.sv, note we did not upload the simulation files as those would be too large.

- Outputs of the module are Arduino Pins D0-D5, note the output is inverted! As extra circuitry had to be implemented  on the input to level up the logic level of the FPGA (3.3v).

- The video demonstration of the project can be seen in the following link https://www.youtube.com/watch?si=b8xfoCtHZS__AAA1&v=ajDVEePGOGo&feature=youtu.be.

# Video Demo
[![Watch the video](https://img.youtube.com/vi/YOUR_VIDEO_ID/hqdefault.jpg)](https://www.youtube.com/watch?si=b8xfoCtHZS__AAA1&v=ajDVEePGOGo&feature=youtu.be)

## 🛠️ Technologies & Tools
![Verilog](https://img.shields.io/badge/-Verilog-blue?logo=verilog&logoColor=white&style=plastic)
![SystemVerilog](https://img.shields.io/badge/-SystemVerilog-blueviolet?style=plastic)
![Quartus Prime](https://img.shields.io/badge/-Quartus%20Prime-lightgrey?logo=intel&logoColor=blue&style=plastic)

## 🧱 Hardware Platform
This project uses the [DE10-Lite FPGA development board](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=205&No=1046) by [Terasic Technologies](https://www.terasic.com.tw/).

## License
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
