% 
% clear all
% clc
% plx_path = fullfile(pwd, 'test', '4chDemoPLX.plx');

function [file] = neurIO_plx(plx_path)

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


%% Read the file header
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
file_comment= deblank(file_comment);

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

%Package file header data into structure
file_header.magic_number = magic_number;
file_header.version = version;
file_header.file_comment = file_comment;
file_header.fs = fs;
file_header.num_dsp_chan = num_dsp_chan;
file_header.num_event_chan = num_event_chan;
file_header.num_slow_chan = num_slow_chan;
file_header.num_points_wave = num_points_wave;
file_header.num_points_preThr = num_points_preThr;
file_header.year = year;
file_header.month = month;
file_header.day = day;
file_header.hour = hour;
file_header.minute = minute;
file_header.second = second;
file_header.fastread = fastread;
file_header.waveform_freq = waveform_freq;
file_header.last_timestamp = last_timestamp;


%% Read headers of filled dsp channels
for h = 1:num_dsp_chan
    
    %Record the place in the file of this header
    dsp_headers(h).fstart = ftell(fID);
    
    %char Name[32];  Name given to the DSP channel
    tmp_str = char.empty(0,32);
    for i = 1:32
        tmp_str(i) = fread(fID, 1, '*char');
    end
    dsp_headers(h).chan_name = deblank(tmp_str);
    
    %char SIGName[32];  Name given to the corresponding SIG channel
    tmp_str = char.empty(0,32);
    for i = 1:32
        tmp_str(i) = fread(fID, 1, '*char');
    end
    dsp_headers(h).sig_name = deblank(tmp_str);
    
    %int Channel;  DSP channel number, 1-based
    dsp_headers(h).channel = fread(fID, 1, 'int32');
    
    %int WFRate;  When MAP is doing waveform rate limiting, this is limit w/f per sec divided by 10
    dsp_headers(h).wf_rate = fread(fID, 1, 'int32');
    
    %int SIG;  SIG channel associated with this DSP channel 1 - based
    dsp_headers(h).sig_chan = fread(fID, 1, 'int32');
    
    %int Ref;  SIG channel used as a Reference signal, 1- based
    dsp_headers(h).chan_gain = fread(fID, 1, 'int32');
    
    %int Gain;  actual gain divided by SpikePreAmpGain. For pre-version 105, actual gain divided by 1000.
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
    dsp_headers(h).chan_comment = deblank(tmp_str);
    
    %int Padding[11];
    dsp_headers(h).chan_padding = fread(fID, 11, 'int32');
    
end


%% Read headers of filled event channels
for h = 1:num_event_chan%size(ev_counts,2)
    
    %Record the place in the file of this header
    ev_headers(h).fstart = ftell(fID);
    
    %char Name[32];  name given to this event
    tmp_str = char.empty(0,32);
    for i = 1:32
        tmp_str(i) = fread(fID, 1, '*char');
    end
    ev_headers(h).chan_name = deblank(tmp_str);
    
    %int Channel;  event number, 1-based
    ev_headers(h).channel = fread(fID, 1, 'int32');
    
    %char Comment[128];
    tmp_str = char.empty(0,128);
    for i = 1:128
        tmp_str(i) = fread(fID, 1, '*char');
    end
    ev_headers(h).chan_comment = deblank(tmp_str);
    
    %int Padding[33];
    ev_headers(h).chan_padding = fread(fID, 33, 'int32');
    
end



%% Read headers of filled slow channels
for h = 1:num_slow_chan
    
    %Record the place in the file of this header
    slow_headers(h).fstart = ftell(fID);
    
    %char Name[32];  name given to this channel
    tmp_str = char.empty(0,32);
    for i = 1:32
        tmp_str(i) = fread(fID, 1, '*char');
    end
    slow_headers(h).chan_name = deblank(tmp_str);
    
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
    slow_headers(h).chan_comment = deblank(tmp_str);
    
    %int Padding[28];
    slow_headers(h).chan_padding = fread(fID, 28, 'int32');
end

%% Varibles for reading data blocks
%Save point at which data blocks start
file_header.datablock_start = ftell(fID);

%Create fragment counter
fragment =0;

%Create counters for # of found channels
slowchans_found = 0;
spkchans_found = 0;
eventchans_found = 0;

%Create lookup for found channels
id_slow = [];
id_spk = [];
id_event = [];

%Create counters for fragments for each channel
slow_frags = 0;
spk_frags = 0;
event_frags = 0;

%Create empty timestamp matrix, row is channel index, col is ts index
slow_ts = [];
spk_ts = [];
event_ts = [];

%Create empty datapoint matrix, row is channel index, col is ts index
slow_dp = [];
spk_dp = [];
event_dp = [];

%Create empty sample count matrix, row is channel index
slow_sc = 0;
spk_sc = 0;
event_sc = 0;

%Create empty  count arrary, row is channel index
slow_counts = 0;
spk_counts = 0;
event_counts = 0;



%% Keep reading data blocks until the end of the file
while feof(fID) == 0 && ftell(fID) < fsize
    
    %Increment fragment count
    fragment=fragment+1;
    
    %short Type; // Data type; 1=spike, 4=Event, 5=continuous
    type = fread(fID, 1, 'short');
    
    if type ==1
        type_str = 'spike';
    elseif type == 4
        type_str = 'event';
    elseif type == 5
        type_str = 'continuous';
    else
        warning('Unexpected data block type!');
    end
    
    %unsigned short UpperByteOf5ByteTimestamp; // Upper 8 bits of the 40 bit timestamp
    upper_ts_byte = fread(fID, 1, 'ushort');
    
    %unsigned long TimeStamp; // Lower 32 bits of the 40 bit timestamp
    ts = fread(fID, 1, 'ulong');
    
    %short Channel; // Channel number
    channel = fread(fID, 1, 'short');
    
    %short Unit; // Sorted unit number; 0=unsorted
    unit = fread(fID, 1, 'short');
    
    %short NumberOfWaveforms; // Number of waveforms in the data to follow, usually 0 or 1
    num_wfs = fread(fID, 1, 'short');
    
    %short NumberOfWordsInWaveform; // Number of samples per waveform in the data to follow
    num_words = fread(fID, 1, 'short');
    
    %If there are waveforms to read in
    if num_words > 0
        wf = fread(fID, [1 num_words], 'int16');
    end
    
    %Offset count by one since matlab is the only programming language that
    %counts from 1 and not zero
    chan_idx = channel+1;
    
    %fprintf('Fragment:%d\tType:%s\tChannel:%d\tWaveforms:%d\tWords:%d\n', fragment,type_str,channel,num_wfs, num_words);
    
    switch type
        case 5 % continuous data block
            
            [found_bool,chan_idx] = ismember(channel,id_slow);
            
            if found_bool %If we have already found this channel
                slow_frags(chan_idx) = slow_frags(chan_idx)+1;
                %fprintf('\tFragment #%d\t', slow_frags(chan_idx));
            else %This is a new channel
                slowchans_found = slowchans_found+1; %Increase found channel count
                slow_frags(slowchans_found) = 1; %First fragment found
                id_slow(slowchans_found) = channel; %Set channel # in key
                %fprintf('\tFound new slow channel (#%d): %d!',slowchans_found, channel);
                chan_idx = slowchans_found; %Set channel index
                slow_adpos(chan_idx) = 1; %Start adpos at 1
                slow_sc(chan_idx) = 0 ; %No samples recorded yet
                slow_counts(chan_idx) = 0; 
                if ev_counts(301+channel) > 0
                     slow_counts(chan_idx) = ev_counts(301+channel);
                    slow_channel(chan_idx).sampled_analog = 1:slow_counts(chan_idx);
                end
                %fprintf('\tCounts found in header:%d\t\n', slow_counts(chan_idx));
                %fprintf('\tFragment #%d\t', slow_frags(slowchans_found));
                slow_channel(chan_idx).channel = channel;
            end
            
            if num_words > 0 %If there is data to save
                %fprintf('Read %d words, saving.\t', size(wf,2));
                
                start_adpos = slow_adpos(chan_idx);
                stop_adpos = slow_adpos(chan_idx)+num_words;
                
                %fprintf('AD-positon %d->%d\t', start_adpos, stop_adpos);
                
                slow_ts(chan_idx,  slow_frags(slowchans_found)) = ts/fs;
                slow_dp(chan_idx,  slow_frags(slowchans_found)) = num_words;
                slow_sc(chan_idx) = slow_sc(chan_idx) + num_words;
                
                if slow_counts(chan_idx) > 0
                    if (stop_adpos-1) <= slow_counts(chan_idx) 
                        %fprintf('-\t');
                        slow_channel(chan_idx).sampled_analog(start_adpos:stop_adpos-1) = wf(1:num_words);
                        slow_adpos(chan_idx) = stop_adpos; 
                    else
                        %fprintf('=\t');
                        for i=1:num_words
                             slow_channel(chan_idx).sampled_analog(slow_adpos(chan_idx)) = wf(i); 
                            slow_adpos(chan_idx) = slow_adpos(chan_idx) + 1;
                        end
                    end
                else
                    %fprintf('+\t');
                    slow_channel(chan_idx).sampled_analog = [ slow_channel(chan_idx).sampled_analog wf(1, 1:nwords)];
                end
            else
                %fprintf('Nothing to save.\t');
            end
            
            %fprintf('Sampled Analog Length:%d\t', size(slow_channel(chan_idx).sampled_analog,2));
        
        case 4 %Event
             [found_bool,chan_idx] = ismember(channel,id_event);
            
            if found_bool %If we have already found this channel
                event_frags(chan_idx) = event_frags(chan_idx)+1;
                %fprintf('\tFragment #%d\t', event_frags(chan_idx));
                
                event(chan_idx).times(event_frags(eventchans_found)) = ts;
                event(chan_idx).codes(event_frags(eventchans_found)) = unit;
                
                 %fprintf('%d @ %d\t', unit, ts);
            else %This is a new channel
                eventchans_found = eventchans_found+1; %Increase found channel count
                event_frags(eventchans_found) = 1; %First fragment found
                id_event(eventchans_found) = channel; %Set channel # in key
                %fprintf('\tFound new event channel (#%d): %d!',eventchans_found, channel);
                chan_idx = eventchans_found; %Set channel index
                event(chan_idx).times(event_frags(eventchans_found)) = ts;
                event(chan_idx).codes(event_frags(eventchans_found)) = unit;
          
                %fprintf('\tFragment #%d\t', event_frags(eventchans_found));
                
                 %fprintf('%d @ %d\t', unit, ts);
                 
                  event(chan_idx).channel = channel;
                  
            end
            
           
        case 1 %Spike
            [found_bool,spk_idx] = ismember(channel,id_spk);
            
             if found_bool %If we have already found this channel
            spike_frags(spkchans_found) = spike_frags(spkchans_found)+1;
                 spike(spk_idx).unit(spike_frags(spkchans_found)) = unit;
                 spike(spk_idx).ts(spike_frags(spkchans_found)) = ts;
                 
                 %fprintf('\tUnit %d @ %d', unit, ts);
             else %This is a new channel
                 spkchans_found = spkchans_found+1;
                 spike_frags(spkchans_found) = 1;
                 id_spk(spkchans_found) = channel;
                 
                 %fprintf('\tFound new spike channel (#%d): %d!\n',spkchans_found, channel);
                 spk_idx = spkchans_found; %Set channel index
                 spike(spk_idx).channel = channel;
                 spike(spk_idx).unit(spike_frags(spkchans_found)) = unit;
                 spike(spk_idx).ts(spike_frags(spkchans_found)) = ts;
                 %fprintf('\tUnit %d @ %d', unit, ts);
                 
                 
             end
             
             if num_wfs >0
                 %fprintf('\tFound waveform!');
                 spike(spk_idx).wf(spike_frags(spkchans_found),1:num_words)  = wf;
             end
            

        otherwise
            
            
    end
    
    
 
    %fprintf('\n');
    
end





%% Transfer data to output file structure
c = 0; % Valid channel count

%Loop through slow channels and add them to stucture
for i = 1:slowchans_found
    
    c = c+1;
 
    header_idx = find([slow_headers.channel] == slow_channel(i).channel);
    
    file(c).chan_header = slow_headers(header_idx);
    file(c).channel = slow_channel(i).channel;
    file(c).name = slow_headers(header_idx).chan_name;
    file(c).type = 1;
    file(c).data.y = slow_channel(i).sampled_analog;
    file(c).data.x = [1:size(file(c).data.y,2)];

end

%Loop through event channels and add them to stucture
for i = 1:eventchans_found
    
    c = c+1;
 
    header_idx = find([ev_headers.channel] == event(i).channel);
    
    file(c).chan_header = ev_headers(header_idx);
    file(c).channel = event(i).channel;
    file(c).name = ev_headers(header_idx).chan_name;
    file(c).type = 2;
    file(c).data.y = event(i).codes;
    file(c).data.x = event(i).times;
end

%Loop through spike channels and add them to stucture
for i = 1:spkchans_found
    
    c = c+1;
    
    header_idx = find([dsp_headers.channel] == spike(i).channel);
    file(c).channel = spike(i).channel;
    file(c).name = dsp_headers(header_idx).chan_name;
    file(c).type = 2;
    file(c).data.y = spike(i).unit;
    file(c).data.x = spike(i).ts;
    
    if size(spike(i).wf,1) > 1
         file(c).type = 3;
         file(c).data.wf = spike(i).wf;
    end
    
end