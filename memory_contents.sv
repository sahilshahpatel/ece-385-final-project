//-------------------------------------------------------------------------
//      memory_contents.sv                                               --
//      The memory contents in the test memory.                          --
//                                                                       --
//      Originally contained in test_memory.sv                           --
//      Revised 10-19-2017 by Anand Ramachandran and Po-Han Huang        --
//      Revised 02-01-2018 by Yikuan Chen
//                        spring 2018 Distribution                       --
//                                                                       --
//      For use with ECE 385 Experment 6                                 --
//      UIUC ECE Department                                              --
//-------------------------------------------------------------------------
module memory_parser;

parameter size = 524288;

task memory_contents(output logic[15:0] mem_array[0:size-1]); 
   
   for (integer i = 0; i <= size - 1; i = i + 1)		// Assign the rest of the memory to 0
   begin
       mem_array[i] = 16'b0;
   end

endtask

endmodule
