// ===========================================
// Dispatcher Module
//
// A top level module design that will decide
// which compute units to "activate" and will interface
// with "user" inputs. Similar to a scheduler 
// within the compute unit, the dispatcher will organize
// which compute units & how many threads will perform the 
// given operation.
//
// For the logic, we will be using a bit-wide logic. AKA:
// If we have 4 active cores, the width of cu_complete is 4 bits
//
// This dispatcher will operate under the base case assumption which is as follows:
// - All active compute units will operate the same set of PC instructions 
//    for the given number of threads, which is at most 16. 
// - There will be an assumed no branch divergence  
//
// I/O Ports:
// 1. thread_count: total number of active threads; max = 16 b/c of 4 CU
// 2. kernel_start: input signal to indicate the start of kernel execution
// 3. cu_complete: Input Signal to track progress of each core 
// 4. cu_enable: Output signal to enable the active cores
// 5. cu_reset: Output reset signals to reset the active cores
// 6. cu_active_threads: Number of active threads per core
// 7. kernel_complete: Signal to track whether or not the current kernel is completed
// ===========================================

module dispatcher #(
  parameter NUM_CORES = 4
) (
  input clk, 
  input reset,

  // Func  tional Inputs
  input [4:0] thread_count,
  input kernel_start, 

  // I/O to interact with cores 
  input [NUM_CORES-1:0] cu_complete, 
  output [NUM_CORES-1:0] cu_enable,
  output [NUM_CORES-1:0] cu_reset,
  output [2:0] cu_active_threads [NUM_CORES-1:0], 

  // Functional Outputs
  output kernel_complete

); 

reg [2:0] active_cores;
always @(*) active_cores = (thread_count+3)/4; // Logic that will always round up

// Registering outputs
reg [NUM_CORES-1:0] cu_enable_reg; 
reg [NUM_CORES-1:0] cu_reset_reg;
reg [2:0] cu_active_threads_reg [NUM_CORES-1:0]; 
reg kernel_complete_reg;
assign cu_enable = cu_enable_reg;
assign cu_reset = cu_reset_reg;
assign cu_active_threads[0] = cu_active_threads_reg[0];
assign cu_active_threads[1] = cu_active_threads_reg[1];
assign cu_active_threads[2] = cu_active_threads_reg[2];
assign cu_active_threads[3] = cu_active_threads_reg[3];
assign kernel_complete = kernel_complete_reg;

// Internal registers
reg [4:0] counter;
reg initial_reset;
reg cu_complete_check;
integer j;

always @(posedge clk) begin 
  if (reset) begin 
    cu_enable_reg <= 0;
    cu_reset_reg <= 0;
    kernel_complete_reg <= 0;
    for (j=0;j<NUM_CORES;j=j+1) begin 
      cu_active_threads_reg[j] <= 3'b0;
    end
    // Resetting our internals
    counter <= 0;
    initial_reset <= 0;
    cu_complete_check <= 0;
  end else begin 
    if (kernel_start) begin 
      counter <= 0;
      // Need to first reset each core
      if (!initial_reset) begin 
        initial_reset <= 1;
        for (j=0;j<active_cores;j=j+1) begin 
          cu_reset_reg[j] <= 1;
        end
      end
      else begin 
        // Set the reset signals to low; In theory its only high for 1 cycle
        for (j=0;j<active_cores;j=j+1) begin 
          cu_reset_reg[j] <= 0;
        end

        // Enable all active registers
        for (j=0;j<active_cores;j=j+1) begin 
          // Computing the number of active threads per core
          if (counter + 4 > thread_count) begin 
            cu_active_threads_reg[j] <= (thread_count - counter);
          end else begin 
            cu_active_threads_reg[j] <= 4;
            counter = counter + 4;
          end
          // Enabling all of the proper active cores
          cu_enable_reg[j] = 1;
          if (cu_complete[j] && cu_enable_reg[j]) begin 
            cu_enable_reg[j] = 0;
          end
        end

        // Check for completion
        cu_complete_check = 0;
        for (j=0;j<active_cores;j=j+1) begin 
          if (!cu_complete[j] && cu_enable_reg[j]) begin 
            cu_complete_check = 1;
          end
        end
        kernel_complete_reg <= !cu_complete_check;

        // if (!cu_complete_check) begin 
        //   // All cores are complete
        //   kernel_complete_reg <= 1;
        // end else begin 
        //   // Assigning each active core the number of active threads
        //   for (j=0;j<active_cores;j=j+1) begin 
        //     if (counter + 4 > thread_count) begin 
        //       cu_active_threads_reg[j] <= (thread_count - counter);
        //     end else begin 
        //       cu_active_threads_reg[j] <= 4;
        //       counter = counter + 4;
        //     end
        //     // Enabling all of the cores that are not finished)
        //     cu_enable_reg[j] <= 1;
        //     if (cu_complete[j] && cu_enable_reg[j]) begin 
        //       cu_enable_reg[j] <= 0;
        //     end
        //   end
        // end
      end
    end
  end
end

// Helper for dumping wires
wire [2:0] active_thread0; 
wire [2:0] active_thread1; 
wire [2:0] active_thread2; 
wire [2:0] active_thread3;
assign active_thread0 = cu_active_threads[0]; 
assign active_thread1 = cu_active_threads[1]; 
assign active_thread2 = cu_active_threads[2]; 
assign active_thread3 = cu_active_threads[3]; 

endmodule