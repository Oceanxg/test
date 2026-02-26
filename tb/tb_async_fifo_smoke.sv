`timescale 1ns/1ps

module tb_async_fifo_smoke;
    localparam int DATA_WIDTH = 32;
    localparam int ADDR_WIDTH = 4;
    localparam int DEPTH      = (1 << ADDR_WIDTH);
    localparam int TEST_NUM   = DEPTH * 4;

    logic wr_clk;
    logic rd_clk;
    logic rst_n;
    logic wr_en;
    logic rd_en;
    logic [DATA_WIDTH-1:0] din;
    logic [DATA_WIDTH-1:0] dout;
    logic full;
    logic empty;

    logic [DATA_WIDTH-1:0] exp_queue[$];
    int unsigned wr_idx;
    int unsigned rd_idx;
    int unsigned err_cnt;
    logic        rd_fire;

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );

    initial wr_clk = 1'b0;
    always #5 wr_clk = ~wr_clk;

    initial rd_clk = 1'b0;
    always #7 rd_clk = ~rd_clk;

    initial begin
        $display("[TB] async_fifo smoke start");
        `ifdef DUMP_FSDB
            $fsdbDumpfile("wave.fsdb");
            $fsdbDumpvars(0, tb_async_fifo_smoke);
        `endif

        rst_n  = 1'b0;
        wr_en  = 1'b0;
        rd_en  = 1'b0;
        rd_fire = 1'b0;
        din    = '0;
        wr_idx = 0;
        rd_idx = 0;
        err_cnt = 0;

        repeat (5) @(posedge wr_clk);
        rst_n = 1'b1;

        fork
            begin : write_proc
                while (wr_idx < TEST_NUM) begin
                    @(negedge wr_clk);
                    if (!full) begin
                        wr_en <= 1'b1;
                        din   <= 32'h1A2B_0000 + wr_idx;
                    end else begin
                        wr_en <= 1'b0;
                    end

                    @(posedge wr_clk);
                    if (wr_en && !full) begin
                        exp_queue.push_back(din);
                        wr_idx++;
                    end
                end
                @(posedge wr_clk);
                wr_en <= 1'b0;
            end

            begin : read_proc
                while (rd_idx < TEST_NUM) begin
                    @(negedge rd_clk);
                    if (!empty) begin
                        rd_en <= 1'b1;
                    end else begin
                        rd_en <= 1'b0;
                    end
                end
                @(posedge rd_clk);
                rd_en <= 1'b0;
            end
        join_none

        forever begin
            @(posedge rd_clk);
            rd_fire = (rst_n && rd_en && !empty);
            if (rd_fire) begin
                logic [DATA_WIDTH-1:0] exp;
                #1step;
                if (exp_queue.size() == 0) begin
                    $error("[TB] expected queue empty when receiving data, dout=0x%08h", dout);
                    err_cnt++;
                end else begin
                    exp = exp_queue.pop_front();
                    if (dout !== exp) begin
                        $error("[TB] mismatch idx=%0d exp=0x%08h got=0x%08h", rd_idx, exp, dout);
                        err_cnt++;
                    end
                    rd_idx++;
                end
            end

            if (rd_idx == TEST_NUM) begin
                break;
            end
        end

        repeat (10) @(posedge wr_clk);

        if (err_cnt == 0) begin
            $display("[TB][PASS] async_fifo smoke pass, checked %0d transactions", TEST_NUM);
        end else begin
            $fatal(1, "[TB][FAIL] async_fifo smoke fail, err_cnt=%0d", err_cnt);
        end

        $finish;
    end

endmodule
