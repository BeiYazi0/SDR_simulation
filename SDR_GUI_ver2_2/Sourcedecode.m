function [type, info] = Sourcedecode(x)
p = mod(length(x), 8);
if p ~= 0
    x = [x; zeros(8-p, 1)];
end

type_info = x(1:8);
type = decode_type(type_info);

if type == 1
    info = bits_to_str(x(9:end));
elseif type == 2
    info = img_decode(x(9:end));
elseif type == 3
    info = audio_decode(x(9:end));
end
end

% 确定信源格式
function type = decode_type(type_info)
text_pss = length(find(type_info ~= [0,0,0,1,1,0,0,0].'));
img_pss = length(find(type_info ~= [0,0,1,0,0,1,0,0].'));
audio_pss = length(find(type_info ~= [0,1,0,0,0,0,1,0].'));
pss = [text_pss; img_pss; audio_pss];
% 根据码距确定信源格式
[~, type] = min(pss);
end

% 文本信息解码
function msgStr = bits_to_str(msg_bits)
% 霍夫曼解码
native = myhuffmandeco(msg_bits);

len = native(1)*256 + native(2);
msgStr = native2unicode(native(3:len+2)).'; % 转成unicode
end 

% 图片信息解码
function I = img_decode(x)  
% 霍夫曼译码
info = myhuffmandeco(x);

h = info(1);
w = info(2);
channel = info(3);

info = [info;zeros(channel*w*h+3-length(info), 1)];
if channel == 3
    updatedMeans = reshape(info(4:771), 3, 256).';
    currClusters = info(772:771+w*h) + 1;

    % 将原始值替换为相应的集群值并重构图像
    updated_image_values = updatedMeans(currClusters, :);
    updated_image_values = reshape(updated_image_values, h, w, channel);
    I = uint8(updated_image_values);
else
    I=uint8(reshape(info(4:h*w*channel+3), h, w, channel));
end
end

function data = myhuffmandeco(code)%返回解码结果
    code = code'; % 转为行向量
    [dict, k]=decodedict(code);
    code(1:k)=[]; % 删除字典占的位置
    data = huffmandeco(code,dict).';
end 

function [dict,k]=decodedict(code)
    num = bin2dec(code(1:20));
    code(1:20) = [];
    k = num+20;
    %开始生成元胞数组
    row = bin2dec(code(1:10));
    code(1:10) = [];
    num = num-10;
    dict = {};
    for i=1:row
        dict{i,1} = bin2dec(code(1:10));
        num = num-10;
        code(1:10) = [];
        h = bin2dec(code(1:10));
        num = num-10;
        code(1:10) = [];
        dict{i,2} = code(1:h);
        num=num-h;
        code(1:h) = [];
        if num == 0
            break;
        end
    end  
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

% 音频信息解码
function audio = audio_decode(x) 
x = reshape(x, 8 ,[]).';
audio.Fs = bi2de(x(1,:)) * 1e3;
audio.T = bi2de(x(2,:));
len = audio.Fs * audio.T;
x = x(3:len+2,:);

len = length(x);
z = zeros(1, len);
parcode = 1:8;             % 段落位置序号
stalevel = 2.^(parcode+2); % 起始电平
zhishu = parcode-2;
zhishu(1) = 0;
detas = 2.^zhishu;         % 量化间隔
for i=1:len
    idx = x(i,2)*4+x(i,3)*2+x(i,4)+1;            % 该段落位置序号
    slevel = stalevel(idx);                      % 该段落起始电平
    deta = detas(idx);                           % 该段落量化间隔
    secode = x(i,5)*8+x(i,6)*4+x(i,7)*2+x(i,8);  % 段内位置序号
    I = slevel+secode*deta+deta/2;               % 译码电平
    z(i) = I/2048;                               % 实际电平
    if x(i,1)==0
        z(i) = -z(i);
    end
end

%还原量化前电平
audio.wave = quanreduction(z);
end
        
% 还原量化前信号
function x = quanreduction(y)  
A = 87.6;
a = 1/(1+log(A));
p = 1+log(A);
abs_y = abs(y);        % 输入信号的绝对值
flag = y./(abs_y+eps); % 还原信号的符号
x = ((abs_y < a) .* abs_y*p +  (abs_y >= a) .* exp(abs_y*p-1)) .* flag/A;
end