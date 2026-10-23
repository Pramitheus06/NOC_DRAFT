`timescale 1ns/1ps

module tb_crossbar;
    parameter integer FLIT_W = 34;
    parameter [2:0] PORT_N = 3'd0, PORT_S = 3'd1,
                    PORT_E = 3'd2, PORT_W = 3'd3, PORT_L = 3'd4;

    reg clk = 0;
    reg rst = 1;
    reg enable = 0;
    reg [4:0] input_control = 0, output_control = 0;
    reg [FLIT_W-1:0] IN_DATA_N = 0, IN_DATA_S = 0,
                     IN_DATA_E = 0, IN_DATA_W = 0, IN_DATA_L = 0;
    wire [FLIT_W-1:0] OUT_DATA_N, OUT_DATA_S, OUT_DATA_E,
                      OUT_DATA_W, OUT_DATA_L;
    wire rdy;

    crossbar #(
        .FLIT_W(FLIT_W), .PORT_N(PORT_N), .PORT_S(PORT_S),
        .PORT_E(PORT_E), .PORT_W(PORT_W), .PORT_L(PORT_L)
    ) dut (
        .clk(clk), .rst(rst), .enable(enable),
        .IN_DATA_N(IN_DATA_N), .IN_DATA_S(IN_DATA_S),
        .IN_DATA_E(IN_DATA_E), .IN_DATA_W(IN_DATA_W),
        .IN_DATA_L(IN_DATA_L),
        .input_control(input_control), .output_control(output_control),
        .OUT_DATA_N(OUT_DATA_N), .OUT_DATA_S(OUT_DATA_S),
        .OUT_DATA_E(OUT_DATA_E), .OUT_DATA_W(OUT_DATA_W),
        .OUT_DATA_L(OUT_DATA_L), .rdy(rdy)
    );

    always #5 clk = ~clk;

    // Array positions below always mean N, S, E, W, L.
    reg [FLIT_W-1:0] expected [0:4];
    reg expected_rdy;
    integer cycles = 0;
    integer seed = 32'h13579BDF;
    integer i, j, k;
    reg [4:0] random_in, random_out;

    function automatic [4:0] port_mask(input integer port_index);
        case (port_index)
            0: port_mask = 5'b00001 << PORT_N;
            1: port_mask = 5'b00001 << PORT_S;
            2: port_mask = 5'b00001 << PORT_E;
            3: port_mask = 5'b00001 << PORT_W;
            4: port_mask = 5'b00001 << PORT_L;
            default: port_mask = 0;
        endcase
    endfunction

    function automatic [FLIT_W-1:0] input_word(input integer p);
        case (p)
            0: input_word = IN_DATA_N;
            1: input_word = IN_DATA_S;
            2: input_word = IN_DATA_E;
            3: input_word = IN_DATA_W;
            4: input_word = IN_DATA_L;
            default: input_word = 0;
        endcase
    endfunction

    function automatic [FLIT_W-1:0] output_word(input integer p);
        case (p)
            0: output_word = OUT_DATA_N;
            1: output_word = OUT_DATA_S;
            2: output_word = OUT_DATA_E;
            3: output_word = OUT_DATA_W;
            4: output_word = OUT_DATA_L;
            default: output_word = 0;
        endcase
    endfunction

    // Randomize every bit, including widths greater than 32 bits.
    function automatic [FLIT_W-1:0] random_flit();
        integer b;
        for (b = 0; b < FLIT_W; b = b + 1)
            random_flit[b] = $urandom_range(0, 1);
    endfunction

    task automatic check_outputs(input string phase);
        integer p;
        begin
            for (p = 0; p < 5; p = p + 1) begin
                if (output_word(p) !== expected[p])
                    $fatal(1,
                        "FAIL cycle=%0d phase=%s port=%0d expected=%h got=%h",
                        cycles, phase, p, expected[p], output_word(p));
            end
            if (rdy !== expected_rdy)
                $fatal(1,
                    "FAIL cycle=%0d phase=%s rdy expected=%b got=%b",
                    cycles, phase, expected_rdy, rdy);
        end
    endtask

    task automatic step(
        input bit next_rst,
        input bit next_enable,
        input [4:0] next_input_control,
        input [4:0] next_output_control
    );
        integer src, dst, p;
        begin
            // Drive away from the DUT's sampling edge to avoid races.
            @(negedge clk);
            rst = next_rst;
            enable = next_enable;
            input_control = next_input_control;
            output_control = next_output_control;
            IN_DATA_N = random_flit();
            IN_DATA_S = random_flit();
            IN_DATA_E = random_flit();
            IN_DATA_W = random_flit();
            IN_DATA_L = random_flit();

            // A registered DUT must not respond before the rising edge.
            #1;
            check_outputs("before rising edge");

            @(posedge clk);
            cycles = cycles + 1;
            expected_rdy = 0;
            if (rst) begin
                for (p = 0; p < 5; p = p + 1)
                    expected[p] = 0;
            end else if (enable) begin
                src = -1;
                dst = -1;
                for (p = 0; p < 5; p = p + 1) begin
                    if (input_control === port_mask(p)) src = p;
                    if (output_control === port_mask(p)) dst = p;
                end
                if ((src >= 0) && (dst >= 0)) begin
                    expected[dst] = input_word(src);
                    expected_rdy = 1;
                end
            end

            // Wait for nonblocking assignments to update the DUT outputs.
            #1;
            check_outputs("after rising edge");
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_crossbar);

        seed = $urandom(seed);
        expected_rdy = 0;
        for (k = 0; k < 5; k = k + 1)
            expected[k] = 0;

        step(1, 0, 0, 0);

        $display("Checking all 25 paths without idle cycles...");
        for (i = 0; i < 5; i = i + 1)
            for (j = 0; j < 5; j = j + 1)
                step(0, 1, port_mask(i), port_mask(j));

        $display("Checking enable=0 and output retention...");
        for (i = 0; i < 5; i = i + 1)
            step(0, 0, port_mask(i), port_mask(4-i));

        $display("Checking reset priority while enable=1...");
        step(0, 1, port_mask(2), port_mask(1));
        step(1, 1, port_mask(4), port_mask(0));

        $display("Checking all 1024 control combinations...");
        for (i = 0; i < 32; i = i + 1)
            for (j = 0; j < 32; j = j + 1)
                step(0, 1, i[4:0], j[4:0]);

        // Unknown controls must not accidentally produce a transfer.
        step(0, 1, 5'bxxxxx, port_mask(0));
        step(0, 1, port_mask(0), 5'bzzzzz);

        $display("Checking 250 randomized cycles...");
        for (k = 0; k < 250; k = k + 1) begin
            if ($urandom_range(0, 3) != 0) begin
                random_in = port_mask($urandom_range(0, 4));
                random_out = port_mask($urandom_range(0, 4));
            end else begin
                random_in = $urandom_range(0, 31);
                random_out = $urandom_range(0, 31);
            end
            step(($urandom_range(0, 31) == 0),
                 $urandom_range(0, 1), random_in, random_out);
        end

        $display("PASS: %0d checked cycles; all 25 paths, reset, enable, invalid controls and output retention.", cycles);
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "FAIL: simulation timeout");
    end
endmodule
