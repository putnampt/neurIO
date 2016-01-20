%function [ chan ] = load_pl2(path, varargin)
%LOAD_PL2 Summary of this function goes here
%   Detailed explanation goes here

path = 'C:\Users\Bread\Desktop\encodeTest1.pl2';

pl2 = PL2GetFileIndex(path);
 
%%Load the analog channels 
for c = 1:size(pl2.AnalogChannels,1);
    chan(c).type = 1; % Analog channel
    chan(c).name = pl2.AnalogChannels{c}.Name;
    chan(c).header = pl2.AnalogChannels{c};
    
end

%%Load the spike channels
for c = c:(c+size(pl2.SpikeChannels,1));
    
end

%%Load the eventtr[op channels 
for c = c:(c+size(pl2.EventChannels,1));
    
end
 
       PL2Print(pl2.EventChannels);
       
       [event] = PL2EventTs(path, 'Strobed');