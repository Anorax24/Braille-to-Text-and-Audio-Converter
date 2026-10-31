// ============================================================================
// Module: Voice ROM (inferred M9K block RAM, initialised from voice_rom.mif)
//   53,248 x 8 bit = 26 letters x 2048 samples
// ============================================================================
module voice_rom (
    input  wire        clk,
    input  wire [15:0] addr,
    output reg  [7:0]  q
);
    (* ram_init_file = "voice_rom.mif" *) reg [7:0] memory [0:53247];

    always @(posedge clk) begin
        q <= memory[addr];
    end
endmodule