

`timescale 1ns/1ps
module tb_sync_fifo1;
    localparam DEPTH = 16, DWIDTH = 8;

    reg              clk = 0, rst_n = 0;
    reg              wr_en = 0, rd_en = 0;
    reg  [DWIDTH-1:0] din = 0;
    wire [DWIDTH-1:0] dout;
    wire             full, empty;

    sync_fifo #(.DEPTH(DEPTH), .DWIDTH(DWIDTH)) dut (
        .clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en),
        .din(din), .dout(dout), .full(full), .empty(empty));

    always #5 clk = ~clk;

    logic [DWIDTH-1:0] model [$];        
    integer errors = 0;
    integer writes = 0, reads = 0;
    integer cov_wr_full = 0, cov_rd_empty = 0;   
    logic [DWIDTH-1:0] exp;
    bit check_next = 0;

  
    initial begin
        $dumpfile("tb_sync_fifo1.vcd");
        $dumpvars(0, tb_sync_fifo1);
    end

    always @(negedge clk) if (rst_n) begin

        
        if (check_next) begin
            if (dout !== exp) begin
                errors = errors + 1;
                $error("MISMATCH: got %02h, expected %02h", dout, exp);
            end
            check_next = 0;
        end

        
        wr_en = $random;
        rd_en = $random;

        if(wr_en==1&&full!==1)begin
        din = din + 1;
        model.push_back(din);
        writes=writes+1;
        end
        else if(wr_en==1&&full==1)begin
        cov_wr_full=cov_wr_full+1;
        
        end

     
        if(rd_en==1&&empty!==1)begin
        exp=model.pop_front();
        check_next = 1;
        reads=reads+1;
        
        end
        else if(rd_en==1&&empty==1)begin
        cov_rd_empty=cov_rd_empty+1;
        
        end
      
        
    end

   
    initial begin
        repeat (4) @(negedge clk);
        rst_n = 1;
        repeat (2000) @(negedge clk);     

        $display("=======================================");
        $display(" writes=%0d reads=%0d", writes, reads);
        $display(" coverage: write-while-full=%0d  read-while-empty=%0d",
                 cov_wr_full, cov_rd_empty);
        $display(" errors=%0d", errors);
        if (errors == 0) $display(" RESULT: *** PASS ***");
        else             $display(" RESULT: *** FAIL ***");
        $display("=======================================");
        $finish;
    end
endmodule
