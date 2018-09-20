`timescale 1ns / 1ps
//
//Group Number: 22
//
//Members: Robert Keenan & Ciaran Nolan
//
//Project Title: Calculator Design
//
//Description of Module:
//  This module is the core logic of the calculator describing each register, calculation block,
//  multiplexer and inputs from the keypad.
//  Its outputs are overflowLED and valueOutput. The former is an output from the top-level module
//  for use on hardware (LED on board) while the latter is used by the display interface module to display
//  digits/operations/results on the 7 segment display
//
//
//
//
module calcCoreLogic( input newkey,
                      input clock,
                      input reset,
                      input [4:0] keycode,
                      output [15:0] valueOutput,    //16 bit output to display interface
                      output overflowLED );         //LED to detect overflow

                     reg [16:0] xRegOutput, yRegOutput; //X,Y Register outputs
                     reg [16:0] xIn, yIn;               //X,Y Register inputs
                     reg [16:0] outputCombLogicOVF;     //Calculation result
                     reg [1:0] opOutput , opIn;         //Operator register output and input
                     reg lastInputX;                    //Tracking what kind last entered key was
                     wire clearEntry,NumSquared, deletePressed; //Comparators for non
                                                                //algebraic operator keys
                     wire [16:0] clearDelete;           //Delete wire


                    //Operator Register
                    always @(posedge clock)
                      if(reset)
                          opOutput<= 2'b0;
                      else if(newkey)   //Only change value when newkey is 1
                          opOutput<=opIn;
                      else
                          opOutput<=opOutput;

                    //Assigning comparators
                    assign NumSquared = (keycode == 5'b01100);
                    assign clearEntry = (keycode == 5'b00001);
                    assign deletePressed = (keycode == 5'b00010);

                    //Operator Multiplexer
                    always @(keycode, opOutput)
                        casez(keycode)
                            5'b010??: opIn = keycode[1:0]; //Set output to type of operator-
                            5'b00011: opIn = 2'b0; //CA pressed so flush register with zeroes
                            5'b00100: opIn = 2'b0; //Equals pressed
                            default: opIn = opOutput; //Default
                        endcase

///////////////////////////////////////////////////////////////////////////////////////////////////////////
                    //X Register Description
                    always @(posedge clock)
                        if(reset)
                            xRegOutput<=17'b0;
                        else if(newkey)         //Again, only change output when newkey=1
                            xRegOutput<=xIn;
                        else
                            xRegOutput<=xRegOutput;


                    assign valueOutput = xRegOutput[15:0]; //Value output port is 16 LSBs of X register
                    assign overflowLED = xRegOutput[16];   //Overflow LED is 17th bit

                    //When delete key pressed, replace right most digit
                    assign clearDelete[11:0] = xRegOutput[15:4]; //Shift MSBs of X output to new LSBs
                    assign clearDelete[16:12] = 5'b0;         //Add 4 zeroes as the new MSBs

                    //X Register Input Multiplexer
                    always @(keycode, xRegOutput, outputCombLogicOVF, clearDelete, lastInputX)
                        casez({keycode, lastInputX})
                            6'b1????1: xIn = (keycode[3:0] + (xRegOutput*13'd16)); //Digit entered|prev. val. digit
                            6'b00100?: xIn = outputCombLogicOVF;           //Equals pressed|prev val. = dont care
                            6'b011001: xIn = xRegOutput*xRegOutput;       //Squared pressed|prev.val = digit
                            6'b00010?: xIn = clearDelete;                  //Delete key
                            6'b010??1: xIn = xRegOutput;                   //Operator pressed|prev. val. number
                            6'b1????0: xIn = {13'b0,keycode[3:0]};         //Entry digit|prev. val. operator
                            6'b000?1?: xIn = 17'b0;                        //CE or CA
                            default: xIn = xRegOutput;                     //Default
                        endcase

                    //Keeping note of which type of key pressed last
                    //Need this to keep operand on display after operator press
                    always @(posedge clock)
                        if(reset)
                            lastInputX <= 1'b0;
                        else if(newkey)
                            lastInputX <= keycode[4]; //Type of key pressed last
                        else
                            lastInputX <= lastInputX;

///////////////////////////////////////////////////////////////////////////////////////////////////////////

                    //Y Register Description
                    always @(posedge clock)
                        if(reset)
                            yRegOutput<=17'b0;
                        else if(newkey)
                            yRegOutput<=yIn;
                        else
                            yRegOutput<=yRegOutput;

                    //Y register input Multiplexer
                    always @(keycode, xRegOutput, yRegOutput, NumSquared, clearEntry, deletePressed)
                        case({keycode[4:3], NumSquared,clearEntry, deletePressed})
                            5'b01000: yIn = xRegOutput; //Algebraic operator pressed - Not squared
                            5'b00000: yIn = 17'b0;      //CA or Equals has been pressed
                            default: yIn = yRegOutput;  // Default
                        endcase


                    //Calculating the results
                    always @(opOutput,xRegOutput,yRegOutput)
                        case(opOutput)
                            2'b01: outputCombLogicOVF = (xRegOutput + yRegOutput); //Addition
                            2'b10: outputCombLogicOVF = (xRegOutput * yRegOutput); //Multiplication
                            2'b11: outputCombLogicOVF = (yRegOutput - xRegOutput); //Subtraction
                            default: outputCombLogicOVF = 17'b0; //Default
                        endcase
endmodule
