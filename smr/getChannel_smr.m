function[data,header]=getChannel_smr(fID, chan, varargin)

SizeOfHeader=20;    % Block header is 20 bytes long

if ischar(fID)==1
    warning('getChannel_smr: expecting a file handle from fopen(), not a string "%s" on input',fID );
    data=[];
    header=[];
    return;
end;


[path, name, ext]=fileparts(fopen(fID));
if strcmpi(ext,'.smr') ~=1
    warning('getChannel_smr: file handle points to "%s". \nThis is not a valid file',fopen(fID));
    data=[];
    header=[];
    return;
end;


Info=getInfo_smr(fID,chan);
if(Info.kind==0) 
    warning('getChannel_smr: Channel #%d does not exist (or has been deleted)',chan);
    data=[];
    header=[];
    return;
end;

switch Info.kind
case {1}
    [data,header]=getAnalog_smr(fID,chan,varargin{:});
    [data,header]=convertToDouble_smr(data,header);
case {2,3,4}
    [data,header]=getEventChannel_smr(fID,chan,varargin{:});
case {5}
    [data,header]=getMarkerChannel_smr(fID,chan,varargin{:});
case {6}
    [data,header]=getAnalogMarkerChannel_smr(fID,chan,varargin{:});
case {7}
    [data,header]=getRealMarkerChannel_smr(fID,chan,varargin{:});
case {8}
    [data,header]=getTextChannel_smr(fID,chan,varargin{:});
case {9}
    [data,header]=getRealWaveChannel_smr(fID,chan,varargin{:});
otherwise
    warning('getChannel_smr: Channel type not supported');
    data=[];
    header=[];
    return;
end;


switch Info.kind
case {1,6,7,9}
    if isempty(header)==0
        header.transpose=0;
    end;
end;



    






    

