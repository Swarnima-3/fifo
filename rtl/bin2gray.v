module bin2gray #(parameter WIDTH = 5)(
    input  wire [WIDTH-1:0] bin,
    output wire [WIDTH-1:0] gray
);
    assign gray = bin ^ (bin >> 1);
endmodule
