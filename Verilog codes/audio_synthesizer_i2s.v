// ============================================================================
// Module: Audio Synthesizer & I2S Master Transmitter
//   MCLK = 12.5 MHz, BCLK = 3.125 MHz, LRCK = 48.83 kHz (64 BCLK / frame)
//   audio_done is a 1-clk PULSE at the end of playback.
// ============================================================================
// ============================================================================
// Module: Audio Synthesizer & I2S Master Transmitter
// 50 MHz system clock, 12.5 MHz MCLK, 3.125 MHz BCLK,
// 48.828125 kHz LRCK (64 BCLK periods per stereo frame).
// Plays 2048 unsigned 8-bit PCM samples per letter at 8 kHz.
// ============================================================================
module audio_synthesizer_i2s #(
    parameter SIMULATION = 0
)(
    input  wire        clk,
    input  wire        reset_n,
    input  wire        audio_trigger,
    input  wire [4:0]  letter_idx,
    output reg         audio_done,
    output reg         aud_xck,
    output reg         aud_bclk,
    output reg         aud_daclrck,
    output reg         aud_dacdat
);

    // MCLK: 50 MHz / 4 = 12.5 MHz
    reg xck_div;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            xck_div <= 1'b0;
            aud_xck <= 1'b0;
        end else begin
            xck_div <= ~xck_div;
            if (xck_div)
                aud_xck <= ~aud_xck;
        end
    end

    // BCLK: toggle every 8 system clocks -> 3.125 MHz.
    // bclk_fall_ce is a one-system-clock enable on each falling BCLK edge.
    reg [2:0] bclk_div;
    reg       bclk_fall_ce;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            bclk_div     <= 3'd0;
            aud_bclk     <= 1'b0;
            bclk_fall_ce <= 1'b0;
        end else begin
            bclk_fall_ce <= 1'b0;
            if (bclk_div == 3'd7) begin
                bclk_div <= 3'd0;
                aud_bclk <= ~aud_bclk;
                if (aud_bclk)
                    bclk_fall_ce <= 1'b1;
            end else begin
                bclk_div <= bclk_div + 1'b1;
            end
        end
    end

    // 8 kHz sample interval. Simulation mode shortens playback intervals.
    localparam integer SAMPLE_DIV = SIMULATION ? 20 : 6250;
    reg [12:0] sample_timer;
    wire sample_tick = (sample_timer == SAMPLE_DIV - 1);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            sample_timer <= 13'd0;
        else if (!playing || sample_tick || start_req)
            sample_timer <= 13'd0;
        else
            sample_timer <= sample_timer + 1'b1;
    end

    // ROM and playback control.
    // Each letter is 2048 bytes; concatenation maps letter n to n*2048.
    reg        playing;
    reg [4:0]  latched_idx;
    reg [10:0] sample_offset;
    wire       start_req = audio_trigger && !playing;
    wire [15:0] rom_addr = {latched_idx, sample_offset};
    wire [7:0]  rom_data;

    voice_rom u_voice_rom (
        .clk  (clk),
        .addr (rom_addr),
        .q    (rom_data)
    );

    // Unsigned PCM (0..255, silence at 128) -> signed 16-bit PCM.
    wire [15:0] pcm_now = {(rom_data ^ 8'h80), 8'h00};

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            playing       <= 1'b0;
            latched_idx   <= 5'd0;
            sample_offset <= 11'd0;
            audio_done    <= 1'b0;
        end else begin
            // A one-clock completion pulse, consumed by the flow FSM.
            audio_done <= 1'b0;

            if (start_req) begin
                if (letter_idx < 5'd26) begin
                    playing       <= 1'b1;
                    latched_idx   <= letter_idx;
                    sample_offset <= 11'd0;
                end
            end else if (playing && sample_tick) begin
                if (sample_offset == 11'd2047) begin
                    playing    <= 1'b0;
                    audio_done <= 1'b1;
                end else begin
                    sample_offset <= sample_offset + 1'b1;
                end
            end
        end
    end

    // Capture one sample per complete stereo frame so left and right
    // channels always transmit the same PCM value. The ROM output is
    // registered and has settled long before the next 48.8 kHz frame.
    reg [15:0] frame_sample;
    reg [15:0] shift_reg;
    reg [5:0]  bit_cnt;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            bit_cnt      <= 6'd0;
            aud_daclrck  <= 1'b0;
            frame_sample <= 16'h0000;
            shift_reg    <= 16'h0000;
            aud_dacdat   <= 1'b0;
        end else if (bclk_fall_ce) begin
            // The registered LRCK changes one BCLK before the channel MSB.
            // Counts 0..31 are left; counts 32..63 are right.
            if (bit_cnt == 6'd0)
                aud_daclrck <= 1'b0;
            else if (bit_cnt == 6'd32)
                aud_daclrck <= 1'b1;

            // Count 0 is the start of the left-channel slot. Latch the
            // current ROM sample once per stereo frame.
            if (bit_cnt == 6'd0) begin
                frame_sample <= playing ? pcm_now : 16'h0000;
                shift_reg    <= playing ? pcm_now : 16'h0000;
                aud_dacdat   <= 1'b0; // I2S one-bit delay slot
            end else if (bit_cnt == 6'd32) begin
                shift_reg  <= frame_sample;
                aud_dacdat <= 1'b0;   // I2S one-bit delay slot
            end else if ((bit_cnt >= 6'd1 && bit_cnt <= 6'd16) ||
                         (bit_cnt >= 6'd33 && bit_cnt <= 6'd48)) begin
                aud_dacdat <= shift_reg[15];
                shift_reg  <= {shift_reg[14:0], 1'b0};
            end else begin
                aud_dacdat <= 1'b0;
            end

            bit_cnt <= bit_cnt + 1'b1;
        end
    end

endmodule
