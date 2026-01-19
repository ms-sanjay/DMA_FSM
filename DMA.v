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
