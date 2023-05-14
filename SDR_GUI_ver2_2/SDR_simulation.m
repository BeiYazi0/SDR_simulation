function varargout = SDR_simulation(varargin)
% SDR_SIMULATION MATLAB code for SDR_simulation.fig
%      SDR_SIMULATION, by itself, creates a new SDR_SIMULATION or raises the existing
%      singleton*.
%
%      H = SDR_SIMULATION returns the handle to a new SDR_SIMULATION or the handle to
%      the existing singleton*.
%
%      SDR_SIMULATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SDR_SIMULATION.M with the given input arguments.
%
%      SDR_SIMULATION('Property','Value',...) creates a new SDR_SIMULATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SDR_simulation_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SDR_simulation_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SDR_simulation

% Last Modified by GUIDE v2.5 04-Apr-2023 15:18:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SDR_simulation_OpeningFcn, ...
                   'gui_OutputFcn',  @SDR_simulation_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SDR_simulation is made visible.
function SDR_simulation_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SDR_simulation (see VARARGIN)

% Choose default command line output for SDR_simulation
handles.output = hObject;

% 信源设定
handles.text_max_len = 8e3;   % 文本最长限制
handles.img_size = [120, 80]; % 图片大小
handles.send_fs = 4e3;        % 音频采样率
handles.T = 2;                % 音频录制时长

% 信源编码标记
handles.srcflag = false(1, 1);
% 仿真标记
handles.simflag = false(1, 1);

% 信道译码标记
handles.decodeflag = false(1, 1);

% 信源
handles.channel_data1 = [];
handles.channel_data2 = [];
handles.channel_data3 = [];

% 信道编码数据
handles.encode_data1 = [];
handles.encode_data2 = [];
handles.encode_data3 = [];

% 仿真输出
handles.simout_data1 = [];
handles.simout_data2 = [];
handles.simout_data3 = [];

% 信道译码结果
handles.decode_data1 = [];
handles.decode_data2 = [];
handles.decode_data3 = [];

% 信源译码结果
handles.sink_data1.type = 0;
handles.sink_data1.value = [];
handles.sink_data2.type = 0;
handles.sink_data2.value = [];
handles.sink_data3.type = 0;
handles.sink_data3.value = [];

% 误码率
handles.bit_error_rate1 = 0;
handles.bit_error_rate2 = 0;
handles.bit_error_rate3 = 0;

% 音频
handles.wave = [];
handles.Fs = 0;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SDR_simulation wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SDR_simulation_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in channel_select.
function channel_select_Callback(hObject, eventdata, handles)
% hObject    handle to channel_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns channel_select contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_select


% --- Executes during object creation, after setting all properties.
function channel_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in info_type_select.
function info_type_select_Callback(hObject, eventdata, handles)
% hObject    handle to info_type_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

% 确定信源格式
types = get(handles.info_type_select, 'String');         % 获取信源格式列表
selected_index = get(handles.info_type_select, 'Value'); % 选择的索引
type = cellstr(types(selected_index));                   % 信源格式
if strcmp(type, '文本')
    text_show = '选择文本';
elseif strcmp(type, '图像')
    text_show = '选择图片';
elseif strcmp(type, '音频')
    text_show = '开始录制';
end

% 设置按钮文字
set(handles.info_get, 'String', text_show);

% Update handles structure
guidata(hObject, handles);
% Hints: contents = cellstr(get(hObject,'String')) returns info_type_select contents as cell array
%        contents{get(hObject,'Value')} returns selected item from info_type_select


% --- Executes during object creation, after setting all properties.
function info_type_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to info_type_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in modulation_select.
function modulation_select_Callback(hObject, eventdata, handles)
% hObject    handle to modulation_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns modulation_select contents as cell array
%        contents{get(hObject,'Value')} returns selected item from modulation_select


% --- Executes during object creation, after setting all properties.
function modulation_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to modulation_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in info_get.
function info_get_Callback(hObject, eventdata, handles)
% hObject    handle to info_get (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

if handles.srcflag
    warndlg('正在对信源进行编码，请稍后', '提示');
    return
end

handles.srcflag = ~handles.srcflag;
% Update handles structure
guidata(hObject, handles);

% 获取信源格式
text_show = get(handles.info_get, 'String');
if strcmp(text_show, '选择文本')
     type = 1;
elseif strcmp(text_show, '选择图片')
     type = 2;
elseif strcmp(text_show, '开始录制')
     type = 3;
else 
    warndlg('载入信息中，请稍后', '提示');
    return
end

% 信源编码
if type == 3
    set(handles.info_get, 'String', '录制中...');
end
info = Sourcecode(type, handles.text_max_len, handles.img_size, handles.send_fs, handles.T);
if type == 3
    set(handles.info_get, 'String', '开始录制');
end

% 获取通道数
channel = get(handles.channel_select, 'Value');  % 通道数

% 载入数据
if channel == 1
    handles.channel_data1 = info;
elseif channel == 2
    handles.channel_data2 = info;
elseif channel == 3
    handles.channel_data3 = info;
end

if isempty(info)
    warndlg('载入信息失败', '提示');
else
    warndlg('载入信息成功', '提示');
end

handles.srcflag = ~handles.srcflag;
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in simulation.
function simulation_Callback(hObject, eventdata, handles)
% hObject    handle to simulation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

if handles.simflag
    warndlg('正在仿真中，请稍后', '提示');
    return
end

handles.simflag = ~handles.simflag;
% Update handles structure
guidata(hObject, handles);

% 确定调制方式
modulations = get(handles.modulation_select, 'String');     % 获取调制方式列表
selected_index = get(handles.modulation_select, 'Value');   % 选择的索引
modulation = cellstr(modulations(selected_index));          % 调制方式
if strcmp(modulation, 'QPSK')
    sim_name = 'QPSK';
    awgn_path = 'QPSK/QPSK/信道/AWGN Channel';
elseif strcmp(modulation, '16QAM')
    sim_name = 'QAM';
    awgn_path = 'QAM/my16QAM/16QAM_core/AWGN Channel';
end

% 打开模型&设置参数
open_system(sim_name);
SNR =  get(handles.SNRdb, 'String'); % 获取信噪比
set_param(awgn_path, 'SNRdB', SNR);  % 设置信噪比
% set_param([sim_name, '/Signal From Workspace'], 'X', 'input'); % 设置输入

% 经过信道编码的数据
simin = [2*ones(1000,1); handles.encode_data1; 2*ones(1000,1)];

% 开始仿真
warning off
options = simset('SrcWorkspace', 'current');                % 设置仿真空间
Ts = get_param([sim_name, '/Signal From Workspace'], 'Ts'); % 获取采样间隔
Ts = str2double(Ts);
endtime = ceil(length(simin)*Ts);                           % 计算仿真时长
out = sim(sim_name, [0 endtime], options);                  % 获取仿真输出
handles.simout_data1 = double(out.yout);
handles.simout_data2 = zeros(size(handles.simout_data1));
handles.simout_data3 = zeros(size(handles.simout_data1));

if get(handles.close_check, 'Value') == 1
    close_system(sim_name, 0);
end

handles.simflag = ~handles.simflag;
handles.decodeflag = false(1,1);
% Update handles structure
guidata(hObject, handles);



function SNRdb_Callback(hObject, eventdata, handles)
% hObject    handle to SNRdb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SNRdb as text
%        str2double(get(hObject,'String')) returns contents of SNRdb as a double


% --- Executes during object creation, after setting all properties.
function SNRdb_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SNRdb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Channel_code_select.
function Channel_code_select_Callback(hObject, eventdata, handles)
% hObject    handle to Channel_code_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Channel_code_select contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Channel_code_select


% --- Executes during object creation, after setting all properties.
function Channel_code_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Channel_code_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox3


% --- Executes on selection change in popupmenu5.
function popupmenu5_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu5


% --- Executes during object creation, after setting all properties.
function popupmenu5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1


% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton2


% --- Executes on button press in Channelcode.
function Channelcode_Callback(hObject, eventdata, handles)
% hObject    handle to Channelcode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

% 确定信道编码方式
encodes = get(handles.Channel_code_select, 'String');       % 获取信道编码方式列表
selected_index = get(handles.Channel_code_select, 'Value'); % 选择的索引
encode_type = cellstr(encodes(selected_index));             % 信道编码方式
if strcmp(encode_type, '线性分组码')
    type = 1;
elseif strcmp(encode_type, '卷积码')
    type = 2;
end

flag = 0;
% 信道编码%加扰码%组成数据帧
if get(handles.channel1, 'Value') == 1
    if isempty(handles.channel_data1)
        warndlg('请先对通道1进行信源编码', '提示');
        return
    end
    handles.encode_data1 = Channelcode(handles.channel_data1, type);
    flag = 1;
end
if get(handles.channel2, 'Value') == 1
    if isempty(handles.channel_data2)
        warndlg('请先对通道2进行信源编码', '提示');
        return
    end
    handles.encode_data2 = Channelcode(handles.channel_data2, type);
    flag = 1;
end
if get(handles.channel3, 'Value') == 1
    if isempty(handles.channel_data3)
        warndlg('请先对通道3进行信源编码', '提示');
        return
    end
    handles.encode_data3 = Channelcode(handles.channel_data3, type);
    flag = 1;
end

if flag == 0
    warndlg('请至少选择一个通道', '提示');
else
    warndlg(['已选通道信道编码成功，编码方式为', encode_type], '提示');
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in close_check.
function close_check_Callback(hObject, eventdata, handles)
% hObject    handle to close_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of close_check

% 计算误码率
function ber = errorcode_count(orgin_info, decode_info)
len = min(length(orgin_info), length(decode_info));
error = length(find(orgin_info(1:len) ~= decode_info(1:len)));
ber = error/len*100;

% --- Executes on button press in Channeldecode.
function Channeldecode_Callback(hObject, eventdata, handles)
% hObject    handle to Channeldecode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

if isempty(handles.simout_data1)
    warndlg('请先进行仿真', '提示');
    return
end

% 信道译码
handles.decode_data1 = Channeldecode(handles.simout_data1);
handles.decode_data2 = Channeldecode(handles.simout_data2);
handles.decode_data3 = Channeldecode(handles.simout_data3);

% 计算误码率
if ~isempty(handles.decode_data1)
    handles.bit_error_rate1 = errorcode_count(handles.channel_data1, handles.decode_data1);
end
if ~isempty(handles.decode_data2)
    handles.bit_error_rate2 = errorcode_count(handles.channel_data2, handles.decode_data2);
end
if ~isempty(handles.decode_data3)
    handles.bit_error_rate3 = errorcode_count(handles.channel_data3, handles.decode_data3);
end

warndlg('信道译码成功', '提示');
handles.decodeflag = true(1,1);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Sourcedecode.
function Sourcedecode_Callback(hObject, eventdata, handles)
% hObject    handle to Sourcedecode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

if ~handles.decodeflag
    warndlg('请先进行信道译码', '提示');
    return
end

% 信源译码
if isempty(handles.decode_data1)
    handles.sink_data1.type = 0;
    handles.sink_data1.value = [];
else
    [handles.sink_data1.type, handles.sink_data1.value] = Sourcedecode(handles.decode_data1);
end
if isempty(handles.decode_data2)
    handles.sink_data2.type = 0;
    handles.sink_data2.value = [];
else
    [handles.sink_data2.type, handles.sink_data2.value] = Sourcedecode(handles.decode_data2);
end
if isempty(handles.decode_data3)
    handles.sink_data3.type = 0;
    handles.sink_data3.value = [];
else
    [handles.sink_data3.type, handles.sink_data3.value] = Sourcedecode(handles.decode_data3);
end

warndlg('信源译码成功', '提示');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in info_reciver.
function info_reciver_Callback(hObject, eventdata, handles)
% hObject    handle to info_reciver (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

set(handles.reciver, 'Visible', 'on');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in reciver_close.
function reciver_close_Callback(hObject, eventdata, handles)
% hObject    handle to reciver_close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

set(handles.sink1, 'Value', 0);
set(handles.sink2, 'Value', 0);
set(handles.sink3, 'Value', 0);
set(handles.reciver_text, 'Visible', 'off');
axes(handles.reciver_img); 
cla reset;
set(handles.reciver_img, 'Visible', 'off');
handles.wave = [];
handles.Fs = 0;
set(handles.wave_sound, 'Visible', 'off');
set(handles.clear_sound, 'Visible', 'off');

set(handles.reciver_type, 'String', '信息格式');
set(handles.reciver_ber, 'String', '误码率');

set(handles.reciver, 'Visible', 'off');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in sink1.
function sink1_Callback(hObject, eventdata, handles)
% hObject    handle to sink1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

set(handles.sink2, 'Value', 0);
set(handles.sink3, 'Value', 0);
set(handles.reciver_text, 'Visible', 'off');
axes(handles.reciver_img); 
cla reset;
set(handles.reciver_img, 'Visible', 'off');
handles.wave = [];
handles.Fs = 0;
set(handles.wave_sound, 'Visible', 'off');
set(handles.clear_sound, 'Visible', 'off');

if get(handles.sink1, 'Value') == 0
    set(handles.reciver_type, 'String', '信息格式');
    set(handles.reciver_ber, 'String', '误码率');
    return
end


% 展示通道1的信息
if handles.sink_data1.type == 0
    reciver_type_text = '未接收信息';
elseif handles.sink_data1.type == 1
    reciver_type_text = '信息格式：文本';
    set(handles.reciver_text, 'Visible', 'on');
    set(handles.reciver_text, 'String', handles.sink_data1.value);
elseif handles.sink_data1.type == 2
    reciver_type_text = '信息格式：图像';
    axes(handles.reciver_img);
    imshow(handles.sink_data1.value);
elseif handles.sink_data1.type == 3
    reciver_type_text = '信息格式：音频';
    handles.wave = handles.sink_data1.value.wave;
    handles.Fs = handles.sink_data1.value.Fs;
    set(handles.wave_sound, 'Visible', 'on');
    set(handles.clear_sound, 'Visible', 'on');
end
set(handles.reciver_type, 'String', reciver_type_text);
set(handles.reciver_ber, 'String', ['误码率：', num2str(handles.bit_error_rate1), '%']);

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of sink1


% --- Executes on button press in sink2.
function sink2_Callback(hObject, eventdata, handles)
% hObject    handle to sink2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

set(handles.sink1, 'Value', 0);
set(handles.sink3, 'Value', 0);
set(handles.reciver_text, 'Visible', 'off');
axes(handles.reciver_img); 
cla reset;
set(handles.reciver_img, 'Visible', 'off');
handles.wave = [];
handles.Fs = 0;
set(handles.wave_sound, 'Visible', 'off');
set(handles.clear_sound, 'Visible', 'off');

if get(handles.sink2, 'Value') == 0
    set(handles.reciver_type, 'String', '信息格式');
    set(handles.reciver_ber, 'String', '误码率');
    return
end

% 展示通道2的信息
if handles.sink_data2.type == 0
    reciver_type_text = '未接收信息';
elseif handles.sink_data2.type == 1
    reciver_type_text = '信息格式：文本';
    set(handles.reciver_text, 'Visible', 'on');
    set(handles.reciver_text, 'String', handles.sink_data2.value);
elseif handles.sink_data2.type == 2
    reciver_type_text = '信息格式：图像';
    axes(handles.reciver_img);
    imshow(handles.sink_data2.value);
elseif handles.sink_data2.type == 3
    reciver_type_text = '信息格式：音频';
    handles.wave = handles.sink_data2.value.wave;
    handles.Fs = handles.sink_data2.value.Fs;
    set(handles.wave_sound, 'Visible', 'on');
    set(handles.clear_sound, 'Visible', 'on');
end
set(handles.reciver_type, 'String', reciver_type_text);
set(handles.reciver_ber, 'String', ['误码率：', num2str(handles.bit_error_rate2), '%']);

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of sink2


% --- Executes on button press in sink3.
function sink3_Callback(hObject, eventdata, handles)
% hObject    handle to sink3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

set(handles.sink1, 'Value', 0);
set(handles.sink2, 'Value', 0);
set(handles.reciver_text, 'Visible', 'off');
axes(handles.reciver_img); 
cla reset;
set(handles.reciver_img, 'Visible', 'off');
handles.wave = [];
handles.Fs = 0;
set(handles.wave_sound, 'Visible', 'off');
set(handles.clear_sound, 'Visible', 'off');

if get(handles.sink3, 'Value') == 0
    set(handles.reciver_type, 'String', '信息格式');
    set(handles.reciver_ber, 'String', '误码率');
    return
end

% 展示通道3的信息
if handles.sink_data3.type == 0
    reciver_type_text = '未接收信息';
elseif handles.sink_data3.type == 1
    reciver_type_text = '信息格式：文本';
    set(handles.reciver_text, 'Visible', 'on');
    set(handles.reciver_text, 'String', handles.sink_data3.value);
elseif handles.sink_data3.type == 2
    reciver_type_text = '信息格式：图像';
    axes(handles.reciver_img);
    imshow(handles.sink_data3.value);
elseif handles.sink_data1.type == 3
    reciver_type_text = '信息格式：音频';
    handles.wave = handles.sink_data3.value.wave;
    handles.Fs = handles.sink_data3.value.Fs;
    set(handles.wave_sound, 'Visible', 'on');
    set(handles.clear_sound, 'Visible', 'on');
end
set(handles.reciver_type, 'String', reciver_type_text);
set(handles.reciver_ber, 'String', ['误码率：', num2str(handles.bit_error_rate3), '%']);

% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of sink3


% --- Executes on button press in wave_sound.
function wave_sound_Callback(hObject, eventdata, handles)
% hObject    handle to wave_sound (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

sound(handles.wave, handles.Fs);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in clear_sound.
function clear_sound_Callback(hObject, eventdata, handles)
% hObject    handle to clear_sound (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

clear sound

% Update handles structure
guidata(hObject, handles);



function text_len_Callback(hObject, eventdata, handles)
% hObject    handle to text_len (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_len as text
%        str2double(get(hObject,'String')) returns contents of text_len as a double


% --- Executes during object creation, after setting all properties.
function text_len_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_len (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function img_h_Callback(hObject, eventdata, handles)
% hObject    handle to img_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of img_h as text
%        str2double(get(hObject,'String')) returns contents of img_h as a double


% --- Executes during object creation, after setting all properties.
function img_h_CreateFcn(hObject, eventdata, handles)
% hObject    handle to img_h (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function img_w_Callback(hObject, eventdata, handles)
% hObject    handle to img_w (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of img_w as text
%        str2double(get(hObject,'String')) returns contents of img_w as a double


% --- Executes during object creation, after setting all properties.
function img_w_CreateFcn(hObject, eventdata, handles)
% hObject    handle to img_w (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function wave_fs_Callback(hObject, eventdata, handles)
% hObject    handle to wave_fs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of wave_fs as text
%        str2double(get(hObject,'String')) returns contents of wave_fs as a double


% --- Executes during object creation, after setting all properties.
function wave_fs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wave_fs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function wave_T_Callback(hObject, eventdata, handles)
% hObject    handle to wave_T (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of wave_T as text
%        str2double(get(hObject,'String')) returns contents of wave_T as a double


% --- Executes during object creation, after setting all properties.
function wave_T_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wave_T (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in source_set.
function source_set_Callback(hObject, eventdata, handles)
% hObject    handle to source_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

sets = zeros(5, 1);
sets(1) = str2double(get(handles.text_len, 'String'));
sets(2) = str2double(get(handles.img_h, 'String'));
sets(3) = str2double(get(handles.img_w, 'String'));
sets(4) = str2double(get(handles.wave_fs, 'String'));
sets(5) = str2double(get(handles.wave_T, 'String'));

% 判定正整数
if sum(fix(sets) == sets) ~= 5 || min(sets) <= 0
    warndlg('信源参数应为正整数', '提示');
    return
end

% 单独判断
if sets(1) > 65535
    warndlg('文本最长限制不大于65535', '提示');
    return
end
if sets(4) > 64
    warndlg('音频采样率不大于64kHz', '提示');
    return
end
if sets(5) > 30
    warndlg('音频录制时长不大于30s', '提示');
    return
end

% set
handles.text_max_len = sets(1);         % 文本最长限制
handles.img_size = [sets(2), sets(3)];  % 图片大小
handles.send_fs = sets(4);              % 音频采样率
handles.T = sets(5);                    % 音频录制时长

warndlg('设定成功', '提示');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in source_reset.
function source_reset_Callback(hObject, eventdata, handles)
% hObject    handle to source_reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.output = hObject;

% reset
handles.text_max_len = 8000;        % 文本最长限制
handles.img_size = [120, 80];       % 图片大小
handles.send_fs = 4000;             % 音频采样率
handles.T = 2;                      % 音频录制时长

set(handles.text_len, 'String', '8000');
set(handles.img_h, 'String', '60');
set(handles.img_w, 'String', '40');
set(handles.wave_fs, 'String', '4');
set(handles.wave_T, 'String', '2');

% Update handles structure
guidata(hObject, handles);
