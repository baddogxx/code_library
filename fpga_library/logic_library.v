
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
