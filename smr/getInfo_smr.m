function [chanInfo]= getInfo_smr(fID,chan)

FileH=getHeader_smr(fID);           % Get file header
if(FileH.channels<chan)
    warning('getInfo_smr: Channel number #%d too large for this file',chan);
    chanInfo=[];
end;


base=512+(140*(chan-1));            % Offset due to file header and preceding channel headers
fseek(fID,base,'bof');
chanInfo.FileName=fopen(fID);
chanInfo.channel=chan; 
chanInfo.delSize=fread(fID,1,'int16');
chanInfo.nextDelBlock=fread(fID,1,'int32');
chanInfo.firstblock=fread(fID,1,'int32');
chanInfo.lastblock=fread(fID,1,'int32');
chanInfo.blocks=fread(fID,1,'int16');
chanInfo.nExtra=fread(fID,1,'int16');
chanInfo.preTrig=fread(fID,1,'int16');
chanInfo.free0=fread(fID,1,'int16');
chanInfo.phySz=fread(fID,1,'int16');
chanInfo.maxData=fread(fID,1,'int16');
bytes=fread(fID,1,'uint8');
pointer=ftell(fID);
chanInfo.comment=fread(fID,bytes,'char=>char')';
fseek(fID,pointer+71,'bof');
chanInfo.maxChanTime=fread(fID,1,'int32');
chanInfo.lChanDvd=fread(fID,1,'int32');
chanInfo.phyChan=fread(fID,1,'int16');
bytes=fread(fID,1,'uint8');
pointer=ftell(fID);
chanInfo.title=fread(fID,bytes,'char=>char')';
fseek(fID,pointer+9,'bof');
chanInfo.idealRate=fread(fID,1,'float32');
chanInfo.kind=fread(fID,1,'uint8');
chanInfo.pad=fread(fID,1,'int8');               

chanInfo.scale=[];
chanInfo.offset=[];
chanInfo.units=[];
chanInfo.divide=[];
chanInfo.interleave=[];
chanInfo.min=[];
chanInfo.max=[];
chanInfo.initLow=[];
chanInfo.nextLow=[];

   switch chanInfo.kind
   case {1,6}
       chanInfo.scale=fread(fID,1,'float32');
       chanInfo.offset=fread(fID,1,'float32');
       bytes=fread(fID,1,'uint8');
       pointer=ftell(fID);
       chanInfo.units=fread(fID,bytes,'char=>char')';
       fseek(fID,pointer+5,'bof');
       if (FileH.systemID<6)
           chanInfo.divide=fread(fID,1,'int32');
       else
           chanInfo.interleave=fread(fID,1,'int32');
       end;
   case {7,9}
       chanInfo.min=fread(fID,1,'float32');        % With test data from Spike2 v4.05 min=scale and max=offset
       chanInfo.max=fread(fID,1,'float32');        % as for ADC data
       bytes=fread(fID,1,'uint8');
       pointer=ftell(fID);
       chanInfo.units=fread(fID,bytes,'char=>char')';
       fseek(fID,pointer+5,'bof');
       if (FileH.systemID<6)
           chanInfo.divide=fread(fID,1,'int32');
       else
           chanInfo.interleave=fread(fID,1,'int32');
       end;
   case 4
       chanInfo.initLow=fread(fID,1,'uchar');
       chanInfo.nextLow=fread(fID,1,'uchar');
   end
                                                



