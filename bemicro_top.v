
module bemicro_top(
   // General
   input    wire  CLK_FPGA_50M,
   input    wire  CPU_RST_N,

   // Temp. Sensor I/F
   output   wire  TEMP_CS_N,
   output   wire  TEMP_SC,       
   output   wire  TEMP_MOSI,
   input    wire  TEMP_MISO,
	
   // Misc
   input    wire  RECONFIG_SW1,
   input    wire  RECONFIG_SW2,
   input    wire  PBSW_N,
   output   wire  F_LED0,
   output   wire  F_LED1,
   output   wire  F_LED2,
   output   wire  F_LED3,
   output   wire  F_LED4,
   output   wire  F_LED5,
   output   wire  F_LED6,
   output   wire  F_LED7
   );

   wire             clk; // 50 MHz
   wire [1:0]       pb; // Pushbuttons
   wire [7:0]       temp_sensor; // Temperature sensor
   
   reg [7:0]  led;
	
   //Rename the strange input names to easier names to remember.
   //Also handle active-low signals correctly.
   assign clk = CLK_FPGA_50M;
   assign pb = {~PBSW_N, ~CPU_RST_N};
   assign {F_LED0,F_LED1,F_LED2,F_LED3,F_LED4,F_LED5,F_LED6,F_LED7} = ~led;

// --------------------------------------------------------------------------------

   // -----------
   // RESET LOGIC
   // -----------

   reg [19:0]   reset_cnt;
   
   always @(posedge clk)
     if (!reset_cnt[19])
       reset_cnt <= reset_cnt + 1'b1;

   wire         reset = ~reset_cnt[19];

// --------------------------------------------------------------------------------

   // Synchronize pushbutton inputs to input clock

   // NOTE: Each button is asynchronous to all others.  THIS DOES NOT WORK to
   //   synchronize an input bus to a clock domain.
   reg [1:0]    pb_s0, pb_s1, pb_in;
   always @(posedge clk)
     begin
     pb_s0 <= pb;
     pb_s1 <= pb_s0;
     pb_in <= pb_s1;
     end
   
// --------------------------------------------------------------------------------
   
   wire [25:0]  pb0_cntr, pb1_cntr;

   // Only allow pushbuttons to trigger every so often
   // Create a saturating counter that resets when pb is pressed

   counter_sat #(26) PB0_CNTR(
                              // Outputs
                              .count            (pb0_cntr),
                              // Inputs
                              .clk              (clk),
                              .clear            (pb_in[0]));
        
   counter_sat #(26) PB1_CNTR(
                              // Outputs
                              .count            (pb1_cntr),
                              // Inputs
                              .clk              (clk),
                              .clear            (pb_in[1]));


   // What will each of these conditions synthesize to?
   wire pb0_saturated = pb0_cntr[25]; // Saturates after .336 seconds
   wire pb1_saturated = (pb1_cntr[25:0] > 26'he4e1c0) ? 1'b1 : 1'b0; // Saturates after .300 seconds

   wire pb0_event = pb_in[0] && pb0_saturated;
   wire pb1_event = pb_in[1] && pb1_saturated;
   

// --------------------------------------------------------------------------------

   // ----------------
   // MODULE INSTANCES
   // ----------------
   
	wire [7:0] counter_led_out;
	
	//We have to do this since the module's output is a wire,
	//but we want to assign to the led register
	always @(posedge clk) led <= counter_led_out;
	
   binary_counter counter0(
                           // Outputs
                           .led(counter_led_out),
                           // Inputs
                           .clk(clk),
                           .reset(reset),
                           .event0(pb0_event),
                           .event1(pb1_event));
   
endmodule // bemicro_top
