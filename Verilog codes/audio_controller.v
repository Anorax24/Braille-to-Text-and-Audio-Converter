// ============================================================================
// Module: WM8731 I2C Configurator  (unchanged - sequence and values verified)
// ============================================================================
module audio_controller #(
    parameter sim = 0
)(
    input  wire clk,
    input  wire reset_n,
    inout  wire i2c_sdat,
    output reg  i2c_sclk,
    output reg  config_done,
    output reg  ack_error
);

    reg sdat_out;
    assign i2c_sdat = (sdat_out == 1'b0) ? 1'b0 : 1'bz;

    localparam q_tick_limit = sim ? 10'd3 : 10'd499;
    reg [9:0] clk_cnt;
    wire q_tick = (clk_cnt == q_tick_limit);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)        clk_cnt <= 10'd0;
        else if (q_tick)     clk_cnt <= 10'd0;
        else                 clk_cnt <= clk_cnt + 1'b1;
    end

    localparam s_pwr_wait   = 3'd0;
    localparam s_start      = 3'd1;
    localparam s_write_byte = 3'd2;
    localparam s_read_ack   = 3'd3;
    localparam s_stop       = 3'd4;
    localparam s_inter_gap  = 3'd5;
    localparam s_done       = 3'd6;

    reg [2:0]  state;
    reg [1:0]  phase;
    reg [3:0]  cmd_idx;
    reg [1:0]  byte_idx;
    reg [2:0]  bit_idx;
    reg [15:0] pwr_timer;
    reg [15:0] rom_data;

    always @(*) begin
        case (cmd_idx)
            4'd0: rom_data = 16'h1E00;   // reset
            4'd1: rom_data = 16'h0C00;   // power up everything
            4'd2: rom_data = 16'h0812;   // DAC selected, mic muted
            4'd3: rom_data = 16'h0A00;   // DAC unmuted
            4'd4: rom_data = 16'h0E02;   // I2S, 16-bit, slave
            4'd5: rom_data = 16'h1000;   // normal mode, 256fs
            4'd6: rom_data = 16'h0579;   // left headphone volume
            4'd7: rom_data = 16'h0779;   // right headphone volume
            4'd8: rom_data = 16'h1201;   // activate
            default: rom_data = 16'h1E00;
        endcase
    end

    wire [7:0] current_byte = (byte_idx == 2'd0) ? 8'h34 :
                              (byte_idx == 2'd1) ? rom_data[15:8] : rom_data[7:0];

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state       <= s_pwr_wait;
            phase       <= 2'd0;
            cmd_idx     <= 4'd0;
            byte_idx    <= 2'd0;
            bit_idx     <= 3'd7;
            i2c_sclk    <= 1'b1;
            sdat_out    <= 1'b1;
            config_done <= 1'b0;
            ack_error   <= 1'b0;
            pwr_timer   <= 16'd0;
        end else if (q_tick) begin
            phase <= phase + 1'b1;

            case (state)
                s_pwr_wait: begin
                    i2c_sclk <= 1'b1;
                    sdat_out <= 1'b1;
                    if (phase == 2'd3) begin
                        pwr_timer <= pwr_timer + 1'b1;
                        if (pwr_timer >= (sim ? 16'd4 : 16'd1000)) begin
                            cmd_idx <= 4'd0;
                            state   <= s_start;
                        end
                    end
                end

                s_start: begin
                    case (phase)
                        2'd0, 2'd1: begin i2c_sclk <= 1'b1; sdat_out <= 1'b1; end
                        2'd2:       begin i2c_sclk <= 1'b1; sdat_out <= 1'b0; end
                        2'd3: begin
                            i2c_sclk <= 1'b0;
                            sdat_out <= 1'b0;
                            byte_idx <= 2'd0;
                            bit_idx  <= 3'd7;
                            state    <= s_write_byte;
                        end
                    endcase
                end

                s_write_byte: begin
                    case (phase)
                        2'd0: begin i2c_sclk <= 1'b0; sdat_out <= current_byte[bit_idx]; end
                        2'd1, 2'd2: begin i2c_sclk <= 1'b1; end
                        2'd3: begin
                            i2c_sclk <= 1'b0;
                            if (bit_idx == 3'd0) state <= s_read_ack;
                            else                 bit_idx <= bit_idx - 1'b1;
                        end
                    endcase
                end

                s_read_ack: begin
                    case (phase)
                        2'd0: begin i2c_sclk <= 1'b0; sdat_out <= 1'b1; end
                        2'd1: begin i2c_sclk <= 1'b1; end
                        2'd2: begin
                            i2c_sclk <= 1'b1;
                            if (i2c_sdat == 1'b1) ack_error <= 1'b1;
                        end
                        2'd3: begin
                            i2c_sclk <= 1'b0;
                            if (byte_idx == 2'd2) state <= s_stop;
                            else begin
                                byte_idx <= byte_idx + 1'b1;
                                bit_idx  <= 3'd7;
                                state    <= s_write_byte;
                            end
                        end
                    endcase
                end

                s_stop: begin
                    case (phase)
                        2'd0: begin i2c_sclk <= 1'b0; sdat_out <= 1'b0; end
                        2'd1, 2'd2: begin i2c_sclk <= 1'b1; sdat_out <= 1'b0; end
                        2'd3: begin
                            i2c_sclk <= 1'b1;
                            sdat_out <= 1'b1;
                            state    <= s_inter_gap;
                        end
                    endcase
                end

                s_inter_gap: begin
                    i2c_sclk <= 1'b1;
                    sdat_out <= 1'b1;
                    if (phase == 2'd3) begin
                        if (cmd_idx == 4'd8) state <= s_done;
                        else begin
                            cmd_idx <= cmd_idx + 1'b1;
                            state   <= s_start;
                        end
                    end
                end

                s_done: begin
                    i2c_sclk    <= 1'b1;
                    sdat_out    <= 1'b1;
                    config_done <= 1'b1;
                end

                default: state <= s_done;
            endcase
        end
    end
endmodule
