function [ output_args ] = neurIO_smr( input_args )
%NEURIO_SMR File input/output for
%   Detailed explanation goes here
%
%
%
%
%

fID = fopen(path);

fclose(fID);

end

function [header] = getHeader(fID)

try
    frewind(fID);
catch err
    warning(['neurIO_smr:\t' ferror(fID) 'Invalid file handle when reading header.' ]);
    header=[];
    return;
end

header.FileIdentifier=fopen(fID);
header.systemID=fread(fID,1,'int16');
header.copyright=fscanf(fID,'%c',10);
header.Creator=fscanf(fID,'%c',8);
header.usPerTime=fread(fID,1,'int16');
header.timePerADC=fread(fID,1,'int16');
header.filestate=fread(fID,1,'int16');
header.firstdata=fread(fID,1,'int32');
header.channels=fread(fID,1,'int16');
header.chansize=fread(fID,1,'int16');
header.extraData=fread(fID,1,'int16');
header.buffersize=fread(fID,1,'int16');
header.osFormat=fread(fID,1,'int16');
header.maxFTime=fread(fID,1,'int32');
header.dTimeBase=fread(fID,1,'float64');
if header.systemID<6
    header.dTimeBase=1e-6;
end
header.timeDate.Detail=fread(fID,6,'uint8');
header.timeDate.Year=fread(fID,1,'int16');
if header.systemID<6
    header.timeDate.Detail=zeros(6,1);
    header.timeDate.Year=0;
end
header.pad=fread(fID,52,'char=>char');
header.fileComment=cell(5,1);

pointer=ftell(fID);

for i=1:5
    bytes=fread(fID,1,'uint8');
    header.fileComment{i}=fread(fID,bytes,'char=>char')';
    pointer=pointer+80;
    fseek(fID,pointer,'bof');
end
end

function [channel_info] = getInfo(fID, chan)
header=getHeader_smr(fID);           % Get file header
if(header.channels<chan)
    warning('neurIO_smr: Channel number #%d too large for this file.',chan);
    channel_info=[];
end


base=512+(140*(chan-1));            % Offset due to file header and preceding channel headers
fseek(fID,base,'bof');
channel_info.FileName=fopen(fID);
channel_info.channel=chan;
channel_info.delSize=fread(fID,1,'int16');
channel_info.nextDelBlock=fread(fID,1,'int32');
channel_info.firstblock=fread(fID,1,'int32');
channel_info.lastblock=fread(fID,1,'int32');
channel_info.blocks=fread(fID,1,'int16');
channel_info.nExtra=fread(fID,1,'int16');
channel_info.preTrig=fread(fID,1,'int16');
channel_info.free0=fread(fID,1,'int16');
channel_info.phySz=fread(fID,1,'int16');
channel_info.maxData=fread(fID,1,'int16');
bytes=fread(fID,1,'uint8');
pointer=ftell(fID);
channel_info.comment=fread(fID,bytes,'char=>char')';
fseek(fID,pointer+71,'bof');
channel_info.maxChanTime=fread(fID,1,'int32');
channel_info.lChanDvd=fread(fID,1,'int32');
channel_info.physical_channel=fread(fID,1,'int16');
bytes=fread(fID,1,'uint8');
pointer=ftell(fID);
channel_info.title=fread(fID,bytes,'char=>char')';
fseek(fID,pointer+9,'bof');
channel_info.idealRate=fread(fID,1,'float32');
channel_info.kind=fread(fID,1,'uint8');
channel_info.pad=fread(fID,1,'int8');

channel_info.scale=[];
channel_info.offset=[];
channel_info.units=[];
channel_info.divide=[];
channel_info.interleave=[];
channel_info.min=[];
channel_info.max=[];
channel_info.initLow=[];
channel_info.nextLow=[];

switch channel_info.kind
    case {1,6}
        channel_info.scale=fread(fID,1,'float32');
        channel_info.offset=fread(fID,1,'float32');
        bytes=fread(fID,1,'uint8');
        pointer=ftell(fID);
        channel_info.units=fread(fID,bytes,'char=>char')';
        fseek(fID,pointer+5,'bof');
        if (header.systemID<6)
            channel_info.divide=fread(fID,1,'int32');
        else
            channel_info.interleave=fread(fID,1,'int32');
        end
    case {7,9}
        channel_info.min=fread(fID,1,'float32');        % With test data from Spike2 v4.05 min=scale and max=offset
        channel_info.max=fread(fID,1,'float32');        % as for ADC data
        bytes=fread(fID,1,'uint8');
        pointer=ftell(fID);
        channel_info.units=fread(fID,bytes,'char=>char')';
        fseek(fID,pointer+5,'bof');
        if (header.systemID<6)
            channel_info.divide=fread(fID,1,'int32');
        else
            channel_info.interleave=fread(fID,1,'int32');
        end
    case 4
        channel_info.initLow=fread(fID,1,'uchar');
        channel_info.nextLow=fread(fID,1,'uchar');
end


end

function [channel_list] = listChannels(fID)
header = getHeader(fID);

if isempty(header)
    channel_list=[];
    warning(['neurIO_smr:\t' ferror(fID) 'No channels found in header.' ]);
    return
end

actual_channels = 0;

for i=1:header.channels
    channel_info=getInfo(fID,i);
    if(c.kind>0)
        actual_channels=actual_channels+1;
        chanList(actual_channels).number=i;
        chanList(actual_channels).kind=channel_info.kind;
        chanList(actual_channels).title=channel_info.title;
        chanList(actual_channels).comment=channel_info.comment;
        chanList(actual_channels).physical_channel=channel_info.physical_chan;
    end
end

end

function [data, header] = getChannel(fID, chan, varargin)

if ischar(fID)==1
    warning('neurIO_smr: expecting a file handle from fopen(), not a string "%s" on input.',fID );
    data=[];
    header=[];
    return;
end


[path, name, ext]=fileparts(fopen(fID));
if strcmpi(ext,'.smr') ~=1
    warning('neurIO_smr: file handle points to "%s". \nThis is not a valid file.',fopen(fID));
    data=[];
    header=[];
    return;
end


channel_info=getInfo_smr(fID,chan);
if(channel_info.kind==0)
    warning('neurIO_smr: Channel #%d does not exist (or has been deleted).',chan);
    data=[];
    header=[];
    return;
end

switch channel_info.kind
    case {1}
        [data,header]=getAnalog(fID,chan,varargin{:});
        [data,header]=convertToDouble(data,header);
    case {2,3,4}
        [data,header]=getEventChannel(fID,chan,varargin{:});
    case {5}
        [data,header]=getMarkerChannel(fID,chan,varargin{:});
    case {6}
        [data,header]=getAnalogMarkerChannel(fID,chan,varargin{:});
    case {7}
        [data,header]=getRealMarkerChannel(fID,chan,varargin{:});
    case {8}
        [data,header]=getTextChannel(fID,chan,varargin{:});
    case {9}
        [data,header]=getRealWaveChannel(fID,chan,varargin{:});
    otherwise
        warning('neurIO_smr: Channel type not supported.');
        data=[];
        header=[];
        return;
end


switch channel_info.kind
    case {1,6,7,9}
        if isempty(header)==0
            header.transpose=0;
        end
end


end

function[interval, start]=getSampleInterval(fID,chan)
% getSampleInterval_smr returns the sampling interval in seconds
% on a waveform data channel in a file, i.e. the reciprocal of the
% sampling rate for the channel, together with the time of the first sample
%
% [INTERVAL{, START}]=getSampleInterval_smr(FID, CHAN)
% FID is the matlab file handle and CHAN is the channel number (1-max)
% The sampling INTERVAL and, if requested START time for the data are
% returned in seconds.
% Note that the returned times are always in seconds.

header=getHeader(fID);                                   % File header
channel_info=getInfo(fID,chan);                              % Channel header
block_header=getBlockHeaders(fID,chan);
switch channel_info.kind                                            % Disk block headers
    case {1,6,7,9}
        switch header.systemID
            case {1,2,3,4,5}                                                % Before version 6
                if (isfield(channel_info,'divide'))
                    interval=channel_info.divide*header.usPerTime*header.timePerADC*1e-6; % Convert to seconds
                    start=block_header(2,1)*header.usPerTime*header.timePerADC*1e-6;
                else
                    warning('neurIO_smr: ldivide not defined Channel #%d.', chan);
                    interval=[];
                    start=[];
                end;
            otherwise                                                       % Version 6 and above
                interval=channel_info.lChanDvd*header.usPerTime*header.dTimeBase;
                start=block_header(2,1)*header.usPerTime*header.dTimeBase;
        end
    otherwise
        warning('neurIO_smr: Invalid channel type Channel #%d.',chan);
        interval=[];
        start=[];
        return;
end
end
