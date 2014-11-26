clear all
clc
plx_path = fullfile(pwd, 'test', '4chDemoPLX.plx');

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


%Create blank logical matrix of units (rows) by chans (columns)
ts_units_chans = false(5, 130);

%Go through each unit
for unit =  1:5
    
    %Find channels with more than one timestamp (not empty)
     filled_chans = find(ts_counts(unit,:) >1);
     
     %Create array of unit number the length of number of filled channels
     units = unit*ones(1,size(filled_chans,2));
     
     %Set to true
     ts_units_chans(units, filled_chans) = 1;
end

%Go through each channel
for chan = 1:130

    %If any of the unit counts > 0
    if any(ts_counts(:, chan)) > 0
        
    end
end










