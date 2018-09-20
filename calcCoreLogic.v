`timescale 1ns / 1ps
//
//Core Logic Module
//
//Handles the interaction of the registers and combo block
//
//
//
//
//
//
//
//
//
module calcCoreLogic( input newkey,
                      input clock,
                      input reset,
                      input [4:0] keycode,
                      output [16:0] valueOutput
                      );

                     reg [16:0] xRegOutput, yRegOutput;
                     reg [16:0] xIn, yIn;
                     reg [16:0] outputCombLogicOVF; //Comb Logic containing overflow
                     reg [3:0] opOutput , opIn;
                     reg lastInputX;
                     wire equalsCompare, clearEntry, clearAll, NumSquared, deletePressed;
                     wire [16:0] clearDelete;


                    //Operator Register
                    always @(posedge clock)
                      if(reset)
                          opOutput<= 4'b0;
                      else if(newkey)
                          opOutput<=opIn;
                      else
                          opOutput<=opOutput;

                  //Invalid code that determines whether an operator has not been pushed----> do normal addition
                  //If operator has been pushed, have a flag that says one has been pushed but then if i go to press another
                  //Have feedback back into the Op Mux deciding whether one has been pressed already and whether one is pressed now
                  //In that case, I'm gonna load the output of the combinational logic
                  //Comparator variables for equals, CE, CA and the Squared operator

                    assign equalsCompare = (keycode == 5'b00100);
                    assign clearAll = (keycode == 5'b00011);
                    assign NumSquared = (keycode == 5'b01100);
                    assign clearEntry = (keycode == 5'b00001);
                    assign deletePressed = (keycode == 5'b00010);

                    //Operator MUX
                    always @(keycode, equalsCompare, opOutput)
                        casez({keycode[4],equalsCompare})
                            2'b00: opIn = keycode[3:0]; //Equals not pressed-load 3LSBs as this tells us what operator is being used
                            2'b?1: opIn = 4'b0; //Equals is pressed and so flush the reg
                            2'b10: opIn = opOutput; //So if a non operator key is pressed, feedback reg value for no equals pressed
                            default: opIn = 4'b0;
                        endcase

///////////////////////////////////////////////////////////////////////////////////////////////////////////

                    //Make sure to use the output from the logic block as an input to the X closest MUX
                    //X Register
                    always @(posedge clock)
                        if(reset)
                            xRegOutput<=17'b0;
                        else if(newkey)
                            xRegOutput<=xIn;
                        else
                            xRegOutput<=xRegOutput;


                    assign valueOutput = xRegOutput; //Assigning the output port value from the module to the xRegOutput


                    //On a delete key
                    assign clearDelete[11:0] = xRegOutput[15:4]; //Set MSBs of Output back 4 places
                    assign clearDelete[16:12] = 5'b0000;         //Add 4 0's as the new MSBs

                    //X Register Input Mux
                    always @(keycode, xRegOutput, outputCombLogicOVF, clearDelete, lastInputX)
                        casez({keycode, lastInputX})
                            6'b1????1: xIn = (keycode[3:0] + (xRegOutput*16'd16)); //Digit entered ---> prev. val. digit
                            6'b00100?: xIn = outputCombLogicOVF;           //Equals pressed---> prev val. = digit //If i press delete a number and then want to press equals i need a question mark
                            6'b011001: xIn = xRegOutput*xRegOutput;      //Squared pressed--> prev.val = digit
                            6'b00010?: xIn = clearDelete;                  //Clear Entry, delete last entered digit....dont care what the last entered is
                            6'b010??1: xIn = xRegOutput;                   //Operator pressed ---> prev. val. number
                            6'b1????0: xIn = {13'b0,keycode[3:0]};         //Entry digit---> prev. val. operator
                            6'b000?1?: xIn = 17'b0;                        //Clear the X reg //Clear Entry
                            default: xIn = xRegOutput;                     //Default, take old value
                        endcase

                    //Tracking which value was entered last
                    always @(posedge clock)
                        if(reset)
                            lastInputX <= 1'b0;
                       else if(newkey)
                            lastInputX <= keycode[4];
                        else
                            lastInputX <= lastInputX;

                    //Delay MUX - WIll hold value from the x register after a operator press so that


///////////////////////////////////////////////////////////////////////////////////////////////////////////

                    //Y Register as a block
                    always @(posedge clock)
                        if(reset)
                            yRegOutput<=17'b0;
                        else if(newkey)
                            yRegOutput<=yIn;
                        else
                            yRegOutput<=yRegOutput;

                    //Y register input mux
                    always @(keycode, xRegOutput, yRegOutput, NumSquared, clearEntry, deletePressed)
                        casez({keycode[4:3], NumSquared,clearEntry, deletePressed})
                            5'b010??: yIn = xRegOutput; //If other operator pushed, but not equals, squared or clear Entry/all, take x Reg
                            5'b00?00: yIn = 17'b0; //Clear Entry has not been pushed- Clear ALL or Equal has so zero Reg
                            default: yIn = yRegOutput;
                        endcase

                    //Now look at top level module for joining all of the modules together
                    //Combination logic placed here, can be placed in separate module at centre
                    always @(opOutput,xRegOutput,yRegOutput)
                        case(opOutput)
                            4'b1001: outputCombLogicOVF = (xRegOutput + yRegOutput); //Adding
                            4'b1010: outputCombLogicOVF = (xRegOutput * yRegOutput); //Multiplication
                            4'b1011: outputCombLogicOVF = (yRegOutput - xRegOutput); //Subtraction
                            default: outputCombLogicOVF = 17'b0;
                        endcase
endmodule
