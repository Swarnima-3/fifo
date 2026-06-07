`timescale 1ns / 1ps

module sync_2ff #(
    parameter WIDTH = 5
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] d_in,    
    output reg  [WIDTH-1:0] q_out   
);
  
    reg [WIDTH-1:0] ff1 ;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_out<=0;
            ff1<=0;
        end else begin
          
            ff1<=d_in;
            q_out<=ff1;
        end
    end
endmodule
