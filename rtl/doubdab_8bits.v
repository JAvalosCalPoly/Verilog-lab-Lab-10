`timescale 1ns/1ps

module doubdab_8bits(
    input [7:0] b_in,
    output [11:0] bcd_out
    );

//
// Fill in the connections and wires to implement the double-dabble algorithm
//  
//   
    wire [3:0] b1, b2, b3, b4, b5, b6, b7;

    dd_add3 u1 (.i({1'b0 , b_in[7:5]}),
                .o(b1));
    
    dd_add3 u2 (.i({b1[2:0] , b_in[4]}),
                .o(b2));

    dd_add3 u3 (.i({b2[2:0] , b_in[3]}),
                .o(b3));
    
    dd_add3 u4 (.i({b3[2:0] , b_in[2]}),
                .o(b4));

    dd_add3 u5 (.i({b4[2:0] , b_in[1]}),
                .o(b5));
    
    dd_add3 u6 (.i({1'b0 , b1[3] , b2[3] , b3[3]}),
                .o(b6));
                
    dd_add3 u7 (.i({b6[2:0] , b4[3]}),
                .o(b7));

    assign bcd_out = {2'b0 , b6[3] , b7 , b5 , b_in[0]};
     
endmodule
