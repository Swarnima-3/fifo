`timescale 1ns/1ps
module tb_async_fifonew;
    parameter AWIDTH = 4;
    parameter DWIDTH = 8;

    reg                wclk, wrst_n, winc;
    reg                rclk, rrst_n, rinc;
    reg  [DWIDTH-1:0]  wdata;
    wire [DWIDTH-1:0]  rdata;
    wire               wfull, rempty;

    async_fifo #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) dut1 (
        .wclk(wclk), .wrst_n(wrst_n), .rclk(rclk), .rrst_n(rrst_n),
        .winc(winc), .rinc(rinc),
        .wdata(wdata), .rdata(rdata),
        .wfull(wfull), .rempty(rempty)
    );

  
    initial wclk = 0;
    always #5   wclk = ~wclk;     // 100 MHz  
    initial rclk = 0;
    always #7   rclk = ~rclk;     // ~71 MHz  

  
    initial begin
        wrst_n = 0; winc = 0; wdata = 0;
        repeat (3) @(posedge wclk);
        wrst_n = 1;

        winc = 1;                          
        forever begin
            @(posedge wclk);
            if (!wfull) wdata = wdata + 1; 
        end
    end


    initial begin
        rrst_n = 0; rinc = 0;
        repeat (3) @(posedge rclk);
        rrst_n = 1;

        repeat (5) @(posedge rclk);       
        rinc = 1;                         
    end

    initial begin
        #1000 $finish;
    end
