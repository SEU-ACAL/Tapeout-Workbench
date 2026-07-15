`timescale 1ns/1ps

module tb_shift_reg;
    localparam WIDTH = 4;

    reg  clk;
    reg  rst_n;
    reg  en;
    reg  din;
    wire [WIDTH-1:0] q;

    shift_reg #(.WIDTH(WIDTH)) dut (
        .clk (clk),
        .rst_n (rst_n),
        .en  (en),
        .din (din),
        .q   (q)
    );

    // clock
    initial clk = 0;
    always #5 clk = ~clk;

    // waveform dump (FSDB)
    initial begin
        $fsdbDumpfile("shift_reg.fsdb");
        $fsdbDumpvars(0, tb_shift_reg);
    end

    initial begin
        rst_n = 0;
        en    = 0;
        din   = 0;

        #12;
        rst_n = 1;
        en    = 1;

        // shift in 1,0,1,1
        din = 1; #10;
        din = 0; #10;
        din = 1; #10;
        din = 1; #10;

        // hold
        en = 0; din = 0; #20;

        $finish;
    end
endmodule