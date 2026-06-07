module wptr_full #(
    parameter AWIDTH = 4         
)(
    input  wire            wclk,
    input  wire            wrst_n,
    input  wire            winc,            
    input  wire [AWIDTH:0] rptr_gray_sync,  
    output wire [AWIDTH:0] wptr_gray,      
    output wire [AWIDTH-1:0] waddr,        
    output wire            wfull
);
   
    reg [AWIDTH:0] wbin;

    
    always @(posedge wclk or negedge wrst_n) begin
        if(!wrst_n) wbin<=0;
        
        else if(winc && !wfull)begin 
        wbin<=wbin+1;
        end
        
    end

  
    assign waddr = wbin[AWIDTH-1:0];

  
    bin2gray #(.WIDTH(AWIDTH+1)) u_b2g (.bin(wbin),.gray(wptr_gray));

  
    assign wfull = (wptr_gray == {~rptr_gray_sync[AWIDTH:AWIDTH-1], rptr_gray_sync[AWIDTH-2:0]});
endmodule
