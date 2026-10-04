`timescale 1ns/1ps

// ============================================================
// FIFO Transaction
// ============================================================
class fifo_transaction;

    rand bit       wr_en;
    rand bit       rd_en;
    rand bit [7:0] din;

    constraint c_valid_data {
        din inside {[0:255]};
    }

    // Allow all four operation combinations:
    // 00 = idle
    // 01 = read
    // 10 = write
    // 11 = simultaneous read/write

endclass


// ============================================================
// Testbench
// ============================================================
module fifo_tb;

    parameter DEPTH = 8;
    parameter WIDTH = 8;

    logic clk;
    logic rst;

    logic             wr_en;
    logic             rd_en;
    logic [WIDTH-1:0] din;
    logic [WIDTH-1:0] dout;

    logic full;
    logic empty;

    // --------------------------------------------------------
    // DUT
    // --------------------------------------------------------
    fifo_sync #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) dut (
        .clk   (clk),
        .rst   (rst),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .din   (din),
        .dout  (dout),
        .full  (full),
        .empty (empty)
    );


    // ========================================================
    // Functional Coverage
    // ========================================================
    covergroup fifo_coverage;

        cp_full: coverpoint full {
            bins not_full = {0};
            bins full_true = {1};
        }

        cp_empty: coverpoint empty {
            bins not_empty = {0};
            bins empty_true = {1};
        }

        cp_wr: coverpoint wr_en {
            bins no_write = {0};
            bins write    = {1};
        }

        cp_rd: coverpoint rd_en {
            bins no_read = {0};
            bins read    = {1};
        }

        cx_wr_full: cross cp_wr, cp_full;

        cx_rd_empty: cross cp_rd, cp_empty;

        cx_wr_rd: cross cp_wr, cp_rd;

    endgroup

    fifo_coverage cov;


    // ========================================================
    // Scoreboard
    // ========================================================
    logic [WIDTH-1:0] expected_queue[$];

    int pass_count = 0;
    int fail_count = 0;


    // ========================================================
    // Clock
    // ========================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // ========================================================
    // Reset
    // ========================================================
    task reset_fifo();

        rst   = 1;
        wr_en = 0;
        rd_en = 0;
        din   = 0;

        repeat (2) @(posedge clk);

        @(negedge clk);
        rst = 0;

        $display("\nRESET COMPLETE\n");

    endtask


    // ========================================================
    // WRITE TASK
    // ========================================================
    task write_fifo(input logic [WIDTH-1:0] data);

        @(negedge clk);

        wr_en = 1;
        rd_en = 0;
        din   = data;

        @(posedge clk);

        if (!full) begin
            expected_queue.push_back(data);

            $display("WRITE  : data = 0x%02h", data);
        end
        else begin
            $display("WRITE BLOCKED: FIFO FULL");
        end

        @(negedge clk);

        // Sample coverage after FIFO state has updated
        cov.sample();

        wr_en = 0;
        din   = 0;

    endtask


    // ========================================================
    // READ TASK
    // ========================================================
    task read_fifo();

        logic [WIDTH-1:0] expected_data;
        bit read_allowed;

        @(negedge clk);

        wr_en = 0;
        rd_en = 1;
        din   = 0;

        // Capture FIFO state before the clock edge
        read_allowed = !empty;

        if (read_allowed && expected_queue.size() > 0)
            expected_data = expected_queue.pop_front();
        else
            expected_data = 'x;

        @(posedge clk);

        @(negedge clk);

        // Coverage after state update
        cov.sample();

        if (read_allowed) begin

            if (dout === expected_data) begin
                pass_count++;

                $display(
                    "READ PASS: expected = 0x%02h, actual = 0x%02h",
                    expected_data,
                    dout
                );
            end
            else begin
                fail_count++;

                $display(
                    "READ FAIL: expected = 0x%02h, actual = 0x%02h",
                    expected_data,
                    dout
                );
            end

        end
        else begin
            $display("READ BLOCKED: FIFO EMPTY");
        end

        rd_en = 0;

    endtask


    // ========================================================
    // IDLE TASK
    // ========================================================
    task idle_cycle();

        @(negedge clk);

        wr_en = 0;
        rd_en = 0;
        din   = 0;

        @(posedge clk);

        @(negedge clk);

        cov.sample();

    endtask


    // ========================================================
    // SIMULTANEOUS READ + WRITE
    // ========================================================
    task simultaneous_read_write(
        input logic [WIDTH-1:0] data
    );

        logic [WIDTH-1:0] expected_data;
        bit write_allowed;
        bit read_allowed;

        @(negedge clk);

        wr_en = 1;
        rd_en = 1;
        din   = data;

        // ----------------------------------------------------
        // Capture state BEFORE the transaction
        // ----------------------------------------------------
        write_allowed = !full;
        read_allowed  = !empty;

        // ----------------------------------------------------
        // Reference model
        //
        // Read first
        // Write second
        //
        // If both are valid, queue size remains unchanged.
        // ----------------------------------------------------
        if (read_allowed && expected_queue.size() > 0)
            expected_data = expected_queue.pop_front();
        else
            expected_data = 'x;

        if (write_allowed)
            expected_queue.push_back(data);

        @(posedge clk);

        @(negedge clk);

        // ----------------------------------------------------
        // This is the important part:
        //
        // wr_en = 1
        // rd_en = 1
        //
        // Therefore cx_wr_rd gets WRITE × READ.
        // ----------------------------------------------------
        cov.sample();

        // ----------------------------------------------------
        // Check read result
        // ----------------------------------------------------
        if (read_allowed) begin

            if (dout === expected_data) begin
                pass_count++;

                $display(
                    "SIMULTANEOUS PASS: READ expected = 0x%02h, actual = 0x%02h | WRITE = 0x%02h",
                    expected_data,
                    dout,
                    data
                );
            end
            else begin
                fail_count++;

                $display(
                    "SIMULTANEOUS FAIL: READ expected = 0x%02h, actual = 0x%02h | WRITE = 0x%02h",
                    expected_data,
                    dout,
                    data
                );
            end

        end
        else begin

            $display(
                "SIMULTANEOUS: READ BLOCKED, WRITE = 0x%02h",
                data
            );

        end

        wr_en = 0;
        rd_en = 0;
        din   = 0;

    endtask


    // ========================================================
    // SVA ASSERTIONS
    // ========================================================

    // No write should occur when FIFO is full.
    property no_write_when_full;

        @(posedge clk)
        disable iff (rst)
        (wr_en && full) |=> (dut.wr_ptr == $past(dut.wr_ptr));

    endproperty

    assert_no_write_full:
        assert property(no_write_when_full)
        else $error("ASSERTION FAILED: Write occurred while FIFO was full");


    // No read should occur when FIFO is empty.
    property no_read_when_empty;

        @(posedge clk)
        disable iff (rst)
        (rd_en && empty) |=> (dut.rd_ptr == $past(dut.rd_ptr));

    endproperty

    assert_no_read_empty:
        assert property(no_read_when_empty)
        else $error("ASSERTION FAILED: Read occurred while FIFO was empty");


    // FIFO should never be simultaneously full and empty.
    property not_full_empty;

        @(posedge clk)
        disable iff (rst)
        !(full && empty);

    endproperty

    assert_not_full_empty:
        assert property(not_full_empty)
        else $error("ASSERTION FAILED: FIFO is both FULL and EMPTY");


    // ========================================================
    // MAIN TEST
    // ========================================================
    initial begin

        fifo_transaction tr;

        cov = new();

        reset_fifo();


        // ====================================================
        // DIRECTED WRITE TEST
        // Fill FIFO completely
        // ====================================================

        $display("\n========== FILL FIFO ==========");

        repeat (DEPTH) begin
            write_fifo($urandom_range(0,255));
        end


        // Verify FULL
        @(negedge clk);

        if (full == 1) begin
            pass_count++;
            $display("FULL FLAG PASS: FIFO is FULL");
        end
        else begin
            fail_count++;
            $display("FULL FLAG FAIL: FIFO should be FULL");
        end

        cov.sample();


        // ====================================================
        // WRITE WHILE FULL
        // ====================================================

        $display("\n========== WRITE WHILE FULL ==========");

        write_fifo(8'hAA);


        // ====================================================
        // READ ALL DATA
        // ====================================================

        $display("\n========== EMPTY FIFO ==========");

        repeat (DEPTH) begin
            read_fifo();
        end


        // Verify EMPTY
        @(negedge clk);

        if (empty == 1) begin
            pass_count++;
            $display("EMPTY FLAG PASS: FIFO is EMPTY");
        end
        else begin
            fail_count++;
            $display("EMPTY FLAG FAIL: FIFO should be EMPTY");
        end

        cov.sample();


        // ====================================================
        // READ WHILE EMPTY
        // ====================================================

        $display("\n========== READ WHILE EMPTY ==========");

        read_fifo();


        // ====================================================
        // IDLE CYCLE
        // ====================================================

        $display("\n========== IDLE TRANSACTION ==========");

        idle_cycle();


        // ====================================================
        // CREATE SOME FIFO DATA
        // ====================================================

        $display("\n========== PREPARE FOR SIMULTANEOUS R/W ==========");

        write_fifo(8'h11);
        write_fifo(8'h22);
        write_fifo(8'h33);


        // ====================================================
        // TRUE SIMULTANEOUS READ + WRITE
        // ====================================================

        $display("\n========== SIMULTANEOUS READ + WRITE ==========");

        simultaneous_read_write(8'hAA);

        simultaneous_read_write(8'hBB);

        simultaneous_read_write(8'hCC);


        // ====================================================
        // RANDOM TEST
        // ====================================================

        $display("\n========== RANDOM TEST ==========");

        repeat (50) begin

            tr = new();

            if (!tr.randomize()) begin
                $error("Randomization failed");
            end

            // ------------------------------------------------
            // Execute according to randomized operation
            // ------------------------------------------------

            if (tr.wr_en && tr.rd_en) begin

                simultaneous_read_write(tr.din);

            end
            else if (tr.wr_en) begin

                write_fifo(tr.din);

            end
            else if (tr.rd_en) begin

                read_fifo();

            end
            else begin

                idle_cycle();

            end

        end


        // ====================================================
        // FINAL SCOREBOARD CHECK
        // ====================================================

        $display("\n========== FINAL CHECK ==========");

        if (expected_queue.size() == 0) begin

            $display(
                "NOTE: FIFO scoreboard is empty after test."
            );

        end
        else begin

            $display(
                "FIFO scoreboard contains %0d remaining entries.",
                expected_queue.size()
            );

        end


        // ====================================================
        // RESULTS
        // ====================================================

        $display("\n========================================");
        $display("           TEST RESULTS");
        $display("========================================");

        $display("Total PASS : %0d", pass_count);
        $display("Total FAIL : %0d", fail_count);

        $display("\nFunctional Coverage:");

        $display(
            "Coverage = %0.2f%%",
            cov.get_coverage()
        );

        $display("========================================\n");


        // ====================================================
        // Coverage Report
        // ====================================================

        $display("Coverage should now include:");
        $display("  WRITE × READ");
        $display("  WRITE × NO_READ");
        $display("  NO_WRITE × READ");
        $display("  NO_WRITE × NO_READ");


        #20;

        $finish;

    end

endmodule