function[interval, start]=getSampleInterval_smr(fID,chan)
% getSampleInterval_smr returns the sampling interval in seconds 
% on a waveform data channel in a file, i.e. the reciprocal of the
% sampling rate for the channel, together with the time of the first sample
%
% [INTERVAL{, START}]=getSampleInterval_smr(FID, CHAN)
% FID is the matlab file handle and CHAN is the channel number (1-max)
% The sampling INTERVAL and, if requested START time for the data are
% returned in seconds.
% Note that the returned times are always in seconds.



FileH=getHeader_smr(fID);                                   % File header
Info=getInfo_smr(fID,chan);                              % Channel header
header=getBlockHeaders_smr(fID,chan);
switch Info.kind                                            % Disk block headers
    case {1,6,7,9}
        switch FileH.systemID
            case {1,2,3,4,5}                                                % Before version 6
                if (isfield(Info,'divide'))
                    interval=Info.divide*FileH.usPerTime*FileH.timePerADC*1e-6; % Convert to seconds
                    start=header(2,1)*FileH.usPerTime*FileH.timePerADC*1e-6;
                else
                    warning('getSampleInterval_smr: ldivide not defined Channel #%d', chan);
                    interval=[];
                    start=[];
                end;
            otherwise                                                       % Version 6 and above
                interval=Info.lChanDvd*FileH.usPerTime*FileH.dTimeBase;
                start=header(2,1)*FileH.usPerTime*FileH.dTimeBase;
        end;
    otherwise
        warning('getSampleInterval_smr: Invalid channel type Channel #%d',chan);
        interval=[];
        start=[];
        return;
end;

