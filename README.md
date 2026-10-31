FPGA-Based Braille-to-Audio Conversion System

An Assistive Technology Project using Verilog HDL and Python

1. Project Overview

This project implements an FPGA-based Braille-to-Audio Conversion System that converts six-dot Braille inputs into corresponding English alphabet characters and generates spoken audio output.

The system uses a 4×4 matrix keypad to enter Braille patterns. The FPGA decodes the input, displays the corresponding character on a 16×2 LCD, and plays the associated voice output through the WM8731 audio codec.

The design is implemented on the **Altera DE2-115 FPGA Development Board (Cyclone IV EP4CE115).

2. Key Features

- Six-dot Braille input using a 4×4 matrix keypad.
- Keypad scanning and debouncing using Verilog.
- Braille pattern decoding into English alphabets (A–Z).
- Character display using an HD44780-compatible 16×2 LCD.
- Python-based voice sample generation and MIF file creation.
- Internal FPGA ROM for storing voice samples.
- Audio playback using the WM8731 codec.
- I²C-based audio codec configuration.
- I²S-based audio data transmission.
- FSM-based control of the overall system.

3. Hardware Requirements

| Component | Description |
|---|---|
| FPGA Board | Altera DE2-115 |
| FPGA Device | Cyclone IV EP4CE115 |
| Input | 4×4 Matrix Keypad |
| Display | HD44780 16×2 LCD |
| Audio Codec | WM8731 |
| Clock | 50 MHz |
| Status Indicators | Red and Green LEDs |

4. Software and Tools

- Quartus Prime: FPGA design, synthesis and implementation.
- Verilog HDL: Hardware description and digital logic implementation.
- Python: Voice sample processing and MIF file generation.
- Memory Initialization File (MIF): Stores the generated voice samples for FPGA ROM initialization.

5. System Architecture

The system consists of the following functional blocks:

1. Keypad Scanner: Scans the 4×4 matrix keypad and identifies key presses.
2. Braille Decoder: Converts the six-bit Braille pattern into its corresponding ASCII character.
3. Main Control FSM: Coordinates character display and audio playback.
4. LCD Controller: Displays the decoded character.
5. I²C Audio Controller: Configures the WM8731 audio codec.
6. Audio Synthesizer (I²S): Retrieves voice samples from ROM and transmits audio data.
7. Voice ROM: Stores the PCM voice samples for all 26 English alphabets.

6. Audio Generation and Storage

Voice samples corresponding to the 26 English alphabets are generated and processed using Python.

The generated samples are converted into a Memory Initialization File (`voice_rom.mif`), which initializes the FPGA's internal M9K block RAM.

- Number of letters: 26
- Samples per letter: 2048
- Sample format: Unsigned 8-bit PCM
- Sample rate: 8 kHz
- ROM capacity: 53,248 × 8 bits

The audio synthesizer retrieves the samples corresponding to the decoded character and transmits them to the WM8731 codec using the I²S interface.

7. Input Key Mapping

| Key | Function |
|---|---|
| 1–6 | Toggle Braille dots 1–6 |
| B, #, D | Submit the selected pattern |
| A, C, *, 0 | Clear the selected dots |

8. Repository Structure

```text
FPGA-Braille-to-Audio-Converter/
│
├── Verilog/
│   └── Verilog source files
│
├── Python/
│   ├── Voice generation script
│   └── MIF generation script
│
├── Memory/
│   └── voice_rom.mif
│
├── Quartus/
│   └── Pin assignments and project files
│
├── Documentation/
│   ├── Architecture diagram
│   └── Hardware implementation images
│
└── README.md
```

9. Hardware Implementation

The project is implemented and tested on the Altera DE2-115 FPGA development board with an interfaced 4×4 matrix keypad.

The decoded characters are displayed on the LCD, while the corresponding spoken output is generated through the WM8731 audio codec.

10. Expected Applications

- Assistive communication for visually impaired individuals.
- Braille learning and educational systems.
- FPGA-based speech generation systems.
- Embedded assistive technology.

11. Future Enhancements

- Support for numbers, punctuation and complete Braille sentences.
- Improved voice quality and audio playback.
- Expanded Braille input functionality.
- Support for additional languages.

12. Author

Project Domain:** FPGA Design | Embedded Systems | Assistive Technology

Platform:** Altera DE2-115 FPGA

---

*Developed as an FPGA-based course project using Verilog HDL and Python.*