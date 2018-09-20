//
//Company:     UCD School of Electrical and Electronic Engineering
// Engineer:    Robert Keenan & Ciaran Nolan
//
// Module Name:    buttonCleanup
// Project Name:   Button Input Signal Cleanup
//
// Our Button Clean up module so we can prevent/ignore bounce
// We have instantiated a counter module for which we will use for delays to ignore possible bounce.


module buttonCleanup( input clk5,
                      input reset,
                      input raw,
                      output reg clean );

                      reg [2:0] currentState, nextState; //States
                      wire delayPassed;                  //Output from the Counter/timer..Input to SM
                      reg timerControl;                  //Input to the counter for MUX..Output from SM

                      //Defining states as localparams
                      localparam [2:0]  IDLE = 3'b000,
                                        BTNPRESSED = 3'b001,
                                        DELAY1 = 3'b010,
                                        BTNstillPRESSED = 3'b011,
                                        BUTTONunPRESSED = 3'b100;

                      //State Register
                      always @(posedge clk5)
                          if(reset)
                            currentState <= IDLE;
                          else
                            currentState <= nextState;

                      //Next State Logic
                      always @(currentState, raw, delayPassed )
                        case(currentState)
                          IDLE: begin
                                    timerControl = 1'b0;    //Output to counter is zero
                                    if(raw)
                                      nextState = BTNPRESSED;  //Button is now pressed
                                    else
                                      nextState = IDLE;       //Loop in IDLE
                                  end
                          BTNPRESSED: begin
                                    nextState = DELAY1; //Pass straight through regardless of inputs
                                    timerControl = 1'b0;  //Not starting counter
                                  end
                          DELAY1: begin
                                    timerControl = 1'b1;  //Start Counter
                                    if(!delayPassed)
                                      nextState = DELAY1; //Stay in state until 8ms has passed
                                    else
                                      nextState = BTNstillPRESSED;
                                  end
                         BTNstillPRESSED: begin
                                    timerControl = 1'b0;
                                    if(!raw)
                                      nextState = BUTTONunPRESSED; //Do not transition until user stops pressing button
                                    else
                                      nextState = BTNstillPRESSED;
                                  end
                          BUTTONunPRESSED:
                      begin
                                    timerControl = 1'b1; //Start counter again to compensate for bounce on release of button
                                    if(!delayPassed)
                                      nextState = BUTTONunPRESSED;
                                    else
                                      nextState = IDLE;
                                  end
                          default:begin
                                    nextState = IDLE;    //Compensating for the other states
                                    timerControl = 1'b0;
                                  end
                        endcase

                      //Instantiation of counter to count to 8ms and output a 1
                      countTimer delayCounter(.clk(clk5),.rst(reset),.timerControl(timerControl), .timerOut(delayPassed));

                      //Output Logic - > Only one output from our module but two from our state machine.
                      always @(currentState)
                        case(currentState)
                          IDLE: clean = 1'b0;
                          BTNPRESSED: clean = 1'b1;
                          DELAY1: clean = 1'b0;
                          BTNstillPRESSED: clean = 1'b0;
                          BUTTONunPRESSED: clean = 1'b0;
                          default: clean = 1'b0;
                        endcase

endmodule
