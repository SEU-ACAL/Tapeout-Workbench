module multiplier_pipe3 #(
      parameter A_WIDTH = 32,
      parameter B_WIDTH = 32
  ) (
      input  wire                       clock,
      input  wire                       reset_n,
      input  wire                       valid_in,
      input  wire [A_WIDTH-1:0]         a,
      input  wire [B_WIDTH-1:0]         b,
      output reg                        valid_out,
      output reg  [A_WIDTH+B_WIDTH-1:0] product
  );

      reg [A_WIDTH-1:0]         a_s1;
      reg [B_WIDTH-1:0]         b_s1;
      reg                       valid_s1;
      reg [A_WIDTH+B_WIDTH-1:0] product_s2;
      reg                       valid_s2;

      always @(posedge clock or negedge reset_n) begin
          if (!reset_n) begin
              a_s1       <= '0;
              b_s1       <= '0;
              valid_s1   <= 1'b0;
              product_s2 <= '0;
              valid_s2   <= 1'b0;
              product    <= '0;
              valid_out  <= 1'b0;
          end else begin
              // Stage 1: capture operands
              if (valid_in) begin
                  a_s1 <= a;
                  b_s1 <= b;
              end
              valid_s1 <= valid_in;

              // Stage 2: multiply
              if (valid_s1) begin
                  product_s2 <= a_s1 * b_s1;
              end
              valid_s2 <= valid_s1;

              // Stage 3: register output
              if (valid_s2) begin
                  product <= product_s2;
              end
              valid_out <= valid_s2;
          end
      end

  endmodule