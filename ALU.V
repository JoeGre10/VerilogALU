module ALU (ALUctl, A, B, ALUOut, Zero, OverFlow);
    input [2:0] ALUctl;
    input [3:0] A,B;
    output [3:0] ALUOut;
    output Zero,OverFlow;
    
    wire [3:0] andResult, orResult, addResult, subResult, sltResult;
    wire addOverflow, subOverflow, addFlow, subFlow;
    wire [3:0] BComp; // 2's complement for subtraction
    wire BGreater,subCheck,addCheck,notZero,notOne,notTwo; // For SLT (Set Less Than)

    // AND and OR operations
    and(andResult[3], A[3], B[3]);  // Bitwise AND
    and(andResult[2], A[2], B[2]);
    and(andResult[1], A[1], B[1]);
    and(andResult[0], A[0], B[0]);
    
    or (orResult[3], A[3], B[3]);   // Bitwise OR
    or (orResult[2], A[2], B[2]);
    or (orResult[1], A[1], B[1]);
    or (orResult[0], A[0], B[0]);
    //Adding - 010 
    _4bit_adder adder(addResult, addFlow, A, B,1'b0);
    
    // Subtracting - 110
    comp compliment(B, BComp);
    _4bit_adder subAdder(subResult, subFlow, A, BComp, 1'b0);

    //B Greater?- 111    module fourBitGreaterTest (A, B, BGreater); // tests if B is greater than A (4bit)
    
    fourBitGreaterTest greater(A,B,BGreater);
    
    
    //module myMux8(in0, in1, in2, in3, in4, in5, in6, in7, sel, out);
    //             0           1          2            3    4    5       6           7
    myMux8 mux0(andResult[0],orResult[0],addResult[0],1'b0,1'b0,1'b0, subResult[0], BGreater, ALUctl, ALUOut[0]);
    myMux8 mux1(andResult[1],orResult[1],addResult[1],1'b0,1'b0,1'b0, subResult[1], 1'b0, ALUctl, ALUOut[1]);
    myMux8 mux2(andResult[2],orResult[2],addResult[2],1'b0,1'b0,1'b0, subResult[2], 1'b0, ALUctl, ALUOut[2]);
    myMux8 mux3(andResult[3],orResult[3],addResult[3],1'b0,1'b0,1'b0, subResult[3], 1'b0, ALUctl, ALUOut[3]);
    
    //Zero
    nor(Zero,ALUOut[0],ALUOut[1],ALUOut[2],ALUOut[3]);
    
    
    
    
    //overflow
    // Inverted signals for A[3], B[3], and addResult[3]
    wire A3_not, B3_not, addResult3_not;
    not(A3_not, A[3]);
    not(B3_not, B[3]);
    not(addResult3_not, addResult[3]);
    //add detection
    wire addSignMatch, addSignDiff, addOverflowPos, addOverflowNeg;
    and(addSignMatch, A3_not, B3_not);                // A[3] = 0, B[3] = 0
    and(addSignDiff, A[3], B[3]);                     // A[3] = 1, B[3] = 1
    and(addOverflowPos, addSignMatch, addResult[3]);  // Overflow for positive numbers
    and(addOverflowNeg, addSignDiff, addResult3_not); // Overflow for negative numbers
    or (addOverflow, addOverflowPos, addOverflowNeg); // Combined addition overflow
    //sub detection
    wire subSignDiff, subSignChange;
    xor(subSignDiff, A[3], B[3]);                   // A[3] != B[3]
    xor(subSignChange, A[3], subResult[3]);         // A[3] != subResult[3]
    and(subOverflow, subSignDiff, subSignChange);   // Subtraction overflow
    //
    wire isAdd, isSub;
    
    wire not0, not1, not2;
    not(not0, ALUctl[0]);
    not(not1, ALUctl[1]);
    not(not2, ALUctl[2]);
    //check if the current is the one being tested
    and(isAdd, not2, ALUctl[1], not0); // add 010 
    and(isSub, ALUctl[2], ALUctl[1], not0);    // sub 110 


    // Combine overflow signals based on ALUctl
    wire addOverflowActive, subOverflowActive;
    and(addOverflowActive, isAdd, addOverflow); // add 010
    and(subOverflowActive, isSub, subOverflow); // sub 110
    or (OverFlow, addOverflowActive, subOverflowActive); // Combine active overflow signals

    
endmodule




module fourBitGreaterTest (A, B, BGreater); // tests if B is greater than A (4bit)
    input [3:0] A, B;
    output BGreater;
    wire E3, E2, E1, G3, G2, G1, G0, WC2, WC1, WC0, trash; // E# - Equal in test, G# - Greater in test, WC# - wire for carrying to final or gate

    oneCompar Compar3(B[3], A[3], trash, E3, G3);
    oneCompar Compar2(B[2], A[2], trash, E2, G2);
    oneCompar Compar1(B[1], A[1], trash, E1, G1);
    oneCompar Compar0(B[0], A[0], trash, E0, G0);
    
    // Carry results forward for final OR gate logic
    and(WC2, E3, G2);
    and(WC1, E3, E2, G1);
    and(WC0, E3, E2, E1, G0);
    
    // OR gate to output if B is greater than A
    or(BGreater, G3, WC2, WC1, WC0);
    
endmodule


module oneCompar(A, B, BGreat, Equal, AGreat);
    input A, B; 
    output BGreat, Equal, AGreat; // Output
    wire notA, notB, wBGreat, wAGreat; // intermediate outputs for computing

    not(notA, A); // NOT of A
    not(notB, B); // NOT of B
    and(wBGreat, notA, B); // B is greater than A
    and(wAGreat, notB, A); // A is greater than B

    // Outputs
    and(AGreat, notB, A); // A is greater than B
    and(BGreat, notA, B); // B is greater than A
    nor(Equal, wAGreat, wBGreat); // Equal if neither is greater
endmodule


// Half adder
module halfadder (S,C,x,y);
   input x,y;
   output S,C;

   xor (S,x,y);
   and (C,x,y);
endmodule




// Full adder
module fulladder (S,C,x,y,z);
   input x,y,z;
   output S,C;
   wire S1,D1,D2; //Outputs of first XOR and two AND gates
//Instantiate the halfadder
    halfadder HA1 (S1,D1,x,y),
              HA2 (S,D2,S1,z);
    or g1(C,D2,D1);
endmodule





// 4-bit adder - supplied by Dr. Zdravko Markov https://www.cs.ccsu.edu/~markov/ccsu_courses/354Syllabus.html#Basics_of_HDL
module _4bit_adder (S,C4,A,B,C0);
   input [3:0] A,B;
   input C0;
   output [3:0] S;
   output C4;
   wire C1,C2,C3;  //Intermediate carries
//Instantiate the fulladder
   fulladder  FA0 (S[0],C1,A[0],B[0],C0),
              FA1 (S[1],C2,A[1],B[1],C1),
              FA2 (S[2],C3,A[2],B[2],C2),
              FA3 (S[3],C4,A[3],B[3],C3);
endmodule

module comp (X, Y);//gets the 4 bit 2s compliment
    input [3:0] X;
    output [3:0] Y;

    // Invert the bits of X to get the 1's complement
    not n1 (X0, X[0]), n2 (X1, X[1]), n3 (X2, X[2]), n4 (X3, X[3]);


    halfadder h1 (Y[0], c1, X0, 1'b1),   // Add 1 to the 1's complement to get 2's complement
              h2 (Y[1], c2, X1, c1),
              h3 (Y[2], c3, X2, c2),
              h4 (Y[3], c4, X3, c3); 
endmodule


// 8-input, 3-selector multiplexer module - supplied by Dr. Zdravko Markov https://www.cs.ccsu.edu/~markov/ccsu_courses/354Syllabus.html#Basics_of_HDL
module myMux8(in0, in1, in2, in3, in4, in5, in6, in7, sel, out);
    input in0, in1, in2, in3, in4, in5, in6, in7; 
    input [2:0] sel;
    output out;
    wire mux0_out, mux1_out, mux2_out, mux3_out;  // Intermediate wires 
    
    // first Row
    myMux mux0(in0, in1, sel[0], mux0_out);
    myMux mux1(in2, in3, sel[0], mux1_out);
    myMux mux2(in4, in5, sel[0], mux2_out);
    myMux mux3(in6, in7, sel[0], mux3_out);
    
    // seccond Row
    wire mux4_out, mux5_out;
    myMux mux4(mux0_out, mux1_out, sel[1], mux4_out);
    myMux mux5(mux2_out, mux3_out, sel[1], mux5_out);
    
    // Last MUX
    myMux mux6(mux4_out, mux5_out, sel[2], out);
endmodule




//basic mux 2 input 1 selector
module myMux(X,Y,Z,out);
    input X,Y,Z;
    output out;
    wire notZ,A,B;
    not inverter(notZ,Z);

    and(A,X,notZ);
    and(B,Y,Z);
    or(out,A,B);
endmodule






// Test Module 
module testALU;
  reg signed [3:0] a;
  reg signed [3:0] b;
  reg [2:0] op;
  wire signed [3:0] result;
  wire zero,overflow;
  ALU alu (op,a,b,result,zero,overflow);
  initial
    begin
     $display("op  | a        | b        |result    |zero| overflow");
     $monitor ("%b | %b(%d) | %b(%d) | %b(%d) | %b  |  %b",op,a,a,b,b,result,result,zero,overflow);
	       op = 3'b000; a = 4'b0111; b = 4'b0010;  // AND
            #1 op = 3'b001; a = 4'b0101; b = 4'b0010;  // OR
            #1 op = 3'b010; a = 4'b0101; b = 4'b0001;  // ADD
	    #1 op = 3'b010; a = 4'b0111; b = 4'b0001;  // ADD overflow (8+1=-8)
	    #1 op = 3'b110; a = 4'b0101; b = 4'b0001;  // SUB
	    #1 op = 3'b110; a = 4'b1111; b = 4'b0001;  // SUB
	    #1 op = 3'b110; a = 4'b1111; b = 4'b1000;  // SUB no overflow (-1-(-8)=7)
	    #1 op = 3'b110; a = 4'b1110; b = 4'b0111;  // SUB overflow (-2-7=7)
	    #1 op = 3'b111; a = 4'b0101; b = 4'b0001;  // SLT
	    #1 op = 3'b111; a = 4'b0001; b = 4'b0011;  // SLT
	    #1 op = 3'b111; a = 4'b1101; b = 4'b0110;  // SLT overflow (-3-6=7 => SLT=0)
    end
endmodule

/* Test Results from Gate-level Implementation
op  a        b        result   zero overflow
000 0111( 7) 0010( 2) 0010( 2) 0    0
001 0101( 5) 0010( 2) 0111( 7) 0    0
010 0101( 5) 0001( 1) 0110( 6) 0    0
010 0111( 7) 0001( 1) 1000(-8) 0    1
110 0101( 5) 0001( 1) 0100( 4) 0    0
110 1111(-1) 0001( 1) 1110(-2) 0    0
110 1111(-1) 1000(-8) 0111( 7) 0    0
110 1110(-2) 0111( 7) 0111( 7) 0    1
111 0101( 5) 0001( 1) 0000( 0) 1    0
111 0001( 1) 0011( 3) 0001( 1) 0    0
111 1101(-3) 0110( 6) 0000( 0) 1    1
*/

