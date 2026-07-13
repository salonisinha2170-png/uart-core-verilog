# UART Core with 16x Oversampling Receiver

A fully synchronized Verilog implementation of a Universal Asynchronous Receiver-Transmitter (UART) hardware core. The design features an independent transmitter module, a robust receiver with a 16x oversampling capability to filter out line noise, and a top-level integration wrapper verified using a comprehensive SystemVerilog testbench.

---

## 🛠️ System Architecture & Features

### 1. Transmitter (`uart_tx`)
* Converts parallel data bytes into a serial bitstream.
* Implements standard UART frame format: **1 Start bit (low), 8 Data bits (LSB first), and 1 Stop bit (high)**.
* Driven by a dynamic tracking scheme using an internal clock enable pulse rather than risky gated clocks.

### 2. Receiver (`uart_rx`)
* Uses a **16x oversampling strategy** to sample incoming serial lines.
* Detects the transition of the start bit and takes samples directly at the stable **center-point (8th and 16th ticks)** of each data bit to achieve stable high-speed data capture.

### 3. Top-Level Integration (`uart_top`)
* Houses an internal `clk_divider_count` module that acts as a Baud Rate Tick Generator, reducing the system master clock safely down by 16 times specifically to drive the transmission sequence seamlessly alongside the receiver logic.

---

## 🔬 Simulation & Verification

The verification environment was simulated using the **Aldec Riviera-PRO** simulation engine. 
The testbench validates data consistency through a **direct hardware loopback array**, feeding data frames sequentially into the design:
* **Test Case 1 (`8'hA5`)**: Verified zero-error transmission and parallel re-assembly.
* **Test Case 2 (`8'h3C`)**: Verified successful execution and dynamic reset handling under full operational speeds.

The EPWave simulation output confirms perfect logic transition states matching the target protocol frame boundaries exactly.
