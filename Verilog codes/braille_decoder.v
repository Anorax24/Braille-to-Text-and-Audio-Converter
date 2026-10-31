// ============================================================================
// Module: Braille Pattern -> ASCII & Letter Index (dots[0]=dot1 ... dots[5]=dot6)
// ============================================================================
module braille_decoder (
    input  wire [5:0] dots,
    output reg  [7:0] ascii_char,
    output reg  [4:0] letter_idx,
    output reg        valid
);
    always @(*) begin
        valid      = 1'b1;
        ascii_char = "?";
        letter_idx = 5'd0;

        case (dots)
            6'b000001: begin ascii_char = "A"; letter_idx = 5'd0;  end
            6'b000011: begin ascii_char = "B"; letter_idx = 5'd1;  end
            6'b001001: begin ascii_char = "C"; letter_idx = 5'd2;  end
            6'b011001: begin ascii_char = "D"; letter_idx = 5'd3;  end
            6'b010001: begin ascii_char = "E"; letter_idx = 5'd4;  end
            6'b001011: begin ascii_char = "F"; letter_idx = 5'd5;  end
            6'b011011: begin ascii_char = "G"; letter_idx = 5'd6;  end
            6'b010011: begin ascii_char = "H"; letter_idx = 5'd7;  end
            6'b001010: begin ascii_char = "I"; letter_idx = 5'd8;  end
            6'b011010: begin ascii_char = "J"; letter_idx = 5'd9;  end
            6'b000101: begin ascii_char = "K"; letter_idx = 5'd10; end
            6'b000111: begin ascii_char = "L"; letter_idx = 5'd11; end
            6'b001101: begin ascii_char = "M"; letter_idx = 5'd12; end
            6'b011101: begin ascii_char = "N"; letter_idx = 5'd13; end
            6'b010101: begin ascii_char = "O"; letter_idx = 5'd14; end
            6'b001111: begin ascii_char = "P"; letter_idx = 5'd15; end
            6'b011111: begin ascii_char = "Q"; letter_idx = 5'd16; end
            6'b010111: begin ascii_char = "R"; letter_idx = 5'd17; end
            6'b001110: begin ascii_char = "S"; letter_idx = 5'd18; end
            6'b011110: begin ascii_char = "T"; letter_idx = 5'd19; end
            6'b100101: begin ascii_char = "U"; letter_idx = 5'd20; end
            6'b100111: begin ascii_char = "V"; letter_idx = 5'd21; end
            6'b111010: begin ascii_char = "W"; letter_idx = 5'd22; end
            6'b101101: begin ascii_char = "X"; letter_idx = 5'd23; end
            6'b111101: begin ascii_char = "Y"; letter_idx = 5'd24; end
            6'b110101: begin ascii_char = "Z"; letter_idx = 5'd25; end
            default:   begin ascii_char = "?"; letter_idx = 5'd0;  valid = 1'b0; end
        endcase
    end
endmodule

