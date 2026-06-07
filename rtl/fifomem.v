module fifomem #(
    parameter AWIDTH = 4,
    parameter DWIDTH = 8
)(
    input  wire              wclk,
    input  wire              winc,
    input  wire              wfull,
    input  wire [AWIDTH-1:0] waddr,
    input  wire [AWIDTH-1:0] raddr,
    input  wire [DWIDTH-1:0] wdata,
    output wire [DWIDTH-1:0] rdata
);
    localparam DEPTH = (1 << AWIDTH);
    reg [DWIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[waddr] <= wdata;
    end

    assign rdata = mem[raddr];
endmodule
