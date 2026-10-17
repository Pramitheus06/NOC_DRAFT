module crossbar #(
    parameter integer FLIT_W = 32,

    parameter [2:0] PORT_N = 3'd0,
    parameter [2:0] PORT_S = 3'd1,
    parameter [2:0] PORT_E = 3'd2,
    parameter [2:0] PORT_W = 3'd3,
    parameter [2:0] PORT_L = 3'd4
)(
    input wire clk,
    input wire rst,
    input wire enable,

    input wire [FLIT_W-1:0] IN_DATA_N,
    input wire [FLIT_W-1:0] IN_DATA_S,
    input wire [FLIT_W-1:0] IN_DATA_E,
    input wire [FLIT_W-1:0] IN_DATA_W,
    input wire [FLIT_W-1:0] IN_DATA_L,

    input wire [4:0] input_control,
    input wire [4:0] output_control,

    output reg [FLIT_W-1:0] OUT_DATA_N,
    output reg [FLIT_W-1:0] OUT_DATA_S,
    output reg [FLIT_W-1:0] OUT_DATA_E,
    output reg [FLIT_W-1:0] OUT_DATA_W,
    output reg [FLIT_W-1:0] OUT_DATA_L,

    output reg rdy
);
localparam [4:0] in_n = 5'b00001 << PORT_N;
localparam [4:0] in_s = 5'b00001 << PORT_S;
localparam [4:0] in_e = 5'b00001 << PORT_E;
localparam [4:0] in_w = 5'b00001 << PORT_W;
localparam [4:0] in_l = 5'b00001 << PORT_L;

localparam [4:0] out_n = 5'b00001 << PORT_N;
localparam [4:0] out_s = 5'b00001 << PORT_S;
localparam [4:0] out_e = 5'b00001 << PORT_E;
localparam [4:0] out_w = 5'b00001 << PORT_W;
localparam [4:0] out_l = 5'b00001 << PORT_L;



always @(posedge clk) begin
    if (rst) begin
        rdy <= 0;
        OUT_DATA_E <= 0;
        OUT_DATA_N <= 0;
        OUT_DATA_S <= 0;
        OUT_DATA_W <= 0;
        OUT_DATA_L <= 0;
    end
    else if (enable) begin
        rdy <= 0;

        if ((output_control == out_n) &&
            (input_control == in_e)) begin
            OUT_DATA_N <= IN_DATA_E;
            rdy <= 1;
        end

        if ((output_control == out_n) &&
            (input_control == in_n)) begin
            OUT_DATA_N <= IN_DATA_N;
            rdy <= 1;
        end

        if ((output_control == out_n) &&
            (input_control == in_s)) begin
            OUT_DATA_N <= IN_DATA_S;
            rdy <= 1;
        end

        if ((output_control == out_n) &&
            (input_control == in_w)) begin
            OUT_DATA_N <= IN_DATA_W;
            rdy <= 1;
        end

        if ((output_control == out_n) &&
            (input_control == in_l)) begin
            OUT_DATA_N <= IN_DATA_L;
            rdy <= 1;
        end

        if ((output_control == out_s) &&
            (input_control == in_n)) begin
            OUT_DATA_S <= IN_DATA_N;
            rdy <= 1;
        end

        if ((output_control == out_s) &&
            (input_control == in_s)) begin
            OUT_DATA_S <= IN_DATA_S;
            rdy <= 1;
        end

        if ((output_control == out_s) &&
            (input_control == in_e)) begin
            OUT_DATA_S <= IN_DATA_E;
            rdy <= 1;
        end

        if ((output_control == out_s) &&
            (input_control == in_w)) begin
            OUT_DATA_S <= IN_DATA_W;
            rdy <= 1;
        end

        if ((output_control == out_s) &&
            (input_control == in_l)) begin
            OUT_DATA_S <= IN_DATA_L;
            rdy <= 1;
        end

        if ((output_control == out_e) &&
            (input_control == in_n)) begin
            OUT_DATA_E <= IN_DATA_N;
            rdy <= 1;
        end

        if ((output_control == out_e) &&
            (input_control == in_s)) begin
            OUT_DATA_E <= IN_DATA_S;
            rdy <= 1;
        end

        if ((output_control == out_e) &&
            (input_control == in_e)) begin
            OUT_DATA_E <= IN_DATA_E;
            rdy <= 1;
        end

        if ((output_control == out_e) &&
            (input_control == in_w)) begin
            OUT_DATA_E <= IN_DATA_W;
            rdy <= 1;
        end

        if ((output_control == out_e) &&
            (input_control == in_l)) begin
            OUT_DATA_E <= IN_DATA_L;
            rdy <= 1;
        end

        if ((output_control == out_w) &&
            (input_control == in_n)) begin
            OUT_DATA_W <= IN_DATA_N;
            rdy <= 1;
        end

        if ((output_control == out_w) &&
            (input_control == in_s)) begin
            OUT_DATA_W <= IN_DATA_S;
            rdy <= 1;
        end

        if ((output_control == out_w) &&
            (input_control == in_e)) begin
            OUT_DATA_W <= IN_DATA_E;
            rdy <= 1;
        end

        if ((output_control == out_w) &&
            (input_control == in_w)) begin
            OUT_DATA_W <= IN_DATA_W;
            rdy <= 1;
        end

        if ((output_control == out_w) &&
            (input_control == in_l)) begin
            OUT_DATA_W <= IN_DATA_L;
            rdy <= 1;
        end

        if ((output_control == out_l) &&
            (input_control == in_n)) begin
            OUT_DATA_L <= IN_DATA_N;
            rdy <= 1;
        end

        if ((output_control == out_l) &&
            (input_control == in_s)) begin
            OUT_DATA_L <= IN_DATA_S;
            rdy <= 1;
        end

        if ((output_control == out_l) &&
            (input_control == in_e)) begin
            OUT_DATA_L <= IN_DATA_E;
            rdy <= 1;
        end

        if ((output_control == out_l) &&
            (input_control == in_w)) begin
            OUT_DATA_L <= IN_DATA_W;
            rdy <= 1;
        end

        if ((output_control == out_l) &&
            (input_control == in_l)) begin
            OUT_DATA_L <= IN_DATA_L;
            rdy <= 1;
        end
    end
    else begin
        rdy <= 0;
    end
end

endmodule