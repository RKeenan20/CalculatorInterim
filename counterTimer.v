//////////////////////////////////////////////////////////////////////////////////
// Company:     UCD School of Electrical and Electronic Engineering
// Engineer:    Robert Keenan & Ciaran Nolan
//
// Module Name:    countTimer
// Project Name:   Button Input Signal Cleanup

//////////////////////////////////////////////////////////////////////////////////
module countTimer(
        input clk,              // clock signal
        input rst,              // reset, synchronous, active high
        input timerControl,     //Enable to start the counter
        output timerOut );  //Output 1 when 8ms has passed, 0 otherwise

    localparam comparator = 39999;  //Comparator Value to count to 8ms and then output
    reg [15:0] count, nextCount;      //next count value

    //  Count register - 16 bit
    always @ (posedge clk)
        if (rst) count <= 16'b0;
        else count <= nextCount;

    //Input Mux - Dependent on the control Value from the State Machine
    always @(timerControl, count)
        case(timerControl)
            1'b1: nextCount = count + 1'b1;
            1'b0: nextCount = 16'b0;
        endcase

    //Comparator - IF count is equal to comparator value, assign timerOut = 1, otherwise 0
    assign timerOut = (count == comparator);

endmodule
