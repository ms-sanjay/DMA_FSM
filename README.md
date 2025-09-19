# DMA Controller (Verilog)

## Description
This project implements a **Direct Memory Access (DMA) Controller** in Verilog.  
A DMA controller enables peripherals or subsystems to transfer data directly between memory locations without CPU intervention, improving overall system performance.  

The controller supports **byte-wise data transfers** and simple handshaking with memory. It is controlled by the CPU through a `start` signal and notifies the CPU when the transfer is complete via a `done` signal.

---

## How It Works
The DMA controller uses a **Finite State Machine (FSM)** to manage memory transfers:

1. **IDLE** – Waits for the CPU to assert the `start` signal.  
2. **READ** – Sends the current source address to memory and requests a read.  
3. **WAIT** – Waits for the memory to signal `mem_ready`, indicating valid data.  
4. **WRITE** – Writes the fetched data to the destination address and updates the pointers.  
5. **DONE** – Signals the CPU that the transfer is complete and returns to IDLE for the next operation.

**Key Points:**
- Transfers occur **one byte at a time**.  
- Internal registers `src`, `dest`, and `len` track source, destination, and remaining bytes.  
- `data_buffer` temporarily holds data between read and write cycles.  
- `mem_read` and `mem_write` signals coordinate with memory for each operation.  
- FSM ensures proper sequencing and prevents data corruption.

This design is suitable for **simple memory-to-memory transfers** in embedded systems or SoC designs, demonstrating basic DMA functionality with a clear and modular structure.
