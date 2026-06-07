module rptr_empty #(
    parameter AWIDTH = 4
)(
    input  wire            rclk,
    input  wire            rrst_n,
    input  wire            rinc,             
    input  wire [AWIDTH:0] wptr_gray_sync,   
    output wire [AWIDTH:0] rptr_gray,        
    output wire [AWIDTH-1:0] raddr,         
    output wire            rempty
);
    reg [AWIDTH:0] rbin;

    
    always@(posedge rclk or negedge rrst_n) begin
    if(!rrst_n) rbin<=0;
    
    else if(rinc && !rempty) begin
    rbin<=rbin+1;
    
    end
    
    end
    assign raddr=rbin[AWIDTH-1:0];
   
  
    bin2gray #(.WIDTH(AWIDTH+1)) u1_b2g (.bin(rbin),.gray(rptr_gray));
    assign rempty =(rptr_gray==wptr_gray_sync);
  
endmodule
