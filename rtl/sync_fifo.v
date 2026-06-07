module sync_fifo #(
    parameter DEPTH  = 16,        
    parameter DWIDTH = 8
)(
    input  wire              clk, rst_n,
    input  wire              wr_en, rd_en,
    input  wire [DWIDTH-1:0] din,
    output reg  [DWIDTH-1:0] dout,
    output wire              full, empty
);
    localparam ADDR_W = $clog2(DEPTH);

    reg [DWIDTH-1:0] mem [0:DEPTH-1];

    reg [ADDR_W:0] wr_ptr;
    reg [ADDR_W:0] rd_ptr;
    
    
    always @(posedge clk or negedge rst_n) begin
    if (!rst_n)  wr_ptr<=0;
    else if((full!=1)&&(wr_en))
        begin
        mem[wr_ptr[ADDR_W-1:0]] <= din;
        wr_ptr<=wr_ptr+1;
        end
        end
    
    always @(posedge clk or negedge rst_n) begin
    if (!rst_n)  rd_ptr<=0;
    else if((empty!=1)&&(rd_en))
        begin
        dout<=mem[rd_ptr[ADDR_W-1:0]];
        rd_ptr<=rd_ptr+1;
        end
        end
        
    
 
    assign empty =(wr_ptr==rd_ptr);  
    assign full = (wr_ptr[ADDR_W-1:0] == rd_ptr[ADDR_W-1:0]) && (wr_ptr[ADDR_W] ^ rd_ptr[ADDR_W]);  
endmodule
