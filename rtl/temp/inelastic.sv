// Two-state inelastic slice: IDLE/DONE without an explicit FSM enum
module inelastic #(
    parameter int DataWidth = 8
) (
    input  logic                 clk_i,
    input  logic                 rst_i,

    input  logic [DataWidth-1:0] in_data_i,
    input  logic                 in_valid_i,
    output logic                 in_ready_o,

    output logic                 out_valid_o,
    output logic [DataWidth-1:0] out_data_o,
    input  logic                 out_ready_i
);
    logic [DataWidth-1:0] data_q;
    logic                 valid_q;

    // Single-issue: ready only when empty
    assign in_ready_o  = ~valid_q;
    assign out_valid_o =  valid_q;
    assign out_data_o  =  data_q;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            data_q  <= '0;
            valid_q <= 1'b0;
        end else begin
            if (!valid_q) begin
                // Capture when empty and producer is valid
                if (in_valid_i) begin
                    data_q  <= in_data_i;
                    valid_q <= 1'b1;
                end
            end else begin
                // Release when consumer is ready
                if (out_ready_i) begin
                    valid_q <= 1'b0;
                end
            end
        end
    end
endmodule




// FSM Version
// module rv_stage #(
//     parameter int DataWidth = 8
// ) (
//     input  logic                 clk_i,
//     input  logic                 rst_i,

//     input  logic [DataWidth-1:0] in_data_i,
//     input  logic                 in_valid_i,
//     output logic                 in_ready_o,

//     output logic                 out_valid_o,
//     output logic [DataWidth-1:0] out_data_o,
//     input  logic                 out_ready_i
// );

//     typedef enum logic { 
//         S_IDLE, 
//         S_DONE 
//     } state_e;

//     state_e state_q, state_d;
//     logic [DataWidth-1:0] data_q, data_d;

//     always_comb begin
//         state_d     = state_q;
//         data_d      = data_q;

//         in_ready_o  = (state_q == S_IDLE);
//         out_valid_o = (state_q == S_DONE);
//         out_data_o  = data_q;             

//         unique case (state_q)
//             S_IDLE: begin
//                 if (in_valid_i && in_ready_o) begin
//                     data_d  = in_data_i;
//                     state_d = S_DONE;
//                 end
//             end

//             S_DONE: begin
//                 if (out_ready_i) begin
//                     state_d = S_IDLE;
//                 end
//             end
//         endcase
//     end

//     always_ff @(posedge clk_i) begin
//         if (rst_i) begin
//             state_q <= S_IDLE;
//             data_q  <= '0;
//         end else begin
//             state_q <= state_d;
//             data_q  <= data_d;
//         end
//     end

// endmodule


// Inelastic pipeline
// module rv_stage #(
//     parameter int DataWidth = 8
// ) (
//     input  logic                 clk_i,
//     input  logic                 rst_i,

//     input  logic [DataWidth-1:0] in_data_i,
//     input  logic                 in_valid_i,
//     output logic                 in_ready_o,

//     output logic                 out_valid_o,
//     output logic [DataWidth-1:0] out_data_o,
//     input  logic                 out_ready_i
// );

//     logic [DataWidth-1:0] data_q;
//     logic                 valid_q;

//     assign in_ready_o  = ~valid_q;
//     assign out_valid_o = valid_q; 
//     assign out_data_o  = data_q;

//     always_ff @(posedge clk_i) begin
//         if (rst_i) begin
//             data_q  <= '0;
//             valid_q <= 1'b0;
//         end else begin
//             if (~valid_q) begin
//                 if (in_valid_i) begin
//                     data_q  <= in_data_i;
//                     valid_q <= 1'b1;
//                 end
//             end else begin
//                 if (out_ready_i) begin
//                     valid_q <= 1'b0;
//                 end
//             end
//         end
//     end

// endmodule
