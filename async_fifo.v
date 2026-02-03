`timescale 1ns / 1ps
module async_fifo #(parameter DATA_WIDTH = 8, ADDR_WIDTH = 4) (
    input                     wclk, wrst_n, wr_en,
    input                     rclk, rrst_n, rd_en,
    input  [DATA_WIDTH-1:0]   wdata,
    output [DATA_WIDTH-1:0]   rdata,
    output reg                wfull,
    output reg                rempty
);

    reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH:0] wbin, rbin;
    reg [ADDR_WIDTH:0] wptr, rptr;
    reg [ADDR_WIDTH:0] wptr_sync1, wptr_sync2;
    reg [ADDR_WIDTH:0] rptr_sync1, rptr_sync2;

    // --- Write Logic ---
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin <= 0;
            wptr <= 0;
        end else if (wr_en && !wfull) begin
            wbin <= wbin + 1;
            wptr <= (wbin + 1) ^ ((wbin + 1) >> 1); // Binary to Gray
            mem[wbin[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // --- Read Logic ---
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin <= 0;
            rptr <= 0;
        end else if (rd_en && !rempty) begin
            rbin <= rbin + 1;
            rptr <= (rbin + 1) ^ ((rbin + 1) >> 1); // Binary to Gray
        end
    end
    assign rdata = mem[rbin[ADDR_WIDTH-1:0]];

    // --- Synchronization ---
    // Read pointer ko Write domain mein sync karna
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) {rptr_sync2, rptr_sync1} <= 0;
        else {rptr_sync2, rptr_sync1} <= {rptr_sync1, rptr};
    end
    // Write pointer ko Read domain mein sync karna
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) {wptr_sync2, wptr_sync1} <= 0;
        else {wptr_sync2, wptr_sync1} <= {wptr_sync1, wptr};
    end

    // --- Flags Generation ---
    always @(*) begin
        rempty = (wptr_sync2 == rptr);
        // Full condition: MSB aur second MSB different ho, baaki bits same
        wfull  = (wptr == {~rptr_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rptr_sync2[ADDR_WIDTH-2:0]});
    end

endmodule