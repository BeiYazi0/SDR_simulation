function decode = Channeldecode(code)
G = [1,0,1;1,1,1];   % 卷积码生成多项式
sfd=[0; 1; 0; 1; 0; 1; 1; 1];
pre_core=[  1; 1; 0; 0;
            1; 1; 0; 0;
            1; 1; 0; 0;
            1; 1; 0; 0;
            1; 1; 0; 1;
            1; 1; 0; 1;
            1; 1; 0; 1;
            1; 1; 0; 1;
            1; 1; 1; 1;
            1; 1; 1; 1;
            1; 1; 1; 1;
            1; 1; 1; 1;
            1; 1; 1; 0;
            1; 1; 1; 0;
            1; 1; 1; 0;
            1; 1; 1; 0;];

% 寻找detframe序列位置
detframe=[pre_core; sfd];
pos = 1:length(code);
for i=1:length(detframe)
    pos_temp=find(code(i:end-length(detframe)+i)==detframe(i));
    pos=intersect(pos,pos_temp);
end
if isempty(pos)  % 未找到有效信息
    decode = [];
    return
end
pos = pos(1);

frame_syn_code = code(pos+length(detframe):end);     
len_type = reshape(frame_syn_code(1:24), 8, []).';         % 帧长字段
len_type = bi2de(len_type);
len_type = len_type(1)*65536+len_type(2)*256+len_type(3);  % 计算帧长
scramble_N = floor(sqrt(len_type));                        % 计算交织矩阵宽度
frame_syn_code = frame_syn_code(25:scramble_N^2+24);       % 提取数据序列

% 解交织
descrambledcode = reshape(frame_syn_code,[scramble_N scramble_N]);
descrambledcode = reshape(descrambledcode.', [scramble_N^2 1]);

% 信道译码
type_info = descrambledcode(1:8);
type = decode_type(type_info);
if type == 1
    decode = linear_decode(descrambledcode(9:end));
elseif type == 2
    decode = conv_decode(G, 1, descrambledcode(9:end));
end
end

% 确定编码方式
function type = decode_type(type_info)
linear_pss = length(find(type_info ~= [0,0,1,1,1,1,0,0].'));
conv_pss = length(find(type_info ~= [1,1,0,0,0,0,1,1].'));
% 根据码距确定编码方式
if linear_pss < conv_pss
    type = 1;
else
    type = 2;
end
end

% 线性分组码译码
function A = linear_decode(x) 
%分组码各部分长度
k = 8;   % 信息码元数
r = 4;   % 监督码元数
n = 12;  % 发送码元数

p = mod(length(x), n);
if p ~= 0
    x = [x; zeros(n-p, 1)];
end
x = reshape(x, n, []).';

IR=eye(r);
% IK=eye(k);
P=[1 1 1 1 0 0 0 0
   1 0 0 0 1 1 1 0
   0 1 1 0 1 1 0 1
   0 1 0 1 1 0 1 1];  
Q=P';
H=[P,IR];    % 校验矩阵
% G=[IK ,Q]; % 生成矩阵

% 伴随式
pe = [
    0,0,0,0;
    0,0,0,1;
    0,0,1,0;
    0,1,0,0;
    1,0,0,0;
    0,0,1,1;
    0,1,0,1;
    0,1,1,0;
    0,1,1,1;
    1,0,0,1;
    1,0,1,0;
    1,0,1,1;
    1,1,0,0];
% 伴随式对应的错误图样
SE = [
    0,0,0,0,0,0,0,0,0,0,0,0;
    0,0,0,0,0,0,0,0,0,0,0,1;
    0,0,0,0,0,0,0,0,0,0,1,0;
    0,0,0,0,0,0,0,0,0,1,0,0;
    0,0,0,0,0,0,0,0,1,0,0,0;
    0,0,0,0,0,0,0,1,0,0,0,0;
    0,0,0,0,0,0,1,0,0,0,0,0;
    0,0,0,0,0,1,0,0,0,0,0,0;
    0,0,0,0,1,0,0,0,0,0,0,0;
    0,0,0,1,0,0,0,0,0,0,0,0;
    0,0,1,0,0,0,0,0,0,0,0,0;
    0,1,0,0,0,0,0,0,0,0,0,0;
    1,0,0,0,0,0,0,0,0,0,0,0];
% 生成伴随式
S = mod(x*H.', 2);
len = size(x, 1);
result = zeros(len, n);
for i=1:len
    flag = 1;
    % 根据伴随式确定错误图样并纠错
    for j=1:size(SE, 1)
        if all(S(i,:) == pe(j,:))
            result(i,:) = mod(x(i,:) + SE(j,:), 2);
            flag = 0;
            break;
        end
    end
    % 未找到对应伴随式，错码数大于1，无法纠正错误
    if flag == 1
        result(i,:) = x(i,:);
    end
end
% 提取信息码元
A = result(:,1:k);
% 串行数据
A = A.';
A = A(:);
end

% 卷积码译码
function decode_output = conv_decode(G, k, decode_input)
% (n,k,N)卷积Viterbi译码器
%   g              n个生成矢量排列形成的卷积码生成矩阵:g = [g1;g2;...;gn]
%   k              编码位数
%   decode_input   输入码流

% 约束长度N
N = size(G,2);
% 编码输出位数n
n = size(G,1);
% 网格图的状态数
number_of_states = 2^(k*(N-1));
% 输入矩阵
input = zeros(number_of_states);
% 状态转移矩阵
nextstate = zeros(number_of_states,2^k);
% 输出矩阵
output = zeros(number_of_states,2^k);
%%%% 对各个状态进行运算，得到输入矩阵、状态转移矩阵与输出矩阵 %%%%
for s = 0:number_of_states-1    
    %对前一时刻状态到下一时刻状态之间的各条支路进行运算
    for t = 0:2^k-1         
        % next_state_function函数产生移存器跳转到的下一状态及当前时刻编码器内容
        [next_state,memory_contents] = next_state_function(s,t,N,k);
        % 内容为经由支路编号
        input(s+1,next_state+1) = t;                %输入矩阵
        % 各条支路编码输出
        branch_output = rem(memory_contents*G',2); 
        % 内容为下一时刻状态s
        nextstate(s+1,t+1) = next_state;            %状态转移矩阵
        % 内容为相应分支输出编码
        output(s+1,t+1) = bin2dec(branch_output);	%输出矩阵
    end
end
%%%%%%%%%%%%% 开始译码，得到幸存状态矩阵 %%%%%%%%%%%%%
% 状态度量矩阵
% 第一列为当前时刻各状态的路径度量
% 第二列为下一时刻各状态的路径度量（即更新后的状态度量）
state_metric = zeros(number_of_states,2);
% 网格深度
p = mod(length(decode_input), n);
if p ~= 0
    decode_input = [decode_input; zeros(n - p, 1)];
end
depth_of_trellis = length(decode_input)/n;
decode_input_matrix = reshape(decode_input, n, depth_of_trellis);
% 幸存状态矩阵
survivor_state = zeros(number_of_states,depth_of_trellis+1);
% 各个状态的初始路径度量
for i =1:N-1
    % 网格图从全零状态出发，直到所有状态都有路径到达
    for s = 0:2^(k*(N-i)):number_of_states-1
        %对前一时刻状态到下一时刻状态之间的各条分支进行运算
        for t = 0:2^k-1
            % 分支度量
            branch_metric = 0;
            % 将各分支的编码输出以二进制形式表示
            bin_output = dec2bin(output(s+1,t+1),n);
            for j = 1:n
                % 分支度量的计算
                branch_metric = branch_metric + metric_hard(decode_input_matrix(j,i),bin_output(j));
            end
            % 各个状态路径度量值的更新
            % 下一时刻路径度量=当前时刻路径度量+分支度量
            state_metric(nextstate(s+1,t+1)+1,2) = state_metric(s+1,1) + branch_metric;
            % 幸存路径的存储
            % 一维坐标表示下一时刻状态
            % 二维坐标表示该状态在网格图中的列位置
            % 内容为当前时刻状态
            survivor_state(nextstate(s+1,t+1)+1,i+1) = s;
        end
    end
    % 对所有状态完成一次路径度量值计算后
    % 状态度量矩阵第一列（当前状态路径度量）
    % 与第二列（下一状态路径度量）对换
    % 方便下一时刻继续迭代更新
    state_metric = state_metric(:,2:-1:1);
end
% 各个状态的路径度量更新
for i = N:depth_of_trellis-(N-1)
    % 记录某一状态的路径度量是否更新过
    flag = zeros(1,number_of_states);
    for s = 0:number_of_states-1
       for t = 0:2^k-1
           branch_metric = 0;
           bin_output = dec2bin(output(s+1,t+1),n);
           for j = 1:n
              branch_metric = branch_metric + metric_hard(decode_input_matrix(j,i),bin_output(j));
           end
           % 若某状态的路径度量未被更新
           % 或一次更新后的路径度量大于本次更新的路径度量
           % 则进行各状态路径度量值的更新
           if((state_metric(nextstate(s+1,t+1)+1,2)>state_metric(s+1,1)+branch_metric) || flag(nextstate(s+1,t+1)+1) == 0)
               state_metric(nextstate(s+1,t+1)+1,2) = state_metric(s+1,1)+ branch_metric;
               survivor_state(nextstate(s+1,t+1)+1,i+1) = s;
               % 一次更新后flag置为1
               flag(nextstate(s+1,t+1)+1) = 1;
           end
       end 
    end
    state_metric = state_metric(:,2:-1:1);
end
% 结尾译码：网格图回归全零状态
for i = depth_of_trellis-(N-1)+1:depth_of_trellis
flag = zeros(1,number_of_states);
%上一比特存留的状态数
    last_stop_states = number_of_states/(2^((i-depth_of_trellis+N-2)*k));   
    % 网格图上的各条路径最后都要回到同一个全零状态
    for s = 0:last_stop_states-1
        branch_metric = 0;
        bin_output = dec2bin(output(s+1,1),n);
        for j = 1:n
           branch_metric = branch_metric+ metric_hard(decode_input_matrix(j,i),bin_output(j));
        end
        if((state_metric(nextstate(s+1,1)+1,2) > state_metric(s+1,1)+branch_metric) || flag(nextstate(s+1,1)+1) == 0)
            state_metric(nextstate(s+1,1)+1,2) = state_metric(s+1,1)+ branch_metric;
            survivor_state(nextstate(s+1,1)+1,i+1) = s;
            flag(nextstate(s+1,1)+1) = 1;
        end
    end
    state_metric = state_metric(:,2:-1:1);
end
%%%%%% 根据幸存状态矩阵开始逐步向前回溯，得到译码输出 %%%%%%%
sequence = zeros(1,depth_of_trellis+1);
% 逐步向前回溯
for i = 1:depth_of_trellis
   sequence(1,depth_of_trellis+1-i) = survivor_state(sequence(1,depth_of_trellis+2-i)+1,depth_of_trellis+2-i);
end
% 译码输出
decode_output_matrix = zeros(k,depth_of_trellis-N);
for i = 1:depth_of_trellis-N
    % 由输入矩阵得到经由支路编号
    dec_decode_output = input(sequence(1,i)+1,sequence(1,i+1)+1);
    % 将支路编号转为二进制码元，即为相应的译码输出
    bin_decode_output = dec2bin(dec_decode_output,k);
    % 将每一分支的译码输出存入译码输出矩阵中
    decode_output_matrix(:,i) = bin_decode_output(k:-1:1)';
end
% 重新排列译码输出序列
decode_output = reshape(decode_output_matrix,1,k*(depth_of_trellis-N)).';
end

function [next_state, memory_contents] = next_state_function( current_state,input,L,k )
%（n,k,L）编码,寄存器下一时刻状态跳转及当前时刻内容
%   current_state    当前寄存器状态(DEC)
%   input            编码输入（DEC），即分支编号
%   L                约束长度
%   k                编码位数
%   next_state       下一时刻寄存器状态(DEC)
%   memory_contents  当前时刻寄存器内容（BIN）
bin_current_state = dec2bin(current_state,k*(L-1));
bin_input = dec2bin(input,k);
bin_next_state = [bin_input,bin_current_state(1:k*(L-2))];
next_state = bin2dec(bin_next_state);
memory_contents = [bin_input,bin_current_state];
end

function distance = metric_hard(x, y)
% 硬判决与汉明距测量
if x == y
    distance = 0;
else
    distance = 1;
end
end

function y = dec2bin(x, L)
% 十进制数转为二进制数
%   x  十进制数
%   y  二进制数
%   L  二进制数长度
y = zeros(1,L);
i = 1;
while x>=0 && i<=L
    y(i) = rem(x,2);
    x = (x-y(i))/2;
    i = i+1;
end
y = y(L:-1:1);
end

function y = bin2dec(x)
% 二进制数转为十进制数
%   x  二进制数
%   y  十进制数
L = length(x);
y = (L-1:-1:0);
y = 2.^y;
y = x*y';
end