
module DMA (
    input wire clk,
    input wire rst,           // Asynchronous reset (active high)

    // -------- CPU Interface --------
    input wire start,
    input wire [7:0] src_addr,
    input wire [7:0] dest_addr,
    input wire [7:0] length,
    output reg done,

    // -------- Memory Interface --------
    input wire [7:0] mem_data_in,
    input wire mem_ready,
    output reg [7:0] mem_addr,
    output reg mem_read,
    output reg mem_write,
    output reg [7:0] mem_data_out
);

    // -------- Internal Registers --------
    reg [7:0] src;
    reg [7:0] dest;
    reg [7:0] len;
    reg [7:0] data_buffer;
    reg [2:0] state;

    // -------- FSM States --------
    localparam IDLE  = 3'd0,
               READ  = 3'd1,
               WAIT  = 3'd2,
               WRITE = 3'd3,
               DONE  = 3'd4;

    // -------- FSM --------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            done         <= 0;
            mem_read     <= 0;
            mem_write    <= 0;
            mem_addr     <= 0;
            mem_data_out <= 0;
            src          <= 0;
            dest         <= 0;
            len          <= 0;
            data_buffer  <= 0;
        end else begin
            // Default outputs (avoid latches / glitches)
            mem_read  <= 0;
            mem_write <= 0;
            done      <= 0;

            case (state)

                IDLE: begin
                    if (start) begin
                        src   <= src_addr;
                        dest  <= dest_addr;
                        len   <= length;
                        state <= READ;
                    end
                end

                READ: begin
                    mem_addr <= src;
                    mem_read <= 1;
                    state    <= WAIT;
                end

                WAIT: begin
                    if (mem_ready) begin
                        data_buffer <= mem_data_in;
                        state <= WRITE;
                    end
                end

                WRITE: begin
                    mem_addr     <= dest;
                    mem_data_out <= data_buffer;
                    mem_write    <= 1;

                    src  <= src + 1;
                    dest <= dest + 1;
                    len  <= len - 1;

                    if (len == 1)
                        state <= DONE;
                    else
                        state <= READ;
                end

                DONE: begin
                    done  <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule



module dma_tb;

    reg clk;
    reg rst;
    reg start;
    reg [7:0] src_addr;
    reg [7:0] dest_addr;
    reg [7:0] length;

    wire done;

    reg [7:0] mem_data_in;
    reg mem_ready;
    wire [7:0] mem_addr;
    wire mem_read;
    wire mem_write;
    wire [7:0] mem_data_out;

    // Instantiate DMA
    DMA dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .src_addr(src_addr),
        .dest_addr(dest_addr),
        .length(length),
        .done(done),
        .mem_data_in(mem_data_in),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_data_out(mem_data_out)
    );

    // Clock: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Fake memory
    reg [7:0] memory [0:255];

    initial begin
        // Initialize memory
        memory[10] = 8'hAA;
        memory[11] = 8'hBB;
        memory[12] = 8'hCC;
        memory[13] = 8'hDD;
        memory[14] = 8'hEE;

        // Initialize signals
        rst = 1;
        start = 0;
        src_addr  = 8'd10;
        dest_addr = 8'd100;
        length    = 8'd5;
        mem_data_in = 0;
        mem_ready = 0;

        #20 rst = 0;

        #10 start = 1;
        #10 start = 0;

        wait(done);

        #20;
        $display("DMA COPY RESULT:");
        $display("100 = %h", memory[100]);
        $display("101 = %h", memory[101]);
        $display("102 = %h", memory[102]);
        $display("103 = %h", memory[103]);
        $display("104 = %h", memory[104]);

        $stop;
    end

    // Memory behavior
    always @(posedge clk) begin
        mem_ready <= 0;

        if (mem_read) begin
            mem_data_in <= memory[mem_addr];
            mem_ready   <= 1;
        end

        if (mem_write) begin
            memory[mem_addr] <= mem_data_out;
        end
    end

endmodule

