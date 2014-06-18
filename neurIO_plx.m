function [ varargout ] = neurIO_plx( varargin )
%NEURIO_PLX Summary of this function goes here
%   Detailed explanation goes here

filename = fullfile(pwd, 'test', 'plexon_sample.plx');

fID = fopen(filename);
file.filename = filename;

if(fID == -1)
    file = -1;
    return;
end

[info] = getInfo(fID)

[sampling_rate, number_samples, time_stamps, fragment_datapoints, sampled_analog] = getAnalog(fID, 1);
plot(sampled_analog)


fclose(fID);

end

function [info] = getInfo(fID)
info.raw_header = fread(fID, 64, 'int32');
info.version = info.raw_header(2);
info.freq = info.raw_header(35);  % frequency
info.number_dsp_channels = info.raw_header(36);  % number of dsp channels
info.number_event_channels = info.raw_header(37); % number of external events
info.number_analog_channels = info.raw_header(38);  % number of slow channels
info.waveform_points = info.raw_header(39);  % number of points in waveforms
info.points_before_threshold = info.raw_header(40);  % number of points before threshold

info.ts_count = fread(fID, [5, 130], 'int32');
info.wf_count = fread(fID, [5, 130], 'int32');
info.ev_count = fread(fID, [1, 512], 'int32');

% reset counters
info.ts_count = zeros(5, 130);
info.wf_count = zeros(5, 130);
info.ev_count = zeros(1, 512);
% skip variable headers
fseek(fID, 1020*info.number_dsp_channels + 296*info.number_event_channels + 296*info.number_analog_channels, 'cof');
info.records = 0;
while feof(fID) == 0
    type = fread(fID, 1, 'int16');
    upperbyte = fread(fID, 1, 'int16');
    timestamp = fread(fID, 1, 'int32');
    channel = fread(fID, 1, 'int16');
    unit = fread(fID, 1, 'int16');
    nwf = fread(fID, 1, 'int16');
    nwords = fread(fID, 1, 'int16');
    toread = nwords;
    if toread > 0
        wf = fread(fID, toread, 'int16');
    end
    if type == 1
        info.ts_count(unit+1, channel+1) = info.ts_count(unit+1, channel+1) + 1;
        if toread > 0
            info.wf_count(unit+1, channel+1) = info.wf_count(unit+1, channel+1) + 1;
        end
    end
    if type == 4
        info.ev_count(channel+1) = info.ev_count(channel+1) + 1;
    end
    
    info.records = info.records + 1;
    if feof(fID) == 1
        break
    end
end

end

function  [sampling_rate, number_samples, time_stamps, fragment_datapoints, sampled_analog] = getAnalog(fID, channel_number)
i = 0;
number_samples = 0;
time_stamps = 0;
fragment_datapoints = 0;
sampled_analog = 0;

% calculate file size
fseek(fID, 0, 'eof');
fsize = ftell(fID);
fseek(fID, 0, 'bof');


% Read file info.raw_header
info.raw_header = fread(fID, 64, 'int32');
info.freq = info.raw_header(35);  % frequency
info.number_dsp_channels = info.raw_header(36);  % number of dsp channels
info.number_event_channels = info.raw_header(37); % number of external events
info.number_analog_channels = info.raw_header(38);  % number of slow channels
info.waveform_points = info.raw_header(39);  % number of points in waveforms
info.points_before_threshold = info.raw_header(40);  % number of points before threshold
info.ts_count = fread(fID, [5, 130], 'int32');
info.wf_count = fread(fID, [5, 130], 'int32');
info.ev_count = fread(fID, [1, 512], 'int32');

% A/D counts are stored in info.ev_count (301, 302, etc.)
count = 0;
if info.ev_count(301+channel_number) > 0
    count = info.ev_count(301+channel_number);
    sampled_analog = 1:count;
end

% skip DSP and Event headers
fseek(fID, 1020*info.number_dsp_channels + 296*info.number_event_channels, 'cof');

% read one A/D info.raw_header and get the frequency
analog_chan_header = fread(fID, 74, 'int32');
sampling_rate = analog_chan_header(10);

% skip all other a/d headers
fseek(fID, 296*(info.number_analog_channels-1), 'cof');

records = 0;

wf = zeros(1, info.waveform_points);
adpos = 1;

while feof(fID) == 0
    type = fread(fID, 1, 'int16');
    upperbyte = fread(fID, 1, 'int16');
    timestamp = fread(fID, 1, 'int32');
    channel = fread(fID, 1, 'int16');
    unit = fread(fID, 1, 'int16');
    nwf = fread(fID, 1, 'int16');
    nwords = fread(fID, 1, 'int16');
    if nwords > 0
        wf = fread(fID, [1 nwords], 'int16');
    end
    if nwords > 0
        if type == 5
            if channel == channel_number
                i = i + 1;
                number_samples = number_samples + nwords;
                time_stamps(i) = timestamp/info.freq;
                fragment_datapoints(i) = nwords;
                if count > 0
                    if adpos+nwords-1 <= count
                        sampled_analog(adpos:adpos+nwords-1) = wf(1:nwords);
                        adpos = adpos + nwords;
                    else
                        for i=1:nwords
                            sampled_analog(adpos) = wf(i); adpos = adpos + 1;
                        end
                    end
                else
                    sampled_analog = [sampled_analog wf(1, 1:nwords)];
                end
            end
        end
    end
    
    records = records + 1;
    if mod(records, 1000) == 0
        %disp(sprintf('records %d points %d (%.1f%%)', records, number_samples, 100*ftell(fID)/fsize));
    end
    
    if feof(fID) == 1
        break
    end
    
end

if adpos-1 < count
    sampled_analog = sampled_analog(1:adpos-1);
end

end

function [number_samples, time_stamps] = getTimestamps(fID, channel_number, u)
% INPUT:
%   fID - fID
%   channel - 1-based channel number
%   unit  - unit number (0- invalid, 1-4 valid)
% OUTPUT:
%   number_samples - number of timestamps
%   time_stamps - array of timestamps (in seconds)


number_samples = 0;
time_stamps = 0;

% read file info.raw_header
info.raw_header = fread(fID, 64, 'int32');
info.freq = info.raw_header(35);  % frequency
info.number_dsp_channels = info.raw_header(36);  % number of dsp channels
info.number_event_channels = info.raw_header(37); % number of external events
info.number_analog_channels = info.raw_header(38);  % number of slow channels
info.waveform_points = info.raw_header(39);  % number of points in waveforms
info.points_before_threshold = info.raw_header(40);  % number of points before threshold
info.ts_count = fread(fID, [5, 130], 'int32');
info.wf_count = fread(fID, [5, 130], 'int32');
info.ev_count = fread(fID, [1, 512], 'int32');

% skip variable headers
fseek(fID, 1020*info.number_dsp_channels + 296*info.number_event_channels + 296*info.number_analog_channels, 'cof');

% read the data
records = 0;
while feof(fID) == 0
    type = fread(fID, 1, 'int16');
    upperbyte = fread(fID, 1, 'int16');
    timestamp = fread(fID, 1, 'int32');
    channel = fread(fID, 1, 'int16');
    unit = fread(fID, 1, 'int16');
    nwf = fread(fID, 1, 'int16');
    nwords = fread(fID, 1, 'int16');
    toread = nwords;
    if toread > 0
        wf = fread(fID, toread, 'int16');
    end
    if type == 1
        if channel == channel_number
            if unit == u
                number_samples = number_samples + 1;
                time_stamps(number_samples) = timestamp/info.freq;
            end
        end
    end
    
    records = records + 1;
    if feof(fID) == 1
        break
    end
    
end


end

function [number_samples, time_stamps, event_values] = getEvents(fID, channel_number)
% INPUT:
%   filename - if empty string, will use File Open dialog
%   channel - 1-based external channel number
%             strobed channel has channel number 257
% OUTPUT:
%   number_samples - number of timestamps
%   time_stamps - array of timestamps
%   event_values - array of strobed event values (filled only if channel is 257)

number_samples = 0;
time_stamps = 0;
event_values = 0;

% read file info.raw_header
info.raw_header = fread(fID, 64, 'int32');
info.freq = info.raw_header(35);  % frequency
info.number_dsp_channels = info.raw_header(36);  % number of dsp channels
info.number_event_channels = info.raw_header(37); % number of external events
info.number_analog_channels = info.raw_header(38);  % number of slow channels
info.waveform_points = info.raw_header(39);  % number of points in waveforms
info.points_before_threshold = info.raw_header(40);  % number of points before threshold
info.ts_count = fread(fID, [5, 130], 'int32');
info.wf_count = fread(fID, [5, 130], 'int32');
info.ev_count = fread(fID, [1, 512], 'int32');

% skip variable headers
fseek(fID, 1020*info.number_dsp_channels + 296*info.number_event_channels + 296*info.number_analog_channels, 'cof');

% read the data
records = 0;
while feof(fID) == 0
    type = fread(fID, 1, 'int16');
    upperbyte = fread(fID, 1, 'int16');
    timestamp = fread(fID, 1, 'int32');
    channel = fread(fID, 1, 'int16');
    unit = fread(fID, 1, 'int16');
    nwf = fread(fID, 1, 'int16');
    nwords = fread(fID, 1, 'int16');
    toread = nwords;
    if toread > 0
        wf = fread(fID, toread, 'int16');
    end
    if type == 4
        if channel == channel_number
            number_samples = number_samples + 1;
            time_stamps(number_samples) = timestamp;
            event_values(number_samples) = unit;
        end
    end
    
    records = records + 1;
    if feof(fID) == 1
        break
    end
    
end

end

function [number_samples, waveform_points, time_stamps, waveforms] = getWaveforms(fID, channel_number, u)
% INPUT:
%   filename - if empty string, will use File Open dialog
%   channel - 1-based channel number
%   unit  - unit number (0- invalid, 1-4 valid)
% OUTPUT:
%   number_samples - number of waveforms
%   waveform_points - number of points in each waveform
%   time_stamps - array of timestamps (in seconds)
%   waveforms - array of waveforms [waveform_points, number_samples], raw a/d values

number_samples = 0;
waveform_points = 0;
time_stamps = 0;
waveforms = 0;

% read file info.raw_header
info.raw_header = fread(fID, 64, 'int32');
info.freq = info.raw_header(35);  % frequency
info.number_dsp_channels = info.raw_header(36);  % number of dsp channels
info.number_event_channels = info.raw_header(37); % number of external events
info.number_analog_channels = info.raw_header(38);  % number of slow channels
waveform_points = info.raw_header(39);  % number of points in waveforms
info.points_before_threshold = info.raw_header(40);  % number of points before threshold
info.ts_count = fread(fID, [5, 130], 'int32');
info.wf_count = fread(fID, [5, 130], 'int32');
info.ev_count = fread(fID, [1, 512], 'int32');

% skip variable headers
fseek(fID, 1020*info.number_dsp_channels + 296*info.number_event_channels + 296*info.number_analog_channels, 'cof');

records = 0;
waveforms = zeros(waveform_points, 1);
wf = zeros(waveform_points, 1);

% read data records
while feof(fID) == 0
    type = fread(fID, 1, 'int16');
    upperbyte = fread(fID, 1, 'int16');
    timestamp = fread(fID, 1, 'int32');
    channel = fread(fID, 1, 'int16');
    unit = fread(fID, 1, 'int16');
    nwf = fread(fID, 1, 'int16');
    nwords = fread(fID, 1, 'int16');
    toread = nwords;
    if toread > 0
        wf = fread(fID, [toread, 1], 'int16');
    end
    if toread > 0
        if type == 1
            if channel == channel_number
                if unit == u
                    number_samples = number_samples + 1;
                    time_stamps(number_samples) = timestamp/info.freq;
                    waveforms(:, number_samples) = wf;
                end
            end
        end
    end
    
    records = records + 1;
    if feof(fID) == 1
        break
    end
    
end
end


