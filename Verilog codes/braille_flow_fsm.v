// ============================================================================
// Module: Flow Control FSM
//   INIT_LCD -> WAIT_INPUT -> WRITE_LCD -> WAIT_BTN -> PLAY_AUDIO -> WAIT_BTN
//   When the pattern becomes invalid/cleared the LCD cell is blanked.
//   Command strobes (lcd_write_cmd, audio_trigger) are exactly 1 clk wide.
// ============================================================================
module braille_flow_fsm (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        valid,
    input  wire [7:0]  ascii_in,
    input  wire [4:0]  letter_idx_in,
    input  wire [5:0]  dots_in,
    input  wire        btn_pulse,
    input  wire        lcd_ready,
    output reg         lcd_write_cmd,
    output reg  [7:0]  lcd_char_out,
    input  wire        audio_done,      // 1-clk pulse when playback ends
    output reg         audio_trigger,
    output reg  [4:0]  letter_idx_out,
    output wire [2:0]  state_leds
);

    localparam [2:0] S_INIT_LCD    = 3'd0;
    localparam [2:0] S_WAIT_INPUT  = 3'd1;
    localparam [2:0] S_WRITE_LCD   = 3'd2;
    localparam [2:0] S_WAIT_BTN    = 3'd3;
    localparam [2:0] S_PLAY_AUDIO  = 3'd4;
    localparam [2:0] S_BLANK_LCD   = 3'd5;

    reg [2:0] current_state, next_state;
    reg [5:0] latched_dots;
    reg       cmd_sent;

    assign state_leds = current_state;

    // State register + "command already issued" flag
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_state <= S_INIT_LCD;
            cmd_sent      <= 1'b0;
        end else begin
            current_state <= next_state;
            if (current_state != next_state)
                cmd_sent <= 1'b0;
            else if (lcd_write_cmd || audio_trigger)
                cmd_sent <= 1'b1;
        end
    end

    // Next-state logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            S_INIT_LCD:   if (lcd_ready) next_state = S_WAIT_INPUT;   // LCD self-initialises

            S_WAIT_INPUT: if (valid)     next_state = S_WRITE_LCD;

            S_WRITE_LCD:  if (cmd_sent && lcd_ready) next_state = S_WAIT_BTN;

            S_WAIT_BTN: begin
                if (btn_pulse && valid)                      next_state = S_PLAY_AUDIO;
                else if (!valid)                             next_state = S_BLANK_LCD;
                else if (dots_in != latched_dots)            next_state = S_WRITE_LCD;
            end

            S_BLANK_LCD:  if (cmd_sent && lcd_ready) next_state = S_WAIT_INPUT;

            S_PLAY_AUDIO: if (cmd_sent && audio_done) next_state = S_WAIT_BTN;

            default:      next_state = S_INIT_LCD;
        endcase
    end

    // Output logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lcd_write_cmd  <= 1'b0;
            audio_trigger  <= 1'b0;
            lcd_char_out   <= 8'h20;
            letter_idx_out <= 5'd0;
            latched_dots   <= 6'd0;
        end else begin
            lcd_write_cmd <= 1'b0;
            audio_trigger <= 1'b0;

            case (current_state)
                S_WRITE_LCD: begin
                    if (!cmd_sent && !lcd_write_cmd && lcd_ready) begin
                        lcd_char_out   <= ascii_in;
                        letter_idx_out <= letter_idx_in;
                        latched_dots   <= dots_in;
                        lcd_write_cmd  <= 1'b1;
                    end
                end

                S_BLANK_LCD: begin
                    if (!cmd_sent && !lcd_write_cmd && lcd_ready) begin
                        lcd_char_out  <= 8'h20;          // space
                        latched_dots  <= 6'd0;
                        lcd_write_cmd <= 1'b1;
                    end
                end

                S_PLAY_AUDIO: begin
                    if (!cmd_sent && !audio_trigger)
                        audio_trigger <= 1'b1;
                end

                default: ;
            endcase
        end
    end
endmodule

