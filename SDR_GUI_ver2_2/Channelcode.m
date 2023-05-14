function frame_code = Channelcode(x, type)  
G = [1,0,1;1,1,1];   % 卷积码生成多项式

% 信道编码
if type == 1
    type_info = [0,0,1,1,1,1,0,0].';
    chcode = hamming_code(x); % 线性分组码
elseif type == 2
    type_info = [1,1,0,0,0,0,1,1].';
    chcode = conv_code(x, G); % 卷积码
end
chcode = [type_info;chcode];

% 交织
scramble_N = ceil(sqrt(length(chcode)));                          % 交织矩阵深度
scrambledcode = [chcode ; zeros(scramble_N^2-length(chcode),1)];  % 补0
scrambledcode = reshape(scrambledcode,[scramble_N,scramble_N]);   % 重新分组
scrambledcode = reshape(scrambledcode.',[scramble_N^2,1]);        % 串行数据
chcode = scrambledcode;

% 组成数据帧
sfd = [0; 1; 0; 1; 0; 1; 1; 1];
pre_core = [  1; 1; 0; 0;
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
pre = repmat(pre_core,100,1);   % 前导码
len = scramble_N^2;             % 帧长
c = mod(len, 65536);
a = (len - c)/65536;
len = c;
b = mod(len, 256);
c = (len - b)/256;
len_type = de2bi([a;c;b], 8).'; % 帧长字段
frame_code = [pre; sfd; len_type(:); chcode];
end

% 信道编码-线性分组码((12,8)海明码)
function A = hamming_code(x)  
%分组码各部分长度
k = 8;   % 信息码元数
% r = 4; % 监督码元数
% n = 12;  % 发送码元数

% IR=eye(r);
IK=eye(k);
P=[1 1 1 1 0 0 0 0
   1 0 0 0 1 1 1 0
   0 1 1 0 1 1 0 1
   0 1 0 1 1 0 1 1];  
Q=P';
% H=[P,IR]; %监督矩阵
G=[IK ,Q];  %生成矩阵

p = mod(length(x), k);
if p ~= 0
    x = [x; zeros(k-p,1)];
end
x = reshape(x, k, []).';
% len行-n列
A = x*G;   
% 模2加
A = mod(A, 2);
% 串行数据
A = A.';
A = A(:);
end

% 信道编码-卷积码
function C = conv_code(m, G)  
% 原始序列m
% 生成矢量G
len = length(m);
k = 1;             % 表示每次对k个码元进行编码
[n, N] = size(G);  % k个输入码元拥有n个输出，N表示每次监督的输入码元数

% 生成序列C
C = zeros(n/k*len, 1);
% 在头尾补0，方便卷积输出和寄存器清洗
m_add0 = [zeros(1,N-1), m.', zeros(1,N+1)];

% 循环每一位输入符号，获得输出矩阵
C_reg = fliplr(m_add0(1,1:N));
for i =1:len+N
    %生成每一位输入符号的n位输出
    C(n*i-(n-1):n*i) =  mod(C_reg*G.',2);
    
    %更新寄存器序列+待输出符号（共N个符号）
    C_reg = circshift(C_reg, [0, 1]);
    C_reg(1) = m_add0(i+N);   % 添加新符号
end
end