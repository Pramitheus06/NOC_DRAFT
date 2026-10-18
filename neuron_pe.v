module neuron_pe#(
    parameter integer FLIT_W = 34)(
    input clk,
         input wire [FLIT_W-1:0] IN_FLIT,
         input wire valid,
         input wire  rst,

         output reg spike
 
);

localparam threshold = 4'd15 ;
localparam weight = 4'd5 ;
wire incoming_spike = valid && (IN_FLIT[FLIT_W-1 -: 2] == 2'b11);
reg [4:0] membrane_acc;
reg [3:0] prescaler;
wire [5:0] membrane_plus_weight =  membrane_acc +  weight;

always @(posedge clk) begin
        spike <= 1'b0;

        if (rst) begin
            membrane_acc <= 5'd0;
            prescaler    <= 4'd0;
        end else if (incoming_spike) begin
            
            prescaler <= 4'd0;
            if (membrane_plus_weight >=  threshold) begin
               
                spike        <= 1'b1;
                membrane_acc <= 5'd0;
            end else begin
                membrane_acc <= membrane_plus_weight[4:0];
            end
        end else if (prescaler == 4'd7) begin
           
            prescaler <= 4'd0;
            if (membrane_acc != 5'd0)
                membrane_acc <= membrane_acc - 5'd1;
        end else begin
            prescaler <= prescaler + 4'd1;
        end
    end

endmodule