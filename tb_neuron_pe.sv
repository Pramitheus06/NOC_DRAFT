`timescale 1ns / 1ps

// Self-checking SystemVerilog TB. The DUT remains plain Verilog.
// Three FLIT_W values catch hard-coded header indices, including FLIT_W=2.
module neuron_pe_checker #(
    parameter integer FLIT_W = 34
)(
    input wire clk,
    output reg done
);
    reg rst;
    reg valid;
    reg [FLIT_W-1:0] IN_FLIT;
    wire spike;

    neuron_pe #(.FLIT_W(FLIT_W)) dut (
        .clk(clk), .IN_FLIT(IN_FLIT), .valid(valid), .rst(rst), .spike(spike)
    );

    integer model_voltage;
    integer idle_clocks;
    reg model_spike;
    integer checked_cycles;
    integer output_spikes;
    integer transition_count;
    reg transition_seen [0:1919];
    reg [31:0] random_state;
    integer run_seed;
    integer ignored_plusarg;
    integer i, v, timer_value, reset_value, valid_value, tag_value;

    function automatic [31:0] xorshift32(input [31:0] value);
        reg [31:0] x;
        begin
            x = value;
            x = x ^ (x << 13);
            x = x ^ (x >> 17);
            x = x ^ (x << 5);
            xorshift32 = x;
        end
    endfunction

    // Inputs change at falling edges; outputs are sampled after NBA updates.
    // The reference uses integer voltage and elapsed idle clocks, not DUT RTL.
    task automatic step(
        input reg reset_in,
        input reg valid_in,
        input reg [1:0] tag,
        input reg [FLIT_W-1:0] payload,
        input string context_name
    );
        integer index;
        reg [4:0] previous_voltage;
        reg [3:0] previous_timer;
        reg previous_spike;
        begin
            @(negedge clk);
            previous_voltage = dut.membrane_acc;
            previous_timer = dut.prescaler;
            previous_spike = spike;
            rst = reset_in;
            valid = valid_in;
            IN_FLIT = payload;
            IN_FLIT[FLIT_W-1 -: 2] = tag;

            // No state/output change is permitted before the next rising edge,
            // including when synchronous reset is asserted between edges.
            #1;
            if (checked_cycles != 0 &&
                ((dut.membrane_acc !== previous_voltage) ||
                 (dut.prescaler !== previous_timer) ||
                 (spike !== previous_spike)))
                $fatal(1, "FLIT_W=%0d %s: state changed off the rising edge",
                       FLIT_W, context_name);

            index = ((((model_voltage * 8 + idle_clocks) * 2
                       + reset_in) * 2 + valid_in) * 4 + tag);
            if (!transition_seen[index]) begin
                transition_seen[index] = 1'b1;
                transition_count = transition_count + 1;
            end

            model_spike = 1'b0;
            if (reset_in) begin
                model_voltage = 0;
                idle_clocks = 0;
            end else begin
                idle_clocks = idle_clocks + 1;
                if (valid_in && tag == 2'b11) begin
                    model_voltage = model_voltage + 5;
                    idle_clocks = 0;
                    if (model_voltage >= 15) begin
                        model_spike = 1'b1;
                        model_voltage = 0;
                    end
                end else if (idle_clocks == 8) begin
                    idle_clocks = 0;
                    if (model_voltage > 0)
                        model_voltage = model_voltage - 1;
                end
            end

            @(posedge clk);
            #1;
            checked_cycles = checked_cycles + 1;
            if ((spike !== model_spike) ||
                (dut.membrane_acc !== model_voltage[4:0]) ||
                (dut.prescaler !== idle_clocks[3:0]))
                $fatal(1,
                    "FLIT_W=%0d cycle=%0d %s rst=%b valid=%b tag=%b: got V=%0d timer=%0d spike=%b; expected V=%0d timer=%0d spike=%b",
                    FLIT_W, checked_cycles, context_name, reset_in, valid_in,
                    tag, dut.membrane_acc, dut.prescaler, spike,
                    model_voltage, idle_clocks, model_spike);

            if (spike)
                output_spikes = output_spikes + 1;
            if (dut.membrane_acc >= 15 || dut.prescaler > 7)
                $fatal(1, "FLIT_W=%0d: state invariant failed", FLIT_W);
        end
    endtask

    task automatic idle(input integer count);
        integer n;
        begin
            for (n = 0; n < count; n = n + 1)
                step(0, 0, 2'b00, '0, "idle/leak");
        end
    endtask

    task automatic event_in;
        begin
            random_state = xorshift32(random_state);
            step(0, 1, 2'b11, {random_state, random_state}, "incoming spike");
        end
    endtask

    task automatic reset_neuron;
        begin
            step(1, 0, 2'b00, '0, "reset");
        end
    endtask

    // Reach all 120 legal states through normal inputs, without force/deposit.
    // 0 -> 5 -> 10 -> (eight idle clocks) 9 -> 14, then leak down as needed.
    task automatic reach_state(input integer voltage, input integer age);
        begin
            reset_neuron();
            event_in();
            event_in();
            idle(8);
            event_in();
            idle((14 - voltage) * 8 + age);
            if (model_voltage != voltage || idle_clocks != age)
                $fatal(1, "TB setup failed to reach V=%0d age=%0d", voltage, age);
        end
    endtask

    initial begin
        done = 0;
        rst = 1;
        valid = 0;
        IN_FLIT = '0;
        model_voltage = 0;
        idle_clocks = 0;
        model_spike = 0;
        checked_cycles = 0;
        output_spikes = 0;
        transition_count = 0;
        run_seed = 32'h31415926;
        ignored_plusarg = $value$plusargs("SEED=%d", run_seed);
        random_state = run_seed ^ (32'h9e3779b9 + FLIT_W);
        if (random_state == 0) random_state = 1;
        for (i = 0; i < 1920; i = i + 1)
            transition_seen[i] = 0;

        reset_neuron();
        idle(24); // Timer wraps at zero without membrane underflow.

        // Exact threshold on the third event; next event must still be accepted.
        event_in();
        event_in();
        event_in();
        event_in();
        idle(1); // Checks pulse clearing and membrane hold.

        // Non-spike tags and valid=0 must not integrate or restart the timer.
        for (tag_value = 0; tag_value < 3; tag_value = tag_value + 1)
            step(0, 1, tag_value[1:0], '1, "non-spike tag");
        step(0, 0, 2'b11, '1, "spike tag with valid low");

        // Input/leak collisions: zero membrane, subthreshold, firing, overshoot.
        reach_state(0, 7);
        event_in();
        reach_state(5, 7);
        event_in();
        reach_state(10, 7);
        event_in();
        reach_state(14, 7);
        event_in();

        // Frequent events postpone leakage; invalid traffic does not.
        reset_neuron();
        repeat (9) begin
            event_in();
            idle(7);
        end
        reach_state(1, 7);
        step(0, 1, 2'b01, '1, "last leak to zero");
        idle(16);

        // Reset overrides a would-be firing input; also clears a high pulse.
        reach_state(10, 7);
        step(1, 1, 2'b11, '1, "reset overrides input/leak/fire");
        event_in();
        event_in();
        event_in();
        step(1, 1, 2'b11, '0, "reset clears spike");

        // 120 states x reset(2) x valid(2) x tag(4) = 1,920 transitions.
        // A fresh natural setup precedes every probe, so the first probe cannot
        // disturb the precondition of the next probe.
        for (v = 0; v < 15; v = v + 1)
            for (timer_value = 0; timer_value < 8; timer_value = timer_value + 1)
                for (reset_value = 0; reset_value < 2; reset_value = reset_value + 1)
                    for (valid_value = 0; valid_value < 2; valid_value = valid_value + 1)
                        for (tag_value = 0; tag_value < 4; tag_value = tag_value + 1) begin
                            reach_state(v, timer_value);
                            random_state = xorshift32(random_state);
                            step(reset_value[0], valid_value[0], tag_value[1:0],
                                 {random_state, random_state}, "exhaustive probe");
                        end
        if (transition_count != 1920)
            $fatal(1, "FLIT_W=%0d: transition coverage %0d/1920",
                   FLIT_W, transition_count);

        // 20,000 deterministic random clocks: mixed tags, dense spikes,
        // sparse spikes, and continuously valid mixed traffic. Random resets
        // exercise recovery amid each profile. Change +SEED for another run.
        for (i = 0; i < 20000; i = i + 1) begin
            random_state = xorshift32(random_state);
            if (i < 5000)
                step(random_state[23:16] == 8'h5a, random_state[4],
                     random_state[1:0], {random_state, random_state}, "random mixed");
            else if (i < 10000)
                step(random_state[23:16] == 8'h5a,
                     random_state[4] | random_state[5], 2'b11,
                     {random_state, random_state}, "random dense spikes");
            else if (i < 15000)
                step(random_state[23:16] == 8'h5a, random_state[7:4] == 0,
                     2'b11, {random_state, random_state}, "random sparse spikes");
            else
                step(random_state[23:16] == 8'h5a, 1'b1,
                     random_state[1:0], {random_state, random_state}, "random valid traffic");
        end

        reset_neuron();
        idle(16);
        $display("PASS FLIT_W=%0d: %0d checked cycles, %0d output spikes, %0d/1920 transitions, 20000 randomized cycles",
                 FLIT_W, checked_cycles, output_spikes, transition_count);
        done = 1;
    end
endmodule

module tb_neuron_pe;
    reg clk = 0;
    wire done34, done18, done2;
    always #5 clk = ~clk;

    neuron_pe_checker #(.FLIT_W(34)) check34(.clk(clk), .done(done34));
    neuron_pe_checker #(.FLIT_W(18)) check18(.clk(clk), .done(done18));
    neuron_pe_checker #(.FLIT_W(2))  check2 (.clk(clk), .done(done2));

    initial begin
        if ($test$plusargs("WAVES")) begin
            $dumpfile("neuron_pe.vcd");
            $dumpvars(0, tb_neuron_pe);
        end
        wait(done34 && done18 && done2);
        $display("ALL TESTS PASSED");
        $finish;
    end

    initial begin
        #5000000;
        $fatal(1, "TIMEOUT: testbench did not finish");
    end
endmodule
