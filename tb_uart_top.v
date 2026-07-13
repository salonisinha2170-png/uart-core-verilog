`timescale 1ns/1ps

module tb_uart_tx();

    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg [7:0]  tx_data;
    wire       tx;
    wire       tx_busy;

    // DUT Link
    uart_tx dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_uart_tx);

        clk      = 0;
        rst_n    = 0;   
        tx_start = 0;
        tx_data  = 8'b0;
        
        #20;            
        rst_n    = 1;   
        #20;

        // TEST CASE 1
        tx_data  = 8'b10100101; 
        tx_start = 1;   
        #10;            
        tx_start = 0;   

        #120; 

        // TEST CASE 2
        tx_data  = 8'b11110000;
        tx_start = 1;
        #10;
        tx_start = 0;

        #120;
        
        $finish; 
    end

endmodule
