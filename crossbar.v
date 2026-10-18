/*
 * crossbar.v
 *
 * Registered five-port switch: North, South, East, West and Local.
 * Supports ONE selected input-to-output connection per clock cycle.
 * All 25 input/output combinations are supported, including same-port paths.
 *
 * DATA:
 *   Each data port carries one FLIT_W-bit flit.
 *   Flits are copied unchanged; their contents are not interpreted here.
 *
 * CONTROL:
 *   input_control  selects the source input using a one-hot mask.
 *   output_control selects the destination output using a one-hot mask.
 *   Bit PORT_N represents North, PORT_S represents South, and so on.
 *   PORT_* parameters must be unique indices within 0..4.
 *
 * CLOCK AND RESET:
 *   Outputs update on the rising edge of clk.
 *   rst is synchronous, active-high, and takes priority over enable.
 *   Reset clears all output registers and rdy. Apply reset before use.
 *
 * TRANSFER BEHAVIOUR:
 *   With enable=1 and valid one-hot controls, the selected output captures
 *   the selected input flit and rdy becomes 1.
 *   Unselected outputs retain their previous values.
 *   With enable=0, zero controls, or multi-hot controls, all outputs retain
 *   their values and rdy becomes 0.
 *   Back-to-back transfers are supported; rdy may remain high across them.
 *
 * INTEGRATION CAVEATS:
 *   rdy is a registered transfer indicator, NOT a receiver-ready signal.
 *   The surrounding logic must assert enable only when the input flit is
 *   valid and the downstream path can accept the registered transfer.
 *   There is no arbitration, route computation, credit tracking or FIFO
 *   inside this module. Output data can be overwritten by a later transfer.
 *   Retained output data must not be interpreted as a new packet.
 *   Consumers must track the selected destination, aligned with the
 *   registered output data and rdy; rdy alone does not identify that port.
 *
 * LIMITATION:
 *   This interface selects one input/output pair globally. It does not
 *   support multiple simultaneous connections like a parallel 5x5 crossbar.
 */



module crossbar #(
    parameter integer FLIT_W = 32,

    parameter [2:0] PORT_N = 3'd1,
    parameter [2:0] PORT_S = 3'd2,
    parameter [2:0] PORT_E = 3'd3,
    parameter [2:0] PORT_W = 3'd4,
    parameter [2:0] PORT_L = 3'd0
)(
    input wire clk,
    input wire rst,
    input wire enable,

    input wire [FLIT_W-1:0] IN_DATA_N,
    input wire [FLIT_W-1:0] IN_DATA_S,
    input wire [FLIT_W-1:0] IN_DATA_E,
    input wire [FLIT_W-1:0] IN_DATA_W,
    input wire [FLIT_W-1:0] IN_DATA_L,

    input wire [2:0] input_control,
    input wire [2:0] output_control,

    output reg [FLIT_W-1:0] OUT_DATA_N,
    output reg [FLIT_W-1:0] OUT_DATA_S,
    output reg [FLIT_W-1:0] OUT_DATA_E,
    output reg [FLIT_W-1:0] OUT_DATA_W,
    output reg [FLIT_W-1:0] OUT_DATA_L,

    output reg rdy
);


localparam [2:0] in_n = PORT_N;
localparam [2:0] in_s = PORT_S;
localparam [2:0] in_e = PORT_E;
localparam [2:0] in_w = PORT_W;
localparam [2:0] in_l = PORT_L;

localparam [2:0] out_n = PORT_N;
localparam [2:0] out_s = PORT_S;
localparam [2:0] out_e = PORT_E;
localparam [2:0] out_w = PORT_W;
localparam [2:0] out_l = PORT_L;

always @(posedge clk) begin
    if (rst) begin
        rdy <= 1'b0;
        OUT_DATA_E <= 0;
        OUT_DATA_N <= 0;
        OUT_DATA_S <= 0;
        OUT_DATA_W <= 0;
        OUT_DATA_L <= 0;
    end else if (enable) begin
        rdy <= 1'b0;

        if ((output_control == out_n) &&
            (input_control == in_e)) begin
            OUT_DATA_N <= IN_DATA_E;
            rdy <= 1'b1;
        end

        if ((output_control == out_n) &&
            (input_control == in_n)) begin
            OUT_DATA_N <= IN_DATA_N;
            rdy <= 1'b1;
        end

        if ((output_control == out_n) &&
            (input_control == in_s)) begin
            OUT_DATA_N <= IN_DATA_S;
            rdy <= 1'b1;
        end

        if ((output_control == out_n) &&
            (input_control == in_w)) begin
            OUT_DATA_N <= IN_DATA_W;
            rdy <= 1'b1;
        end

        if ((output_control == out_n) &&
            (input_control == in_l)) begin
            OUT_DATA_N <= IN_DATA_L;
            rdy <= 1'b1;
        end

        if ((output_control == out_s) &&
            (input_control == in_n)) begin
            OUT_DATA_S <= IN_DATA_N;
            rdy <= 1'b1;
        end

        if ((output_control == out_s) &&
            (input_control == in_s)) begin
            OUT_DATA_S <= IN_DATA_S;
            rdy <= 1'b1;
        end

        if ((output_control == out_s) &&
            (input_control == in_e)) begin
            OUT_DATA_S <= IN_DATA_E;
            rdy <= 1'b1;
        end

        if ((output_control == out_s) &&
            (input_control == in_w)) begin
            OUT_DATA_S <= IN_DATA_W;
            rdy <= 1'b1;
        end

        if ((output_control == out_s) &&
            (input_control == in_l)) begin
            OUT_DATA_S <= IN_DATA_L;
            rdy <= 1'b1;
        end

        if ((output_control == out_e) &&
            (input_control == in_n)) begin
            OUT_DATA_E <= IN_DATA_N;
            rdy <= 1'b1;
        end

        if ((output_control == out_e) &&
            (input_control == in_s)) begin
            OUT_DATA_E <= IN_DATA_S;
            rdy <= 1'b1;
        end

        if ((output_control == out_e) &&
            (input_control == in_e)) begin
            OUT_DATA_E <= IN_DATA_E;
            rdy <= 1'b1;
        end

        if ((output_control == out_e) &&
            (input_control == in_w)) begin
            OUT_DATA_E <= IN_DATA_W;
            rdy <= 1'b1;
        end

        if ((output_control == out_e) &&
            (input_control == in_l)) begin
            OUT_DATA_E <= IN_DATA_L;
            rdy <= 1'b1;
        end

        if ((output_control == out_w) &&
            (input_control == in_n)) begin
            OUT_DATA_W <= IN_DATA_N;
            rdy <= 1'b1;
        end

        if ((output_control == out_w) &&
            (input_control == in_s)) begin
            OUT_DATA_W <= IN_DATA_S;
            rdy <= 1'b1;
        end

        if ((output_control == out_w) &&
            (input_control == in_e)) begin
            OUT_DATA_W <= IN_DATA_E;
            rdy <= 1'b1;
        end

        if ((output_control == out_w) &&
            (input_control == in_w)) begin
            OUT_DATA_W <= IN_DATA_W;
            rdy <= 1'b1;
        end

        if ((output_control == out_w) &&
            (input_control == in_l)) begin
            OUT_DATA_W <= IN_DATA_L;
            rdy <= 1'b1;
        end

        if ((output_control == out_l) &&
            (input_control == in_n)) begin
            OUT_DATA_L <= IN_DATA_N;
            rdy <= 1'b1;
        end

        if ((output_control == out_l) &&
            (input_control == in_s)) begin
            OUT_DATA_L <= IN_DATA_S;
            rdy <= 1'b1;
        end

        if ((output_control == out_l) &&
            (input_control == in_e)) begin
            OUT_DATA_L <= IN_DATA_E;
            rdy <= 1'b1;
        end

        if ((output_control == out_l) &&
            (input_control == in_w)) begin
            OUT_DATA_L <= IN_DATA_W;
            rdy <= 1'b1;
        end

        if ((output_control == out_l) &&
            (input_control == in_l)) begin
            OUT_DATA_L <= IN_DATA_L;
            rdy <= 1'b1;
        end

    end else begin
        rdy <= 1'b0;
    end
end

endmodule