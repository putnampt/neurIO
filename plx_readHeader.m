%Philip Putnam
%Test in progress

clear all
clc
plx_path = fullfile(pwd, 'test', '4chTetrodeDemo_PLX.plx');

%Check if file exists
if ~exist(plx_path, 'file')
    error('File not found.');
end

%Try to open file from specified path
fID = fopen(plx_path);

%If fopen failed, return error
if(fID == -1)
    error('Error opening file with fopen, check permissions.');
end

%Get the size of the file
fseek(fID, 0, 'eof');
fsize = ftell(fID);
fseek(fID, 0, 'bof');

%unsigned int MagicNumber; = 0x58454c50;
magic_number = fread(fID, 1, 'uint32');

%int Version; Version of the data format; determines which data
version = fread(fID, 1, 'int32');

%char Comment[128], User-supplied comment
file_comment = char.empty(0,128);
for i = 1:128
    file_comment(i) = fread(fID, 1, '*char');
end
file_comment= strtrim(file_comment);

%int ADFrequency; Timestamp frequency in hertz
fs = fread(fID, 1, 'int32');

%int NumDSPChannels, Number of DSP channel headers in the file
num_dsp_chan = fread(fID, 1, 'int32');

%int NumEventChannels, Number of Event channel headers in the file
num_event_chan = fread(fID, 1, 'int32');

%int NumSlowChannels, Number of A/D channel headers in the file
num_slow_chan = fread(fID, 1, 'int32');

%int NumPointsWave, Number of data points in waveform
num_points_wave = fread(fID, 1, 'int32');

%int NumPointsPreThr, Number of data points before crossing the threshold
num_points_preThr = fread(fID, 1, 'int32');

%int Year, Time/date when the data was acquired
year = fread(fID, 1, 'int32');

%int Month
month = fread(fID, 1, 'int32');

%int Day
day = fread(fID, 1, 'int32');

%int Hour;
hour = fread(fID, 1, 'int32');

%int Minute;
minute = fread(fID, 1, 'int32');

%int Second;
second = fread(fID, 1, 'int32');

%int FastRead; reserved
fastread = fread(fID, 1, 'int32');

%int WaveformFreq; waveform sampling rate; ADFrequency above is timestamp freq
waveform_freq = fread(fID, 1, 'int32');

%double LastTimestamp; duration of the experimental session, in ticks
last_timestamp = fread(fID, 1, 'double');

%The following 6 items are only valid if Version >= 103
if version >= 103
    
    %char Trodalness; 1 for single, 2 for stereotrode, 4 for tetrode
    trodalness = fread(fID, 1, 'char');
    
    %char BitsPerSpikeSample; ADC resolution for spike waveforms in bits
    data_trodalness = fread(fID, 1, 'char');
    
    %char BitsPerSpikeSample;
    bits_per_spike_sample = fread(fID, 1, 'char');
    
    %char BitsPerSlowSample; ADC resolution for slow-channel data in bits
    bits_per_slow_sample = fread(fID, 1, 'char');
    
    %unsigned short SpikeMaxMagnitudeMV; the zero-to-peak voltage in mV for
    spike_max_magnitude_mv = fread(fID, 1, 'ushort');
    
    %unsigned short SlowMaxMagnitudeMV; the zero-to-peak voltage in mV for slow-channel waveform adc values
    slow_max_magnitude_mv = fread(fID, 1, 'ushort');
    
    %unsigned short SpikePreAmpGain
    spike_pre_amp_gain = fread(fID, 1, 'ushort');
    
    %char Padding[46]; so that this part of the header is 256 bytes
    padding = char.empty(0,46);
    for i = 1:46
        padding(i) = (fread(fID, 1, '*char'));
    end
    
    file_header.trodalness = trodalness;
    file_header.data_trodalness = data_trodalness;
    file_header.bits_per_spike_sample = bits_per_spike_sample;
    file_header.bits_per_slow_sample = bits_per_slow_sample;
    file_header.spike_max_magnitude_mv = spike_max_magnitude_mv;
    file_header.slow_max_magnitude_mv = slow_max_magnitude_mv;
    file_header.spike_pre_amp_gain = spike_pre_amp_gain;
end

%Counters for the number of timestamps and waveforms in each channel and unit.
%Note that these only record the counts for the first 4 units in each channel.
%channel numbers are 1-based - array entry at [0] is unused

%int TSCounts[130][5]; number of timestamps[channel][unit]
ts_counts = fread(fID, [5, 130], 'int32');

%int WFCounts[130][5]; number of waveforms[channel][unit]
wf_counts = fread(fID, [5, 130], 'int32');

%Starting at index 300, this array also records the number of samples for the
%continuous channels. Note that since EVCounts has only 512 entries, continuous
%channels above channel 211 do not have sample counts.
%int EVCounts[512]; number of timestamps[event_number]
ev_counts = fread(fID, [1, 512], 'int32');

file_header.magic_number = magic_number;
file_header.version = version;
file_header.file_comment = file_comment;
file_header.fs = fs;
file_header.num_dsp_chan = num_dsp_chan;
file_header.num_event_chan = num_event_chan;
file_header.num_slow_chan = num_slow_chan;
file_header.num_points_wave = num_points_wave;
file_header.num_points_preThr = num_points_preThr;
file_header. year = year;
file_header. month = month;
file_header.day = day;
file_header.hour = hour;
file_header.minute = minute;
file_header.second = second;
file_header.fastread = fastread;
file_header.waveform_freq = waveform_freq;
file_header.last_timestamp = last_timestamp;




%%Create blank logical matrix of units (rows) by chans (columns)
%ts_units_chans = false(5, 130);
%
%%Go through each unit
%for unit =  1:5
%
%%Find channels with more than one timestamp (not empty)
% filled_chans = find(ts_counts(unit,:) >1);
%
% %Create array of unit number the length of number of filled channels
% units = unit*ones(1,size(filled_chans,2));
%
% %Set to true
% ts_units_chans(units, filled_chans) = 1;
%end



%Read headers of filled dsp channels
for h = 1:num_dsp_chan
    
    %Record the place in the file of this header
    dsp_headers(h).fstart = ftell(fID);
    
    %char Name[32];  Name given to the DSP channel
    tmp_str = char.empty(0,32);
    for i = 1:32
        tmp_str(i) = fread(fID, 1, '*char');
    end
    dsp_headers(h).chan_name = strtrim(tmp_str);
    
    %char SIGName[32];  Name given to the corresponding SIG channel
    tmp_str = char.empty(0,32);
    for i = 1:32
        tmp_str(i) = fread(fID, 1, '*char');
    end
    dsp_headers(h).sig_name = strtrim(tmp_str);
    
    %int Channel;  DSP channel number, 1-based
    dsp_headers(h).channel = fread(fID, 1, 'int32');
    
    %int WFRate;  When MAP is doing waveform rate limiting, this is limit w/f per sec divided by 10
    dsp_headers(h).wf_rate = fread(fID, 1, 'int32');
    
    %int SIG;  SIG channel associated with this DSP channel 1 - based
    dsp_headers(h).sig_chan = fread(fID, 1, 'int32');
    
    %int Ref;  SIG channel used as a Reference signal, 1- based
    dsp_headers(h).chan_gain = fread(fID, 1, 'int32');
    
    %int Gain;  actual gain divided by SpikePreAmpGain. For pre
    %version 105, actual gain divided by 1000.
    dsp_headers(h).actual_gain = fread(fID, 1, 'int32');
    
    %int Filter;  0 or 1
    dsp_headers(h).filter_bool = fread(fID, 1, 'int32');
    
    %int Threshold;  Threshold for spike detection in a/d values;
    dsp_headers(h).spike_detect_threshold = fread(fID, 1, 'int32');
    
    %int Method;  Method used for sorting units, 1 - boxes, 2 - templates
    dsp_headers(h).sort_method_int = fread(fID, 1, 'int32');
    
    if  dsp_headers(h).sort_method_int == 1
        dsp_headers(h).sort_method_str = 'boxes';
    elseif  dsp_headers(h).sort_method_int == 2
        dsp_headers(h).sort_method_str = 'templates';
    else
        dsp_headers(h).sort_method_str = 'unknown';
    end
    
    %int NUnits;  number of sorted units
    dsp_headers(h).number_units = fread(fID, 1, 'int32');
    
    %short Template[5][64];  Templates used for template sorting, in a/d values
    dsp_headers(h).templates = fread(fID, [5, 64], 'short');
    
    %int Fit[5];  Template fit
    dsp_headers(h).unit_template_fit = fread(fID, 5, 'int32');
    
    %int SortWidth;  how many points to use in template sorting
    dsp_headers(h).sorting_samples = fread(fID, 1, 'int32');
    
    %short Boxes[5][2][4];  the boxes used in boxes sorting
    for i = 1:4
        templates = fread(fID, [5, 2], 'short');
    end
    
    %int SortBeg;  beginning of the sorting window to use in template sorting (width defined by SortWidth)
    dsp_headers(h).sorting_beginning = fread(fID, 1, 'int32');
    
    %char Comment[128];
    tmp_str = char.empty(0,128);
    for i = 1:128
        tmp_str(i) = fread(fID, 1, '*char');
    end
    dsp_headers(h).chan_comment = strtrim(tmp_str);
    
    %int Padding[11];
    dsp_headers(h).chan_padding = fread(fID, 11, 'int32');
end


%Read headers of filled event channels
for h = 1:num_event_chan%size(ev_counts,2)
    
    %Record the place in the file of this header
    ev_headers(h).fstart = ftell(fID);
    
    %char Name[32];  name given to this event
    tmp_str = char.empty(0,32);
    for i = 1:32
        tmp_str(i) = fread(fID, 1, '*char');
    end
    ev_headers(h).chan_name = strtrim(tmp_str);
    
    %int Channel;  event number, 1-based
    ev_headers(h).channel = fread(fID, 1, 'int32');
    
    %char Comment[128];
    tmp_str = char.empty(0,128);
    for i = 1:128
        tmp_str(i) = fread(fID, 1, '*char');
    end
    ev_headers(h).chan_comment = strtrim(tmp_str);
    
    %int Padding[33];
    ev_headers(h).chan_padding = fread(fID, 33, 'int32');
    
end



%Read headers of filled slow channels
for h = 1:num_slow_chan
    
    %Record the place in the file of this header
    slow_headers(h).fstart = ftell(fID);
    
    %char Name[32];  name given to this channel
    tmp_str = char.empty(0,32);
    for i = 1:32
        tmp_str(i) = fread(fID, 1, '*char');
    end
    slow_headers(h).chan_name = strtrim(tmp_str);
    
    %int Channel;  channel number, 0-based
    slow_headers(h).channel = fread(fID, 1, 'int32');
    
    %int ADFreq;  digitization frequency
    slow_headers(h).fs = fread(fID, 1, 'int32');
    
    %int Gain;  gain at the adc card
    slow_headers(h).gain = fread(fID, 1, 'int32');
    
    %int Enabled;  whether this channel is enabled for taking data, 0 or 1
    slow_headers(h).enabled = fread(fID, 1, 'int32');
    
    %int PreAmpGain;  gain at the preamp
    slow_headers(h).preamp_gain = fread(fID, 1, 'int32');
    
    %int SpikeChannel;
    spike_chan = fread(fID, 1, 'int32');
    
    %As of Version 104, this indicates the spike channel (PL_ChanHeader.Channel) of
    %a spike channel corresponding to this continuous data channel.
    %<=0 means no associated spike channel.
    if version >= 104 && spike_chan >= 0
        slow_headers(h).spike_chan = spike_chan;
    end
    clear spike_chan
    
    %char Comment[128];
    tmp_str = char.empty(0,128);
    for i = 1:128
        tmp_str(i) = fread(fID, 1, '*char');
    end
    slow_headers(h).chan_comment = strtrim(tmp_str);
    
    %int Padding[28];
    slow_headers(h).chan_padding = fread(fID, 28, 'int32');
end
