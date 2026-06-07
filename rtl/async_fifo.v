module async_fifo #(
    parameter AWIDTH = 4,
    parameter DWIDTH = 8
)(
    input  wire              wclk, wrst_n,
    input  wire              rclk, rrst_n,
    input  wire              winc,            
    input  wire              rinc,            
    input  wire [DWIDTH-1:0] wdata,
    output wire [DWIDTH-1:0] rdata,
    output wire              wfull,
    output wire              rempty
);
   
    wire [AWIDTH:0]   wptr_gray, rptr_gray;           
    wire [AWIDTH:0]   wptr_gray_sync, rptr_gray_sync; 
    wire [AWIDTH-1:0] waddr, raddr;                   

 
    sync_2ff #(.WIDTH(AWIDTH+1)) u_sync_w2r (
        .clk   (rclk),
        .rst_n (rrst_n),
        .d_in  (wptr_gray),
        .q_out (wptr_gray_sync)
    );

 
    sync_2ff #(.WIDTH(AWIDTH+1)) u_sync_r2w (
        .clk   (wclk),
        .rst_n (wrst_n),
        .d_in  (rptr_gray),
        .q_out (rptr_gray_sync)
    );

   
    wptr_full #(.AWIDTH(AWIDTH)) u_wptr_full (
        .wclk           (wclk),
        .wrst_n         (wrst_n),
        .winc           (winc),
        .rptr_gray_sync (rptr_gray_sync), 
        .wptr_gray      (wptr_gray),
        .waddr          (waddr),
        .wfull          (wfull)
    );

  
    rptr_empty #(.AWIDTH(AWIDTH)) u_rptr_empty (
        .rclk           (rclk),
        .rrst_n         (rrst_n),
        .rinc           (rinc),
        .wptr_gray_sync (wptr_gray_sync),  
        .rptr_gray      (rptr_gray),
        .raddr          (raddr),
        .rempty         (rempty)
    );

    fifomem #(.AWIDTH(AWIDTH),.DWIDTH(DWIDTH)) fifomem1 (
    .wclk(wclk),
    .winc(winc),
    .wfull(wfull),
    .waddr(waddr),
    .raddr(raddr),
    .wdata(wdata),
    .rdata(rdata));
endmodule
