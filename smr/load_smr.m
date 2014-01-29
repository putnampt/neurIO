%   function [chan] = load_smr(path, channelList, )


function [chan] = load_smr(path, varargin)

fID = fopen(path);
[chan]=listChannels_smr(fID);
numChan = size(chan,2);
[fileHeader] = getHeader_smr(fID);

for chanDex = 1:numChan
    chan(chanDex).fileHeader= fileHeader;
    chan(chanDex).chanHeader = getInfo_smr(fID, chan(chanDex).number);
    [chan(chanDex).data,chan(chanDex).header]=getChannel_smr(fID, chan(chanDex).number);
end
