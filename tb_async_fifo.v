`timescale 1ns / 1ps

module tb_async_fifo;
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;

    reg wclk, wrst_n, wr_en;
    reg rclk, rrst_n, rd_en;
    reg [DATA_WIDTH-1:0] wdata;
    wire [DATA_WIDTH-1:0] rdata;
    wire wfull, rempty;

    // Instantiate the Unit Under Test (UUT)
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .wclk(wclk), .wrst_n(wrst_n), .wr_en(wr_en), .wdata(wdata),
        .rclk(rclk), .rrst_n(rrst_n), .rd_en(rd_en), .rdata(rdata),
        .wfull(wfull), .rempty(rempty)
    );

    // Clock Generation
    initial wclk = 0; always #5 wclk = ~wclk;    // 100MHz
    initial rclk = 0; always #12.5 rclk = ~rclk; // 40MHz

    // ==========================================================
    // ONLY WPTR AND RPTR MONITORING LOGIC
    // ==========================================================
    initial begin
        $display("\n--- Pointers Monitoring Started ---");
        $display("Time (ns) | Write_Ptr (Gray) | Read_Ptr (Gray) | Full | Empty");
        $display("---------------------------------------------------------------");
        
        // Hierarchical path se internal pointers ko monitor karna
        forever begin
            @(uut.wptr or uut.rptr); // Jab bhi koi pointer badle
            $display("%0t\t  | %b\t     | %b\t       | %b    | %b", 
                     $time, uut.wptr, uut.rptr, wfull, rempty);
        end
    end
    // ==========================================================

    initial begin
        // Initialize
        wrst_n = 0; rrst_n = 0; wr_en = 0; rd_en = 0; wdata = 0;
        #30 wrst_n = 1; rrst_n = 1;
        #20;

        // Writing Phase
        repeat (16) begin
            @(posedge wclk);
            if (!wfull) begin
                wr_en = 1;
                wdata = wdata + 1;
            end
        end
        @(posedge wclk) wr_en = 0;

        #100;

        // Reading Phase
        repeat (16) begin
            @(posedge rclk);
            if (!rempty) rd_en = 1;
        end
        @(posedge rclk) rd_en = 0;

        #100;
        $display("--- Simulation Finished ---");
        $finish;
    end
endmodule