

`timescale 1ns/1ps
module tb_async_fifo1;
    localparam AWIDTH = 4, DWIDTH = 8;

    reg               wclk = 0, wrst_n = 0, winc = 0;
    reg               rclk = 0, rrst_n = 0, rinc = 0;
    reg  [DWIDTH-1:0] wdata = 0;
    wire [DWIDTH-1:0] rdata;
    wire              wfull, rempty;

    async_fifo #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) dut (
        .wclk(wclk), .wrst_n(wrst_n), .rclk(rclk), .rrst_n(rrst_n),
        .winc(winc), .rinc(rinc), .wdata(wdata), .rdata(rdata),
        .wfull(wfull), .rempty(rempty));

    localparam WR_SLOW = 1;
    localparam WHALF = WR_SLOW ? 7 : 5;
    localparam RHALF = WR_SLOW ? 5 : 7;
    always #(WHALF) wclk = ~wclk;
    always #(RHALF) rclk = ~rclk;


    logic [DWIDTH-1:0] model [$];
    integer errors = 0, writes = 0, reads = 0;
    integer cov_wfull = 0, cov_rempty = 0;
    logic [DWIDTH-1:0] exp;

    initial begin
        $dumpfile("tb_async_fifo1.vcd");
        $dumpvars(0, tb_async_fifo1);
    end

    
    always @(negedge wclk) if (wrst_n) begin
        winc = $random;
        if (winc && !wfull) begin
            wdata = wdata + 1;
            model.push_back(wdata);
            writes = writes + 1;
        end else if (winc && wfull) begin
            cov_wfull = cov_wfull + 1;
        end
    end

   
    always @(negedge rclk) if (rrst_n) begin
        rinc = $random;
        if (rinc && !rempty) begin
            if (model.size() == 0) begin
                errors = errors + 1;
                $error("UNDERFLOW: read with empty model");
            end else begin
                exp = model.pop_front();
                if (rdata !== exp) begin
                    errors = errors + 1;
                    $error("MISMATCH: got %02h, expected %02h", rdata, exp);
                end
                reads = reads + 1;
            end
        end else if (rinc && rempty) begin
            cov_rempty = cov_rempty + 1;
        end
    end

    
    initial begin
        repeat (4) @(negedge wclk); wrst_n = 1;
        repeat (4) @(negedge rclk); rrst_n = 1;

        repeat (3000) @(negedge wclk);   

        $display("=======================================");
        $display(" ASYNC FIFO  (WR_SLOW=%0d)", WR_SLOW);
        $display(" writes=%0d reads=%0d", writes, reads);
        $display(" coverage: wfull-attempts=%0d  rempty-attempts=%0d",
                 cov_wfull, cov_rempty);
        $display(" errors=%0d", errors);
        if (errors == 0) $display(" RESULT: *** PASS ***");
        else             $display(" RESULT: *** FAIL ***");
        $display("=======================================");
        $finish;
    end
endmodule
