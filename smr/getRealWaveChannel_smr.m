function[data,h]=getRealWaveChannel_smr(fID, chan, varargin)
% getRealWaveChannel_smr reads an ADC (waveform) channel from a file.
%
% [DATA {, HEADER}]=getRealWaveChannel_smr(fID,...
%                       CHAN{, START{, STOP{, OPTIONS}}})
% fID is the matlab file handle, CHAN is the channel number (1=max)
% 
% [DATA, HEADER]=getRealWaveChannel_smr(fID, 1{, OPTIONS})
%       reads all the data on channel 1
% [DATA, HEADER]=getRealWaveChannel_smr(fID, 1, 10{, OPTIONS})
%       reads disc block 10 for continuous data or epoch 10 for triggered
%       data
% [DATA, HEADER]=getRealWaveChannel_smr(fID, 1, 10, 20{, OPTIONS})
%       reads disc blocks 10-20 for continuous data or epochs 10-20
%       for triggered data
%
% When present, OPTIONS must be the last input argument. Valid options
% are:
% 'ticks', 'microseconds', 'milliseconds' and 'seconds' cause times to
%    be scaled to the appropriate unit (seconds by default)in HEADER
% 'progress' - causes a progress bar to be displayed during the read.
%
% Returns the signed 16 bit integer ADC values in DATA (scaled, offset and
% cast to double if 'scale' is used as an option). If present, HEADER
% will be returned with the channel header information from the file.
%
% For continuously sampled data, DATA is a simple vector.
% If sampling was triggered, DATA will be  2-dimensional matrix
% with each epoch (frame) of data in a separate row.
% 
% in this case HEADER could have the following example field values
%       FileName: source filename (and path)
%         system: version identifier
%    FileChannel: Channel number in file
%        phyChan: Physical (hardware) port.
%           kind: 9 - channel type identifier 
%        comment: Channel comment
%          title: Channel title
% sampleinterval: sampling interval in seconds              
%            min: minimum value loaded
%            max: maximum value loaded
%          units: Channel units
%        npoints: e.g. [1x200 double] number of valid data points
%                   in each column of DATA                
%           mode: 'Triggered' or 'Continuous' sampling
%          start: e.g [1x200 double] start time for each column in data
%                       in 'TimeUnits'
%           stop: e.g. [1x200 double] end time for each column in data
%                       in 'TimeUnits'
%         Epochs: e.g. {[200]  [399]  'of'  [961]  'epochs'} lists the
%                        blocks or epochs read
%      TimeUnits: e.g. 'Ticks' the time units
%      transpose: default 0, a flag used to indicate if the columns and
%                       rows of DATA have been transposed


      
        
Info=getInfo_smr(fID,chan);
if isempty (Info)
    data=[];
    h=[];
    return;
end;

if Info.kind ~=9
    warning('getRealWaveChannel_smr: Channel #%d No data or not a RealWave channel',chan);
    data=[];
    h=[];
    return;
end;

ShowProgress=0;
ScaleData=0;
arguments=nargin;
for i=1:length(varargin)
    if ischar(varargin{i}) 
        arguments=arguments-1;
        if strcmpi(varargin{i},'progress') && Info.blocks>10
            ShowProgress=1;
            progbar=progressbar(0,sprintf('Analyzing %d blocks on channel %d',Info.blocks,chan),...
                'Name',sprintf('%s',fopen(fID)));
        end;
    end;
end;

FileH=getHeader_smr(fID);
SizeOfHeader=20;                                            % Block header is 20 bytes long
header=getBlockHeaders_smr(fID,chan);


SampleInterval=(header(3,1)-header(2,1))/(header(5,1)-1);   % Sample interval in clock ticks

if(nargout>1)
h.FileName=Info.FileName;                                   % Set up the header information to return
h.system=['Matoff' num2str(FileH.systemID)];                   % if wanted
h.FileChannel=chan;
h.phyChan=Info.phyChan;
h.kind=Info.kind;
%h.blocks=Info.blocks;
%h.preTrig=Info.preTrig;
h.comment=Info.comment;
h.title=Info.title;
h.sampleinterval=getSampleInterval_smr(fID,chan);
h.min=Info.min;
h.max=Info.max;
h.units=Info.units;
end;


NumFrames=1;                                                % Number of frames. Initialize to one.
Frame(1)=1;
for i=1:Info.blocks-1                                       % Check for discontinuities in data record
    IntervalBetweenBlocks=header(2,i+1)-header(3,i);
    if IntervalBetweenBlocks>SampleInterval                 % If true data is discontinuous (triggered)
        NumFrames=NumFrames+1;                              % Count discontinuities (NumFrames)
        Frame(i+1)=NumFrames;                               % Record the frame number that each block belongs to
    else
        Frame(i+1)=Frame(i);                                % Pad between discontinuities
    end;
end;

    switch arguments
        case {2}
            FramesToReturn=NumFrames;
            h.npoints=zeros(1,FramesToReturn);
            startEpoch=1;           %Read all data
            endEpoch=Info.blocks;
        case {3}
            if NumFrames==1                     % Read one epoch
                startEpoch=varargin{1};  
                endEpoch=varargin{1};
            else
                FramesToReturn=1;
                h.npoints=0;
                startEpoch=find(Frame<=varargin{1});
                endEpoch=startEpoch(end);
                startEpoch=endEpoch;
            end;
        case {4}
            if NumFrames==1
                startEpoch=varargin{1};         % Read a range of epochs
                        endEpoch=varargin{2};
            else
                FramesToReturn=varargin{2}-varargin{1}+1;
                h.npoints=zeros(1,FramesToReturn);
                startEpoch=find(Frame==varargin{1});
                startEpoch=startEpoch(1);
                endEpoch=find(Frame<=varargin{2});
                endEpoch=endEpoch(end);
            end;
          
    end;

% Make sure we are in range if using START and STOP    
        if (startEpoch>Info.blocks || startEpoch>endEpoch)
            data=[];
            h=[];
            close(progbar);
            warning('getRealWaveChannel_smr: Invalid START and/or STOP')
            return;
        end;
        if endEpoch>Info.blocks
            endEpoch=Info.blocks;
        end;


if NumFrames==1 
%%%%%%% Continuous sampling - one frame only. Epochs correspond to blocks
    NumberOfSamples=sum(header(5,startEpoch:endEpoch));     % Sum of samples in all blocks
    data=single(zeros(1,NumberOfSamples));                   % Pre-allocate memory for data
    pointer=1;
   
    h.mode='Continuous';
    h.epochs=[startEpoch endEpoch];
    h.npoints=NumberOfSamples;
    h.start=header(2,startEpoch); % Time of first data point (clock ticks)
    h.stop=header(3,endEpoch);    % End of data (clock ticks)

    for i=startEpoch:endEpoch
        fseek(fID,header(1,i)+SizeOfHeader,'bof');
        data(pointer:pointer+header(5,i)-1)=fread(fID,header(5,i),'float32=>float32');
        pointer=pointer+header(5,i);
        if ShowProgress==1
            done=(i-startEpoch)/max(1,endEpoch-startEpoch);
            progressbar(done, progbar,sprintf('Reading Channel %d     %d%%',chan,(int16(done*100)/10)*10));
        end;
    end;
else
%%%%%%% Frame based data -  multiple frames. Epochs correspond to
%%%%%%% frames of data
    NumberOfSamples=sum(header(5,startEpoch:endEpoch));  % Sum of samples in required epochs
    FrameLength=max(histc(Frame,startEpoch:endEpoch))...
        *max(header(5,startEpoch:endEpoch));% Maximum data points to a frame
    data=single(zeros(FramesToReturn,FrameLength)); % Pre-allocate array
    p=1;                  % Pointer into data array for each disk data block
    Frame(Info.blocks+1)=-99; % Dummy entry to avoid index error in for loop
    h.mode='Triggered';
    h.start(1)=header(2,startEpoch);% Time of first data point in first returned epoch (clock ticks)
    index=1; %epoch counter
    for i=startEpoch:endEpoch                                       
        fseek(fID,header(1,i)+SizeOfHeader,'bof');
        data(index,p:p+header(5,i)-1)=fread(fID,header(5,i),'float32=>float32');
        h.npoints(index)=h.npoints(index)+header(5,i);
        if Frame(i+1)==Frame(i)
            p=p+header(5,i);               % Increment pointer or.....
        else
            h.stop(index)=header(3,i);     % End time for this frame, clock ticks
            if(i<endEpoch)
            p=1;                          % begin new frame
            index=index+1;
            h.start(index)=header(2,i+1); % Time of first data point in next frame (clock ticks)
            end;
        end;
        if ShowProgress==1
            done=(i-startEpoch)/max(1,endEpoch-startEpoch);
            progressbar(done, progbar,sprintf('Reading Channel %d     %d%%',chan,(int16(done*100)/5)*5));
        end;
        
    end;
end;
if NumFrames==1
    h.Epochs={startEpoch endEpoch 'of' Info.blocks 'blocks'};
else
    h.Epochs={startEpoch endEpoch 'of' NumFrames 'epochs'};
end;
[h.start,h.TimeUnits]=convertSamplesToTime_smr(fID,h.start, varargin{:});
[h.stop,h.TimeUnits]=convertSamplesToTime_smr(fID,h.stop, varargin{:});
if ScaleData==1
    if ShowProgress==1
        progressbar(1,progbar,'Scaling data.....');
    end;
    [data,h]=convertRealToAnalog_smr(data,h);
end;

if ShowProgress==1
    close(progbar);
end;

