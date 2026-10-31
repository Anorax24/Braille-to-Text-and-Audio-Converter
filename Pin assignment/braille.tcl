# ============================================================================
# Quartus Prime Pin Assignments for DE2-115 Braille-to-Audio System
# Top-Level Entity Name: braille
# ============================================================================

# ----------------------------------------------------------------------------
# System Clock & Master Reset
# ----------------------------------------------------------------------------
set_location_assignment PIN_Y2   -to CLOCK_50
set_location_assignment PIN_M23  -to KEY[0]

# ----------------------------------------------------------------------------
# 4x4 Keypad Interface (Mapped to GPIO Header JP5 Pin 1 to Pin 8)
# ----------------------------------------------------------------------------
set_location_assignment PIN_AB22 -to KEYPAD_ROW[0]
set_location_assignment PIN_AC15 -to KEYPAD_ROW[1]
set_location_assignment PIN_AB21 -to KEYPAD_ROW[2]
set_location_assignment PIN_Y17  -to KEYPAD_ROW[3]

set_location_assignment PIN_AC21 -to KEYPAD_COL[0]
set_location_assignment PIN_Y16  -to KEYPAD_COL[1]
set_location_assignment PIN_AD21 -to KEYPAD_COL[2]
set_location_assignment PIN_AE16 -to KEYPAD_COL[3]

# Enable weak pull-up resistors on Column Input pins
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to KEYPAD_COL[0]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to KEYPAD_COL[1]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to KEYPAD_COL[2]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to KEYPAD_COL[3]

# Set I/O standard to 3.3-V LVTTL
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEYPAD_ROW[*]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEYPAD_COL[*]

# ----------------------------------------------------------------------------
# HD44780 16x2 Character LCD Interface
# ----------------------------------------------------------------------------
set_location_assignment PIN_L3 -to LCD_DATA[0]
set_location_assignment PIN_L1 -to LCD_DATA[1]
set_location_assignment PIN_L2 -to LCD_DATA[2]
set_location_assignment PIN_K7 -to LCD_DATA[3]
set_location_assignment PIN_K1 -to LCD_DATA[4]
set_location_assignment PIN_K2 -to LCD_DATA[5]
set_location_assignment PIN_M3 -to LCD_DATA[6]
set_location_assignment PIN_M5 -to LCD_DATA[7]

set_location_assignment PIN_M2 -to LCD_RS
set_location_assignment PIN_M1 -to LCD_RW
set_location_assignment PIN_L4 -to LCD_EN
set_location_assignment PIN_L5 -to LCD_ON
set_location_assignment PIN_L6 -to LCD_BLON

# ----------------------------------------------------------------------------
# WM8731 Audio Codec Interface (I2C Control & I2S Master Stream)
# ----------------------------------------------------------------------------
set_location_assignment PIN_B7 -to I2C_SCLK
set_location_assignment PIN_A8 -to I2C_SDAT

set_location_assignment PIN_E1 -to AUD_XCK
set_location_assignment PIN_F2 -to AUD_BCLK
set_location_assignment PIN_E3 -to AUD_DACLRCK
set_location_assignment PIN_D1 -to AUD_DACDAT

# ----------------------------------------------------------------------------
# Status & Diagnostic LEDs
# ----------------------------------------------------------------------------
set_location_assignment PIN_E21 -to LEDG[0]
set_location_assignment PIN_E22 -to LEDG[1]
set_location_assignment PIN_E25 -to LEDG[2]
set_location_assignment PIN_E24 -to LEDG[3]

set_location_assignment PIN_G19 -to LEDR[0]
set_location_assignment PIN_F19 -to LEDR[1]
set_location_assignment PIN_E19 -to LEDR[2]
set_location_assignment PIN_F21 -to LEDR[3]
set_location_assignment PIN_F18 -to LEDR[4]
set_location_assignment PIN_E18 -to LEDR[5]