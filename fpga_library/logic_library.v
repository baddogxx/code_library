
//同步复位
module reset_sync_module(
    input       sys_clk,
    input       rst_n   ,
    output      sync_rst_n
);


(* ASYNC = "TRUE"*)     //这样在综合的时候vivado会把这两个同步寄存器放在同一个CLB里
reg r_rst_n1,r_rst_n2;

always@(posedge sys_clk)begin
  if(~rst_n)begin
    r_rst_n1 <= 'd0;
  end else begin
    r_rst_n1 <= rst_n;
    r_rst_n2 <= r_rst_n1;
  end
end

endmodule

//异步复位同步释放
module async_reset_sync_release (
    input wire clk,       // 时钟信号
    input wire rst_n,     // 异步低电平复位信号
    input wire d,         // 输入数据
    output reg q          // 输出寄存器
);

reg rst_sync1, rst_sync2; // 用于同步复位信号的寄存器

// 异步复位，同步释放的实现
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 异步复位：一旦rst_n为低，立即复位
        rst_sync1 <= 1'b0;
        rst_sync2 <= 1'b0;
    end else begin
        // 同步释放：当复位信号释放后，rst_sync1和rst_sync2同步回1
        rst_sync1 <= 1'b1;
        rst_sync2 <= rst_sync1;
    end
end

// 主数据寄存器
always @(posedge clk) begin
    if (!rst_sync2) begin
        // 当同步复位信号为低时，复位寄存器q
        q <= 1'b0;
    end else begin
        // 正常工作时，同步更新输入数据d到输出寄存器q
        q <= d;
    end
end

endmodule


//慢时钟域到快时钟域的同步
module s2f_sync_module(
    input       i_clk1  ,
    input       i_signal,
    input       i_clk2  ,
    output      o_signal
);

(* ASYNC = "TRUE"*)
reg r_s1,r_s2;

assign  o_signal = r_s2;

always@(posedge i_clk1)begin
    r_s1 <= i_signal;
    r_s2 <= r_s1    ;
end

endmodule

//慢时钟域到快时钟域的同步
module f2s_sync_module(
    input       i_clk1  ,
    input       i_signal,
    input       i_clk2  ,
    output      o_signal
);

(* ASYNC = "TRUE"*)
reg r_d1,r_d2;
wire r_pos;      //三个信号相或的结果

assign r_pos = r_d1 | r_d2 | i_signal;

always @(posedge i_clk1) begin
    r_d1 <= i_signal;
    r_d2 <= r_d1    ;
end

reg r_p1,r_p2;
assign  o_signal = r_p2;

always @(posedge i_clk1) begin
    r_p1 <= r_pos   ;
    r_p2 <= r_p1    ;
end

endmodule


//偶数分频
module divide_2
(
    input clk , // system clock 50Mhz on board
    input rst_n, // system rst, low active
    output reg out_clk // output signal
);

parameter N = 4 ;

reg [N/2-1:0] cnt ;


always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt <= 0;
        out_clk <= 0;
    end else begin
    if(cnt==N/2-1) begin
        out_clk <= ~out_clk;
        cnt <= 0;
    end
    else
        cnt <= cnt + 1;
    end
end

 endmodule


//奇数分频
module divide_3(
    input clk , // system clock 50Mhz on board
    input rst_n, // system rst, low active
    output out_clk // output signal
);

parameter N = 3 ;

reg [N/2 :0] cnt_1 ;
reg [N/2 :0] cnt_2 ;
reg out_clk1 ;
reg out_clk2 ;

always @(posedge clk or negedge rst_n) begin //上升沿输出 out_clk1
    if(!rst_n) begin
        out_clk1 <= 0;
        cnt_1 <= 1; //这里计数器从 1 开始
    end 
    else begin
        if(out_clk1 == 0) begin
            if(cnt_1 == N/2+1) begin
                out_clk1 <= ~out_clk1;
                cnt_1 <= 1;
            end
            else
                cnt_1 <= cnt_1+1;
        end
    else if(cnt_1 == N/2) begin
        out_clk1 <= ~out_clk1;
        cnt_1 <= 1;
    end
    else
        cnt_1 <= cnt_1+1;
    end
end


always @(negedge clk or negedge rst_n) begin //下降沿输出 out_clk2
    if(!rst_n) begin
        out_clk2 <= 0;
        cnt_2 <= 1; //这里计数器从 1 开始
    end
    else begin
        if(out_clk2 == 0) begin
            if(cnt_2 == N/2+1) begin
                out_clk2 <= ~out_clk2;
                cnt_2 <= 1;
            end
            else
            cnt_2 <= cnt_2+1;
        end
        else if(cnt_2 == N/2) begin
            out_clk2 <= ~out_clk2;
            cnt_2 <= 1;
        end
        else
            cnt_2 <= cnt_2+1;
        end
end

assign out_clk = out_clk1 | out_clk2;

endmodule

/*跨时钟域同步
使用方法：例如：mu_dbsync #(20) pctl_sync (clk, clk_pix, dsilite_pctl, dsilite_pctl_clk_pix);
*/
module mu_dbsync #(
    parameter W = 8
) (
    input  wire         iclk,
    input  wire         oclk,
    input  wire [W-1:0] in,
    output wire [W-1:0] out
);

    xpm_cdc_array_single #(
        .WIDTH(W)
    ) xpm_cdc_array_single (
        .src_clk    (iclk),
        .dest_clk   (oclk),
        .src_in     (in),
        .dest_out   (out)
    );

endmodule


//数据位宽匹配模块 位宽减半
module mu_widthadapt_2_to_1 #(
    parameter IW = 64,
    parameter OW = IW / 2
) (
    input  wire             clk,
    input  wire             rst,
    // Incoming port
    input  wire [IW-1:0]    wr_data,
    input  wire             wr_valid,
    output wire             wr_ready,
    // Outgoing port
    output wire [OW-1:0]    rd_data,
    output wire             rd_valid,
    input  wire             rd_ready
);

    reg [IW-1:0]    fifo;
    reg             fifo_full;
    reg             fifo_empty;
    
    always @(posedge clk) begin
        if (fifo_empty) begin
            // Output invalid, if with valid input, fill input
            if (wr_valid) begin
                fifo <= wr_data;
                fifo_empty <= 1'b0;
                fifo_full <= 1'b1;
            end
        end
        else if (fifo_full) begin
            // Output valid, input not ready, if with valid output, shift
            if (rd_ready) begin
                fifo <= {fifo[OW-1:0], {OW{1'b0}}};
                fifo_full <= 1'b0;
            end
        end
        else begin
            // Half empty, output valid, input ready only if output is ready
            if (rd_ready && wr_valid) begin
                fifo <= wr_data;
                fifo_full <= 1'b1;
            end
            else if (rd_ready) begin
                fifo_empty <= 1'b1;
            end
        end

        if (rst) begin
            fifo_full <= 1'b0;
            fifo_empty <= 1'b1;
        end
    end

    // RX data if fifo is empty
    assign wr_ready = fifo_empty || (!fifo_full && rd_ready);
    assign rd_valid = !fifo_empty;
    assign rd_data = fifo[OW*2-1:OW];

endmodule

//信号延拓
module signal_extender #(
    parameter N = 4 // 延拓的时钟周期数（默认 4 个周期）
) (
    input  wire clk,            // 系统时钟
    input  wire rst_n,          // 系统复位（低有效）
    input  wire i_signal,         // 原始单周期 i_signal 信号
    output reg  extended_signal // 延拓后的 i_signal 信号
);

    reg [31:0] count; // 延拓计数器，位宽足够大以支持较大的 N

    // 延拓逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;                // 复位计数器
            extended_signal <= 1'b0; // 初始化为低电平
        end else begin
            if (i_signal) begin
                count <= N;               // 检测到 i_signal 高电平时，加载延拓周期
                extended_signal <= 1'b1; // 输出信号设为高电平
            end else if (count > 0) begin
                count <= count - 1;       // 倒计时
                if (count == 1)           // 当计数器减到 1 时，将信号拉低
                    extended_signal <= 1'b0;
            end
        end
    end

endmodule
    // 实例化 signal_delay 模块
    signal_delay #(
        .N(5),                  // 延迟 5 个时钟周期
        .WIDTH(4)               // 输入信号位宽为 4-bit
    ) delay_inst (
        .sys_clk(sys_clk),      // 连接系统时钟
        .sys_rst_n(sys_rst_n),  // 连接系统复位
        .din(din),              // 输入信号
        .dout(dout)             // 延迟后的输出信号
    );


module signal_delay #(
    parameter N = 4,              // 延迟的时钟周期数（默认为 4 拍）
    parameter WIDTH = 1           // 信号的位宽（默认为 1 bit）
) (
    input wire sys_clk,           // 系统时钟
    input wire sys_rst_n,         // 系统复位信号（低有效）
    input wire [WIDTH-1:0] din,   // 输入信号
    output wire [WIDTH-1:0] dout  // 打 N 拍后的输出信号
);

    // 延迟寄存器数组
    reg [WIDTH-1:0] delay_pipeline [0:N-1];

    integer i;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            // 复位所有寄存器
            for (i = 0; i < N; i = i + 1) begin
                delay_pipeline[i] <= {WIDTH{1'b0}};
            end
        end else begin
            // 数据沿流水线逐级推进
            delay_pipeline[0] <= din;  // 第一级寄存器存储输入信号
            for (i = 1; i < N; i = i + 1) begin
                delay_pipeline[i] <= delay_pipeline[i-1];
            end
        end
    end

    // 输出信号为延迟链末端的寄存器值
    assign dout = delay_pipeline[N-1];

endmodule

//     // 实例化 signal_delay 模块
// signal_delay #(
//     .N(5),                  // 延迟 5 个时钟周期
//     .WIDTH(4)               // 信号位宽为 4-bit
// ) delay_inst (
//     .sys_clk(sys_clk),      // 系统时钟
//     .sys_rst_n(sys_rst_n),  // 系统复位
//     .din(din),              // 输入信号
//     .dout(dout)             // 延迟后的输出信号
// );

module rhs_read (
    input           sys_clk     ,
    input           sys_rst_n   ,

    input           i_read_req  ,
    input  [31:0]   i_read_addr ,

    output reg [31:0] o_read_data ,
    output reg        o_read_done
);

/***********************************************/
reg [1:0] current_state, next_state;
localparam IDLE  = 2'b00;
localparam WRITE = 2'b01;
localparam READ  = 2'b10;
localparam DONE  = 2'b11;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) current_state <= IDLE;
    else            current_state <= next_state; end
/***********************************************/
always @(*) begin
    case (current_state)
        IDLE: begin
            if (1)       
                next_state = WRITE; else next_state = IDLE;  end
        WRITE: begin
            if (1)       
                next_state = READ;  else next_state = WRITE; end
        READ: begin
            if (1)       
                next_state = DONE;  else next_state = READ;  end  
        DONE: begin
            if (1)       
                next_state = IDLE;  else next_state = DONE;  end
        default: next_state = IDLE;
    endcase
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin

    end else begin
        case (current_state)
            IDLE: begin
               
            end
            WRITE: begin
                
            end
            READ: begin
                
            end
            DONE: begin
                
            end
        endcase
    end
end

endmodule



`default_nettype wire
