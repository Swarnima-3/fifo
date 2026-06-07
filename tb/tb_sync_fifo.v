`timescale 1ns/1ps
module tb_sync_fifo;
   
    reg         clk, rst_n;
    reg         wr_en, rd_en;
    reg  [7:0]  din;
    wire [7:0]  dout;
    wire        full, empty;

    sync_fifo #(.DEPTH(16), .DWIDTH(8)) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .rd_en(rd_en),
        .din(din), .dout(dout),
        .full(full), .empty(empty)
    );

  
    always #5 clk=~clk;

    initial begin
        
        clk = 0; rst_n = 0; wr_en = 0; rd_en = 0; din = 0;
        #20 rst_n = 1;        

        wr_en = 1;
        repeat (16) 
        begin
        @(posedge clk);     
        din = din + 1;      
        end
        
        @(posedge clk);
        wr_en = 0;             
        
        rd_en = 1;
            repeat (5) @(posedge clk);   
            rd_en = 0;


        #200 $finish;       
    end
endmodule
