// ============================================================
// Synchronous FIFO Design
// Depth  : 8
// Width  : 8-bit
// ============================================================

module fifo_sync #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
)(
    input  logic             clk,
    input  logic             rst,
    input  logic             wr_en,
    input  logic             rd_en,
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout,
    output logic             full,
    output logic             empty
);

    // DEPTH must be a power of 2 because pointers wrap naturally.
    localparam PTR_W = $clog2(DEPTH);

    logic [WIDTH-1:0] mem [0:DEPTH-1];

    // Pointer width = log2(DEPTH)
    logic [PTR_W-1:0] wr_ptr;
    logic [PTR_W-1:0] rd_ptr;

    // Extra bit allows count to represent 0 through DEPTH.
    logic [PTR_W:0] count;

    // --------------------------------------------------------
    // Parameter check
    // --------------------------------------------------------
    initial begin
        if ((DEPTH & (DEPTH - 1)) != 0)
            $error("fifo_sync: DEPTH must be a power of 2");
    end

    // --------------------------------------------------------
    // Write Logic
    // --------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= '0;
        end
        else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr      <= wr_ptr + 1'b1;
        end
    end

    // --------------------------------------------------------
    // Read Logic
    // Registered output:
    // dout becomes valid after a successful read clock edge.
    // --------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= '0;
            dout   <= '0;
        end
        else if (rd_en && !empty) begin
            dout   <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // --------------------------------------------------------
    // Count Logic
    // --------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= '0;
        end
        else begin
            case ({wr_en && !full, rd_en && !empty})

                // Write only
                2'b10:
                    count <= count + 1'b1;

                // Read only
                2'b01:
                    count <= count - 1'b1;

                // No operation OR simultaneous valid
                // read + write: occupancy remains unchanged.
                default:
                    count <= count;
            endcase
        end
    end

    // --------------------------------------------------------
    // Status Flags
    // --------------------------------------------------------
    assign full  = (count == DEPTH);
    assign empty = (count == 0);

endmodule