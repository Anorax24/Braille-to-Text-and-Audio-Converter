// ============================================================================
// Module: HD44780 LCD Controller
//   * Initialises itself after reset (50 ms power-up wait, then 38/0C/01/06).
//   * Every character write first sets the cursor to DDRAM address 0x00
//     (command 0x80) so the letter always overwrites the same cell.
//   * lcd_ready = 1 only when idle.
// ============================================================================
module lcd_controller #(
    parameter SIMULATION = 0
)(
    output reg  [7:0] lcd_data,
    output reg        lcd_ready,
    output reg        lcd_rs,
    output wire       lcd_rw,
    output reg        lcd_en,
    output wire       lcd_on,
    output wire       lcd_blon,
    input  wire       clk,
    input  wire       reset_n,
    input  wire       lcd_write_cmd,
    input  wire [7:0] char_data
);

    assign lcd_rw   = 1'b0;
    assign lcd_on   = 1'b1;
    assign lcd_blon = 1'b1;

    // 1 us tick
    localparam [5:0] TICK_LIMIT = SIMULATION ? 6'd4 : 6'd49;
    reg [5:0] clk_count;
    wire tick = (clk_count == TICK_LIMIT);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)    clk_count <= 6'd0;
        else if (tick)   clk_count <= 6'd0;
        else             clk_count <= clk_count + 1'b1;
    end

    // Delay timer (in us)
    reg [15:0] timer;
    wire timer_done = (timer == 16'd0);

    localparam [2:0] s_pwr_wait = 3'd0;
    localparam [2:0] s_load     = 3'd1;
    localparam [2:0] s_setup    = 3'd2;
    localparam [2:0] s_en_high  = 3'd3;
    localparam [2:0] s_en_low   = 3'd4;
    localparam [2:0] s_hold     = 3'd5;
    localparam [2:0] s_idle     = 3'd6;

    reg [2:0]  s;
    reg        job_write;     // 0 = init sequence, 1 = write one character
    reg [2:0]  idx;           // byte index inside the current job
    reg [7:0]  char_lat;
    reg        pulse_cnt;

    // Byte table
    reg [7:0]  tx_byte;
    reg        tx_rs;
    reg [15:0] delay_val;
    reg        last_byte;

    always @(*) begin
        tx_byte   = 8'h00;
        tx_rs     = 1'b0;
        delay_val = SIMULATION ? 16'd5 : 16'd50;
        last_byte = 1'b0;

        if (!job_write) begin
            case (idx)
                3'd0: tx_byte = 8'h38;                         // 8-bit, 2 lines
                3'd1: tx_byte = 8'h0C;                         // display on
                3'd2: begin
                    tx_byte   = 8'h01;                         // clear
                    delay_val = SIMULATION ? 16'd20 : 16'd2000;
                end
                default: begin tx_byte = 8'h06; last_byte = 1'b1; end // entry mode
            endcase
        end else begin
            case (idx)
                3'd0:    tx_byte = 8'h80;                      // DDRAM address 0
                default: begin tx_byte = char_lat; tx_rs = 1'b1; last_byte = 1'b1; end
            endcase
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            s         <= s_pwr_wait;
            job_write <= 1'b0;
            idx       <= 3'd0;
            char_lat  <= 8'h20;
            timer     <= SIMULATION ? 16'd10 : 16'd50000;   // 50 ms
            pulse_cnt <= 1'b0;
            lcd_ready <= 1'b0;
            lcd_data  <= 8'h00;
            lcd_rs    <= 1'b0;
            lcd_en    <= 1'b0;
        end else begin
            if (tick && !timer_done)
                timer <= timer - 1'b1;

            case (s)
                s_pwr_wait: begin
                    lcd_ready <= 1'b0;
                    lcd_en    <= 1'b0;
                    if (timer_done) begin
                        job_write <= 1'b0;
                        idx       <= 3'd0;
                        s         <= s_load;
                    end
                end

                s_load: begin                       // present byte on the bus
                    lcd_data  <= tx_byte;
                    lcd_rs    <= tx_rs;
                    lcd_en    <= 1'b0;
                    pulse_cnt <= 1'b0;
                    s         <= s_setup;
                end

                s_setup: begin                      // ~2 us setup
                    if (tick) begin
                        if (pulse_cnt) begin pulse_cnt <= 1'b0; s <= s_en_high; end
                        else           pulse_cnt <= 1'b1;
                    end
                end

                s_en_high: begin                    // ~2 us enable pulse
                    lcd_en <= 1'b1;
                    if (tick) begin
                        if (pulse_cnt) begin pulse_cnt <= 1'b0; s <= s_en_low; end
                        else           pulse_cnt <= 1'b1;
                    end
                end

                s_en_low: begin
                    lcd_en <= 1'b0;
                    timer  <= delay_val;
                    s      <= s_hold;
                end

                s_hold: begin                       // wait for LCD to finish
                    if (timer_done) begin
                        if (last_byte) s <= s_idle;
                        else begin
                            idx <= idx + 1'b1;
                            s   <= s_load;
                        end
                    end
                end

                s_idle: begin
                    lcd_ready <= 1'b1;
                    lcd_en    <= 1'b0;
                    if (lcd_write_cmd) begin
                        lcd_ready <= 1'b0;
                        char_lat  <= char_data;
                        job_write <= 1'b1;
                        idx       <= 3'd0;
                        s         <= s_load;
                    end
                end

                default: s <= s_idle;
            endcase
        end
    end
endmodule
