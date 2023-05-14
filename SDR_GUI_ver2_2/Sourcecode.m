function info = Sourcecode(type, text_max_len, img_size, fs, T)
% text_max_len = 8e3;    % 文本最长限制
% img_size = [300, 300]; % 图片大小
% fs = 4e3;              % 音频采样率
% T = 2;                 % 音频录制时长
if type == 1
    type_info = [0,0,0,1,1,0,0,0].';
    info = get_text(text_max_len); % 文本信息
elseif type == 2
    type_info = [0,0,1,0,0,1,0,0].';
    info = get_img(img_size);      % 图像信息
elseif type == 3
    type_info = [0,1,0,0,0,0,1,0].';
    info = get_voice(fs, T);       % 音频信息
end
info = [type_info;info];
end

function text_code = get_text(text_max_len)
[filename,pathname] = uigetfile('*.txt','请选择需要发送的文本文件', 'MultiSelect', 'off');
if isequal(filename, 0)
    text_code = [];       % 未读取到文件返回空数组
    return
end
pathfile = fullfile(pathname, filename);
msgStr = fileread(pathfile);

native = unicode2native(msgStr);		  % 转成本地编码
% 限制文本长度
if length(native) > text_max_len
    native = native(1:text_max_len);
end

len = length(native);
b = mod(len, 256);
a = (len - b)/256;
msgBin = double([a, b, native].');

% 霍夫曼编码
text_code = myhuffmanenco(msgBin);
end

function img_code = get_img(img_size)
[filename,pathname] = uigetfile({'*.jpg';'*.png'},'请选择需要发送的图片', 'MultiSelect', 'off');
if isequal(filename,0)
    img_code = [];         % 未读取到文件返回空数组
    return
end
pathfile = fullfile(pathname,filename);
I = imread(pathfile);
I = imresize(I, img_size);  % resize图片大小

if size(I, 3) == 3
    % 使用k-means聚类进行压缩
    k = 256;               % 集群数
    max_step = 256;        % 最大迭代次数
    [updatedMeans, currClusters] = k_means_segment(double(I)/255, k, max_step);
    updatedMeans = double(uint8(255*updatedMeans));
    % I的大小和集群信息和索引
    size(I)
    info = [size(I).'; reshape(updatedMeans.', [], 1); (currClusters-1).'];
else
    % I的大小和灰度信息
    info = [size(I), 1, reshape(I, 1, [])].';
end

% 霍夫曼编码
img_code=myhuffmanenco(double(info));
end

function [updatedMeans, currClusters] = k_means_segment(image_values, k, max_step)
% params:
% image_values =  r x c x ch [float]
% k = int
% initial_means = k x n [float]] or None
% 
% returns:
% updated_image_values = r x c x ch [float]
[r, c, ch] = size(image_values);

% 创建一个k_means_step可以处理的矩阵
dataPoints = reshape(image_values, r * c, ch);
% 初始化聚类均值
startMeans = get_initial_means(dataPoints, k);

currClusters = zeros(1, r * c);  % 集群  
% 循环直到收敛
for i = 1:max_step
    prevClusters = currClusters;
    [updatedMeans, currClusters] = k_means_step(dataPoints, k, startMeans);
    startMeans = updatedMeans;
    if all(currClusters == prevClusters) % 收敛时结束循环
        break
    end
end
end

% 初始化k个类
function initial_means = get_initial_means(array, k)
% params:
% array = m x n [float]| datapoints x features
% k = int
% 
% returns:
% initial_means = k x n [float]
rowrank = randperm(size(array, 1));        % size获得a的行数，randperm打乱各行的顺序
initial_means = array(rowrank(1:k), :);    % 按照rowrank重新排列各行, 选择k个点
end

% 单次更新
function [new_means, clusters] = k_means_step(X, k, means)
% params:
% X = m x n [float]| pixels x features (already flattened)
% k = int
% means = k x n [float]
% 
% returns:
% new_means = k x n [float]
% clusters = m [float]
[m, n] = size(X);

% 计算行向量的二范数(X中每个行向量与mean的距离)
eucDist = zeros(m, k);
for i = 1:k
    eucDist(:, i) = sqrt(sum((X - means(i, :)).^2, 2));
end

% 进行聚类，X中每个行向量与mean的最短距离的索引(1 - k)，即每个行向量分到的类
[~, clusters] = min(eucDist.') ;

% 计算每个类的新均值
new_means = zeros(k, n);
for i = 1:k
    points = X(clusters == i, :);
    if ~isempty(points)
        new_means(i, :) = mean(points);
    else
        new_means(i, :) = ones(1, n) * 0.5;
    end
end
end

function code = myhuffmanenco(data)%输入向量，返回信源编码的最终结果
    max_n = max(data);
    p = zeros(max_n, 1);
    for i = 0:max_n
        p(i+1) = length(find(data == i));
    end
    p = p/sum(p);
    a = 0:max_n;
    dict = huffmandict(a, p);
    encode = huffmanenco(data, dict).';
    % 考虑怎么把dict元胞数组加入到序列中,8bit,8bit,?，（a,对应矩阵长度，矩阵）
    code = [encodedict(dict), encode];%最终输入到下一层的结果
    code = code';%转为列向量
end

function dicode = encodedict(dict)%返回字典转换的01向量,最大长度为6万多，我们取20bit表示长度,再取10bit作为元胞数组行数
    [row, ~] = size(dict);
    dicode = [];
    num = row*10*2;
    for i = 1:row
        n = dec2bin(dict{i,1},10);
        dicode = [dicode, n];
        k = length(dict{i,2});
        num = num+k;
        n = dec2bin(k,10);
        dicode = [dicode, n];
        dicode = [dicode,dict{i,2}];
    end
    num = num+10;
    c = dec2bin(row,10);
    b = dec2bin(num,20);
    dicode = [b,c,dicode];
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

function wave_code = get_voice(Fs, T)
myVoice = audiorecorder(Fs, 8, 2, 0);   % 创建录制对象
recordblocking(myVoice, T);             % 录制Ts
y = getaudiodata(myVoice);              % 获取声道数据

sfd = de2bi([Fs/1e3; T], 8).';          % 采样频率和录制时长转成8bit
wave_code = PCM_A(y(:, 1));             % 选择左声道编码
wave_code = [sfd(:); wave_code];
end

% PCM-A律
function z = PCM_A(x) 
% 归一化
maxz = max(x);
z = x/maxz;
% 量化
A = 87.6;
y = quantificat(z, A);
% 编码
z = a_pcm(y);
% 串行数据
z = z.';
z = z(:);
end

% 量化
function y = quantificat(x, A)  
a = 1/A;  % 0.0114
p = 1 + log(A);
abs_x = abs(x);        % 输入信号的绝对值
flag = x./(abs_x+eps); % 量化信号的符号
% 对数映射
y = ((abs_x < a) .* abs_x*A +  (abs_x >= a) .* (1+log(abs_x*A))) .* flag/p;
end

% 编码
function z = a_pcm(y) 
len = length(y);
z = zeros(len, 8);
parcode = 1:8;             % 段落位置序号
stalevel = 2.^(parcode+2); % 起始电平
zhishu = parcode-2;
zhishu(1) = 0;
detas = 2.^zhishu;         %量化间隔
% 极性+段落码
for i=1:len
    I=y(i)*2048;    % 转换为量化单位
    if I>0
        z(i,1) = 1;   % 极性码-正-1
    else
        z(i,1) = 0;   % 极性码-负-0
        I=-I;
    end
    % 段落码
    if I > 1024
        z(i,2) = 1;z(i,3) = 1;z(i,4) = 1; 
    elseif I > 512
        z(i,2) = 1;z(i,3) = 1;z(i,4) = 0; 
    elseif I > 256
        z(i,2) = 1;z(i,3) = 0;z(i,4) = 1; 
    elseif I > 128
        z(i,2) = 1;z(i,3) = 0;z(i,4) = 0; 
    elseif I > 64
        z(i,2) = 0;z(i,3) = 1;z(i,4) = 1;
    elseif I > 32
        z(i,2) = 0;z(i,3) = 1;z(i,4) = 0;
    elseif I > 16
        z(i,2) = 0;z(i,3) = 0;z(i,4) = 1;
    else
        z(i,2) = 0;z(i,3) = 0;z(i,4) = 0;
    end
    % 段内码
    idx=z(i,2)*4+z(i,3)*2+z(i,4)+1;  % 段落位置序号
    slevel = stalevel(idx);          % 该段落起始电平
    deta = detas(idx);               % 该段落的量化间隔 
    level = slevel + (0:15) * deta;
    if I > level(16)
        z(i,5) = 1;z(i,6) = 1;z(i,7) = 1;z(i,8) = 1;
    elseif I > level(15)
        z(i,5) = 1;z(i,6) = 1;z(i,7) = 1;z(i,8) = 0;
    elseif I > level(14)
        z(i,5) = 1;z(i,6) = 1;z(i,7) = 0;z(i,8) = 1;
    elseif I > level(13)
        z(i,5) = 1;z(i,6) = 1;z(i,7) = 0;z(i,8) = 0;
    elseif I > level(12)
        z(i,5) = 1;z(i,6) = 0;z(i,7) = 1;z(i,8) = 1;
    elseif I > level(11)
        z(i,5) = 1;z(i,6) = 0;z(i,7) = 1;z(i,8) = 0;
    elseif I > level(10)
        z(i,5) = 1;z(i,6) = 0;z(i,7) = 0;z(i,8) = 1;
    elseif I > level(9)
        z(i,5) = 1;z(i,6) = 0;z(i,7) = 0;z(i,8) = 0;
    elseif I > level(8)
        z(i,5) = 0;z(i,6) = 1;z(i,7) = 1;z(i,8) = 1;
    elseif I > level(7)
        z(i,5) = 0;z(i,6) = 1;z(i,7) = 1;z(i,8) = 0;
    elseif I > level(6)
        z(i,5) = 0;z(i,6) = 1;z(i,7) = 0;z(i,8) = 1;
    elseif I > level(5)
        z(i,5) = 0;z(i,6) = 1;z(i,7) = 0;z(i,8) = 0;
    elseif I > level(4)
        z(i,5) = 0;z(i,6) = 0;z(i,7) = 1;z(i,8) = 1;
    elseif I > level(3)
        z(i,5) = 0;z(i,6) = 0;z(i,7) = 1;z(i,8) = 0;
    elseif I > level(2)
        z(i,5) = 0;z(i,6) = 0;z(i,7) = 0;z(i,8) = 1;
    else
        z(i,5) = 0;z(i,6) = 0;z(i,7) = 0;z(i,8) = 0;
    end
end
end