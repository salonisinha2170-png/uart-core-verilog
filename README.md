# UART Core with 16x Oversampling Receiver

A fully synchronized Verilog implementation of a universal asynchronous receiver-transmitter (UART) hardware core. The design includes an independent transmitter module, a robust receiver with 16x oversampling capability, and a top-level integration wrapper verified using a comprehensive SystemVerilog testbench.

## Architecture & Features
* **`uart_tx`**: Handles parallel-to-serial conversion with standard Frame formatting (1 Start bit, 8 Data bits, 1 Stop bit).
* **`uart_rx`**: Features a 16x oversampling clock synchronization mechanism to accurately sample incoming bitstreams at their stable center-point.
* **Internal Baud Rate Enable**: A clock divider embedded within the top module aligns the bit-rate timing parameters dynamically without relying on dangerous gated clocks.

## Simulation & Verification
The design was simulated using the Aldec Riviera-PRO simulator. The functional verification environment performs direct loopback testing by verifying successful transmission and serial-to-parallel reconstruction across edge-case data frames like `8'hA5` and `8'h3C`.
