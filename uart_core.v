//////////////////////////////////////////////////////////////////////////////////
// 1. TRANSMITTER MODULE (uart_tx) - FULLY SYNCHRONIZED
//////////////////////////////////////////////////////////////////////////////////
module uart_tx(
  input wire        clk,           // main system clock
  input wire        rst_n,         // active-low reset
  input wire        tx_clk_en,     // 16x divided baud rate enable pulse
  input wire        tx_start,      // signal to start transmission
  input wire [7:0]  tx_data,       // 8-bit data to be transmitted
  output reg        tx,            // serial output pin
  output reg        tx_busy        // high when transmission is ongoing
);
  
  localparam  IDLE  = 2'b00,
              START = 2'b01,
              DATA  = 2'b10,
              STOP  = 2'b11;
              
  reg [1:0] current_state, next_state;
  reg [7:0] data_reg;    
  reg [2:0] bit_index;   
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end
    
  always @(*) begin
    next_state = current_state;
    case (current_state)
      IDLE: begin
        if (tx_start)  next_state = START;
      end
      START: begin
        if (tx_clk_en) next_state = DATA;  // Wait full bit period
      end
      DATA: begin
        if (tx_clk_en && (bit_index == 3'b111)) 
                       next_state = STOP;
      end
      STOP: begin
        if (tx_clk_en) next_state = IDLE;  // Wait full stop bit period
      end
      default:         next_state = IDLE;
    endcase
  end
        
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_index <= 3'b000;
      data_reg  <= 8'b00000000;
    end else begin
      if (current_state == IDLE && tx_start) begin
        data_reg  <= tx_data; 
        bit_index <= 3'b000;  
      end
      else if (current_state == DATA && tx_clk_en) begin
        bit_index <= bit_index + 1; 
      end
    end
  end
      
  always @(*) begin
    case (current_state)
      IDLE: begin
        tx      = 1'b1; 
        tx_busy = 1'b0; 
      end
      START: begin
        tx      = 1'b0; 
        tx_busy = 1'b1; 
      end
      DATA: begin
        tx      = data_reg[bit_index]; 
        tx_busy = 1'b1; 
      end
      STOP: begin
        tx      = 1'b1; 
        tx_busy = 1'b1; 
      end
      default: begin
        tx      = 1'b1; 
        tx_busy = 1'b0; 
      end
    endcase
  end
          
endmodule


//////////////////////////////////////////////////////////////////////////////////
// 2. RECEIVER MODULE (uart_rx)
//////////////////////////////////////////////////////////////////////////////////
module uart_rx (
    input  wire       clk,        
    input  wire       rst_n,      
    input  wire       rx,         
    output reg  [7:0] rx_data,    
    output reg        rx_done     
);

    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    reg [1:0] current_state, next_state;
    reg [3:0] sample_ticks; 
    reg [2:0] bit_index;    
    reg [7:0] rx_shift_reg; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            sample_ticks  <= 4'b0000;
            bit_index     <= 3'b000;
            rx_shift_reg  <= 8'b00000000;
            rx_data       <= 8'b00000000;
            rx_done       <= 1'b0;
        end else begin
            rx_done <= 1'b0; 
            current_state <= next_state;

            case (current_state)
                IDLE: begin
                    sample_ticks <= 4'b0000;
                    bit_index    <= 3'b000;
                end
                START: begin
                    if (sample_ticks == 4'b0111) begin 
                        sample_ticks <= 4'b0000;
                    end else begin
                        sample_ticks <= sample_ticks + 1;
                    end
                end
                DATA: begin
                    if (sample_ticks == 4'b1111) begin 
                        sample_ticks <= 4'b0000;
                        rx_shift_reg <= {rx, rx_shift_reg[7:1]}; 
                        if (bit_index == 3'b111)
                            bit_index <= 3'b000;
                        else
                            bit_index <= bit_index + 1;
                    end else begin
                        sample_ticks <= sample_ticks + 1;
                    end
                end
                STOP: begin
                    if (sample_ticks == 4'b1111) begin 
                        sample_ticks <= 4'b0000;
                        rx_data      <= rx_shift_reg; 
                        rx_done      <= 1'b1;         
                    end else begin
                        sample_ticks <= sample_ticks + 1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (rx == 1'b0) next_state = START;
                else            next_state = IDLE;
            end
            START: begin
                if (sample_ticks == 4'b0111) begin
                    if (rx == 1'b0) next_state = DATA;
                    else            next_state = IDLE;
                end
            end
            DATA: begin
                if (sample_ticks == 4'b1111 && bit_index == 3'b111)
                    next_state = STOP;
            end
            STOP: begin
                if (sample_ticks == 4'b1111)    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule


//////////////////////////////////////////////////////////////////////////////////
// 3. TOP-LEVEL INTEGRATION (uart_top)
//////////////////////////////////////////////////////////////////////////////////
module uart_top (
    input  wire       clk,        
    input  wire       rst_n,      
    input  wire       tx_start,   
    input  wire [7:0] tx_data,    
    output wire [7:0] rx_data,    
    output wire       rx_done,    
    output wire       tx_busy     
);

    wire tx_to_rx_wire;
    
    // 16x Divider Logic for Transmitter stepping
    reg [3:0] clk_divider_count;
    reg       tx_clock_enable;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_divider_count <= 4'b0000;
            tx_clock_enable   <= 1'b0;
        end else begin
            if (clk_divider_count == 4'd15) begin
                clk_divider_count <= 4'b0000;
                tx_clock_enable   <= 1'b1;  
            end else begin
                clk_divider_count <= clk_divider_count + 1;
                tx_clock_enable   <= 1'b0;
            end
        end
    end

    // Instantiate Transmitter
    uart_tx transmitter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_clk_en(tx_clock_enable),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx_to_rx_wire),    
        .tx_busy(tx_busy)
    );

    // Instantiate Receiver
    uart_rx receiver_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rx(tx_to_rx_wire),    
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

endmodule
