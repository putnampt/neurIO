function[interval,start]=getSampleTicks_smr(fID,chan)
% Finds the sampling interval on a data channel in a file
% in clock ticks and returns the time of the first sample


FileH=getHeader_smr(fID);                                   % File header
Info=getInfo_smr(fID,chan);                              % Channel header
header=getBlockHeaders_smr(fID,chan);                        % Disk block headers
switch Info.kind
case {1,6,7,9}
    switch FileH.systemID
    case {1,2,3,4,5}                                                % Before version 6
        if (isfield(Info,'divide'))
            interval=Info.divide*FileH.timePerADC;                  
            start=header(2,1)*FileH.timePerADC;
        else
            interval=[];
            start=[];
        end;
        
    case {6}                                                        % Version 6
        interval=Info.lChanDvd;
        start=header(2,1);
    end;
otherwise
    warning('getSampleTicks_smr: Invalid channel type');
    return
end;

