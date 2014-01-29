function[out,timeunits]=convertSamplesToTime_smr(fid, in, varargin)
% convertSamplesToTime_smr scales timestamp vector IN
%
% [OUT,{ TIMEUNITS}]= convertSamplesToTime_smr(FID, IN{, OPTIONS})
% FID is the matlab file handle, IN is a vector of timestamps from the file.
% 
% OPTIONS if present, may contain:
%   'Ticks' : Returns the time in base clock ticks
%   'microseconds', 'milliseconds' or 'seconds' (=default): scales the output
%        to the appropriate unit
% 
% OUT contains the scaled timestamps. TIMEUNITS, if present, is a string
% copied from OPTIONS giving the time units


FileH=getHeader_smr(fid);

if nargin>2
    for i=1:length(varargin)
        if strcmpi(varargin{i},'ticks')
            out=in;
            timeunits='Ticks';
        end;
        if strcmpi(varargin{i},'microseconds')
            out=in*FileH.usPerTime*(FileH.dTimeBase*1e6);
            timeunits='microseconds';
        end;
        if strcmpi(varargin{i},'milliseconds')
            out=in*FileH.usPerTime*(FileH.dTimeBase*1e3);
            timeunits='milliseconds';
        end;
    end;
end;

% if not set default to seconds
if exist('timeunits','var')==0
    out=in*FileH.usPerTime*FileH.dTimeBase;% default, time in seconds
    timeunits='seconds';
end;

            
        

