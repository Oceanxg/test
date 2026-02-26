module async_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 4
) (
    input  logic                  wr_clk,
    input  logic                  rd_clk,
    input  logic                  rst_n,
    input  logic                  wr_en,
    input  logic                  rd_en,
    input  logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout,
    output logic                  full,
    output logic                  empty
);

localparam int DEPTH = (1 << ADDR_WIDTH);

logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

logic [ADDR_WIDTH:0] wr_bin;
logic [ADDR_WIDTH:0] rd_bin;
logic [ADDR_WIDTH:0] wr_gray;
logic [ADDR_WIDTH:0] rd_gray;

logic [ADDR_WIDTH:0] rd_gray_sync1;
logic [ADDR_WIDTH:0] rd_gray_sync2;
logic [ADDR_WIDTH:0] wr_gray_sync1;
logic [ADDR_WIDTH:0] wr_gray_sync2;

logic [ADDR_WIDTH:0] wr_bin_next;
logic [ADDR_WIDTH:0] rd_bin_next;
logic [ADDR_WIDTH:0] wr_gray_next;
logic [ADDR_WIDTH:0] rd_gray_next;

logic wr_allow;
logic rd_allow;

assign wr_allow = wr_en && !full;
assign rd_allow = rd_en && !empty;

assign wr_bin_next  = wr_bin + wr_allow;
assign rd_bin_next  = rd_bin + rd_allow;
assign wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
assign rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

always_ff @(posedge wr_clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_bin  <= '0;
        wr_gray <= '0;
    end else begin
        if (wr_allow) begin
            mem[wr_bin[ADDR_WIDTH-1:0]] <= din;
        end
        wr_bin  <= wr_bin_next;
        wr_gray <= wr_gray_next;
    end
end

always_ff @(posedge rd_clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_bin  <= '0;
        rd_gray <= '0;
        dout    <= '0;
    end else begin
        if (rd_allow) begin
            dout <= mem[rd_bin[ADDR_WIDTH-1:0]];
        end
        rd_bin  <= rd_bin_next;
        rd_gray <= rd_gray_next;
    end
end

always_ff @(posedge wr_clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_gray_sync1 <= '0;
        rd_gray_sync2 <= '0;
    end else begin
        rd_gray_sync1 <= rd_gray;
        rd_gray_sync2 <= rd_gray_sync1;
    end
end

always_ff @(posedge rd_clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_gray_sync1 <= '0;
        wr_gray_sync2 <= '0;
    end else begin
        wr_gray_sync1 <= wr_gray;
        wr_gray_sync2 <= wr_gray_sync1;
    end
end

assign full = (wr_gray_next == {~rd_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_gray_sync2[ADDR_WIDTH-2:0]});
assign empty = (rd_gray_next == wr_gray_sync2);

endmodule
