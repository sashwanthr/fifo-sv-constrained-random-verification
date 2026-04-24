// Synchronous FIFO Design
// Depth: 8, Data Width: 8-bit

module fifo_sync #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
)(
    input  logic            clk,
    input  logic            rst,
    input  logic            wr_en,
    input  logic            rd_en,
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout,
    output logic            full,
    output logic            empty
);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [$clog2(DEPTH):0] wr_ptr, rd_ptr, count;

    // Write Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 0;
            dout   <= 0;
        end else if (rd_en && !empty) begin
            dout   <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Count Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
        end else begin
            case ({wr_en & !full, rd_en & !empty})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: count <= count;
            endcase
        end
    end

    // Full and Empty Flags
    assign full  = (count == DEPTH);
    assign empty = (count == 0);

endmodule
