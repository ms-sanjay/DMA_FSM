module DMA (
    input wire clk,           // Clock signal
    input wire rst,           // Asynchronous reset (active high)

    // -------- CPU Interface --------
    input wire start,         // CPU starts the DMA transfer (1-cycle pulse)
    input wire [7:0] src_addr,// Starting source address in memory
    input wire [7:0] dest_addr,// Starting destination address in memory
    input wire [7:0] length,  // Number of bytes to transfer
    output reg done,          // DMA signals CPU when transfer is complete

    // -------- Memory Interface --------
    input wire [7:0] mem_data_in, // Data read from memory
    input wire mem_ready,         // Memory asserts when data is valid
    output reg [7:0] mem_addr,    // Address given to memory (for read/write)
    output reg mem_read,          // Request to memory: read at mem_addr
    output reg mem_write,         // Request to memory: write at mem_addr
    output reg [7:0] mem_data_out // Data to write into memory
);

    // -------- Internal Registers --------
    reg [7:0] src;          // Current source pointer (incremented each read)
    reg [7:0] dest;         // Current destination pointer (incremented each write)
    reg [7:0] len;          // Remaining number of bytes to transfer
    reg [2:0] state;        // Holds the FSM state
    reg [7:0] data_buffer;  // Temporary buffer to hold one byte between read and write

    // -------- FSM State Encoding --------
    localparam IDLE  = 3'd0, // Waiting for CPU start
               READ  = 3'd1, // Issue memory read
               WRITE = 3'd2, // Write fetched data to destination
               WAIT  = 3'd3, // Wait until mem_ready (read completes)
               DONE  = 3'd4; // Signal CPU transfer complete

    // -------- Main FSM (runs on every clock edge) --------
    always @(posedge clk or posedge rst) begin
        // Asynchronous reset: return to known state
        if(rst) begin
            state        <= IDLE;    // Start in IDLE
            done         <= 0;
            mem_read     <= 0;
            mem_write    <= 0;
            mem_addr     <= 8'd0;
            mem_data_out <= 8'd0;
            src          <= 8'd0;
            dest         <= 8'd0;
            len          <= 8'd0;
            data_buffer  <= 8'd0;
        end
        else begin
            // -------- FSM Behavior --------
            case(state)

            // -------------------- IDLE State -------------------- //
            IDLE: begin
                mem_read  <= 0;   // Ensure memory signals are low
                mem_write <= 0;

                // Wait for CPU to start transfer
                if(start) begin
                    done  <= 0;              // Clear "done" flag
                    src   <= src_addr;       // Load starting source address
                    dest  <= dest_addr;      // Load starting destination address
                    len   <= length;         // Load transfer length
                    state <= READ;           // Go to READ state
                end
            end

            // -------------------- READ State (Fetch from source) -------------------- //
            READ: begin
                mem_addr <= src;  // Present current source address to memory
                mem_read <= 1;    // Request read
                state    <= WAIT; // Move to WAIT for mem_ready
            end

            // -------------------- WAIT State (Wait for memory valid) -------------------- //
            WAIT: begin
                mem_read <= 0;   // Deassert read (only needed for 1 cycle)
                if(mem_ready) begin
                    data_buffer <= mem_data_in; // Capture data from memory
                    state       <= WRITE;       // Move to WRITE state
                end
            end

            // -------------------- WRITE State (Write to destination) -------------------- //
            WRITE: begin
                mem_addr     <= dest;        // Set memory address to destination
                mem_data_out <= data_buffer; // Provide buffered data
                mem_write    <= 1;           // Assert write enable

                // Update pointers and counters
                src  <= src + 1;    // Move to next source address
                dest <= dest + 1;   // Move to next destination address
                len  <= len - 1;    // One byte transferred

                // If last byte, finish; else go back to READ
                if(len == 1) begin
                    state <= DONE;  // All bytes transferred
                end
                else begin
                    state <= READ;  // More bytes to go
                end
                mem_write <= 0;    // Deassert write (only needed for 1 cycle)
            end

            // -------------------- DONE State (Notify CPU) -------------------- //
            DONE: begin
                done  <= 1;     // Assert done signal
                state <= IDLE;  // Return to IDLE, wait for next start
            end

            endcase
        end
    end

endmodule
