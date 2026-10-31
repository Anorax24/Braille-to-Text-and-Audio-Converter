// ============================================================================
// Top-Level Module: Braille-to-Audio System with 4x4 Keypad Input
// Target Board: Altera DE2-115 FPGA
//
// Keypad map (key -> action)
//   1 2 3 A      1..6 = toggle Braille dots 1..6
//   4 5 6 B      B, #, D = submit (speak the letter)
//   7 8 9 C      A, C, *, 0 = clear dots
//   * 0 # D
// ============================================================================
module braille_top(
    input  wire        CLOCK_50,
    input  wire [0:0]  KEY,            // KEY[0] = Reset_n (active low)

    // 4x4 matrix keypad  (KEYPAD_COL needs pull-ups: see Quartus notes)
    output wire [3:0]  KEYPAD_ROW,
    input  wire [3:0]  KEYPAD_COL,

    // HD44780 16x2 LCD
    output wire [7:0]  LCD_DATA,
    output wire        LCD_RS,
    output wire        LCD_RW,
    output wire        LCD_EN,
    output wire        LCD_ON,
    output wire        LCD_BLON,

    // WM8731 control (I2C)
    output wire        I2C_SCLK,
    inout  wire        I2C_SDAT,

    // WM8731 audio (I2S, FPGA is master)
    output wire        AUD_XCK,
    output wire        AUD_BCLK,
    output wire        AUD_DACLRCK,
    output wire        AUD_DACDAT,

    output wire [3:0]  LEDG,
    output wire [5:0]  LEDR
);

    wire        clk     = CLOCK_50;
    wire        reset_n = KEY[0];

    wire [5:0]  braille_dots;
    wire        submit_pulse;

    wire [7:0]  raw_ascii;
    wire [4:0]  raw_letter_idx;
    wire        char_valid;

    wire [7:0]  fsm_lcd_char;
    wire [4:0]  fsm_audio_letter_idx;
    wire        lcd_ready;
    wire        lcd_write_cmd;

    wire        audio_trigger;
    wire        audio_done;

    wire        config_done;
    wire        ack_error;
    wire [2:0]  fsm_state_leds;

    assign LEDR[5:0] = braille_dots;
    assign LEDG[0]   = config_done;
    assign LEDG[1]   = ack_error;
    assign LEDG[3:2] = fsm_state_leds[1:0];

    keypad_scanner u_keypad (
        .clk(clk), .reset_n(reset_n),
        .col(KEYPAD_COL), .row(KEYPAD_ROW),
        .dots(braille_dots), .submit_pulse(submit_pulse)
    );

    braille_decoder u_decoder (
        .dots(braille_dots),
        .ascii_char(raw_ascii),
        .letter_idx(raw_letter_idx),
        .valid(char_valid)
    );

    braille_flow_fsm u_flow_fsm (
        .clk(clk), .reset_n(reset_n),
        .valid(char_valid),
        .ascii_in(raw_ascii),
        .letter_idx_in(raw_letter_idx),
        .dots_in(braille_dots),
        .btn_pulse(submit_pulse),
        .lcd_ready(lcd_ready),
        .lcd_write_cmd(lcd_write_cmd),
        .lcd_char_out(fsm_lcd_char),
        .audio_done(audio_done),
        .audio_trigger(audio_trigger),
        .letter_idx_out(fsm_audio_letter_idx),
        .state_leds(fsm_state_leds)
    );

    lcd_controller #(.SIMULATION(0)) u_lcd (
        .clk(clk), .reset_n(reset_n),
        .lcd_write_cmd(lcd_write_cmd),
        .char_data(fsm_lcd_char),
        .lcd_ready(lcd_ready),
        .lcd_data(LCD_DATA), .lcd_rs(LCD_RS), .lcd_rw(LCD_RW),
        .lcd_en(LCD_EN), .lcd_on(LCD_ON), .lcd_blon(LCD_BLON)
    );

    audio_controller #(.sim(0)) u_i2c_config (
        .clk(clk), .reset_n(reset_n),
        .i2c_sclk(I2C_SCLK), .i2c_sdat(I2C_SDAT),
        .config_done(config_done), .ack_error(ack_error)
    );

    audio_synthesizer_i2s #(.SIMULATION(0)) u_audio_synth (
        .clk(clk), .reset_n(reset_n),
        .audio_trigger(audio_trigger),
        .letter_idx(fsm_audio_letter_idx),
        .audio_done(audio_done),
        .aud_xck(AUD_XCK), .aud_bclk(AUD_BCLK),
        .aud_daclrck(AUD_DACLRCK), .aud_dacdat(AUD_DACDAT)
    );

endmodule
