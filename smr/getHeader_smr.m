function [head]=getHeader_smr(fID)

try
    frewind(fID);
catch
    warning(['getheader_smr:\t' ferror(fID) 'Invalid file handle?' ]);
    head=[];
    return;
end;

head.FileIdentifier=fopen(fID);
head.systemID=fread(fID,1,'int16');
head.copyright=fscanf(fID,'%c',10);
head.Creator=fscanf(fID,'%c',8);
head.usPerTime=fread(fID,1,'int16');
head.timePerADC=fread(fID,1,'int16');
head.filestate=fread(fID,1,'int16');
head.firstdata=fread(fID,1,'int32');
head.channels=fread(fID,1,'int16');
head.chansize=fread(fID,1,'int16');
head.extraData=fread(fID,1,'int16');
head.buffersize=fread(fID,1,'int16');
head.osFormat=fread(fID,1,'int16');
head.maxFTime=fread(fID,1,'int32');
head.dTimeBase=fread(fID,1,'float64');
if head.systemID<6
    head.dTimeBase=1e-6;
end;
head.timeDate.Detail=fread(fID,6,'uint8');
head.timeDate.Year=fread(fID,1,'int16');
if head.systemID<6
    head.timeDate.Detail=zeros(6,1);
    head.timeDate.Year=0;
end;
head.pad=fread(fID,52,'char=>char');
head.fileComment=cell(5,1);    

pointer=ftell(fID);
for i=1:5
    bytes=fread(fID,1,'uint8');
    head.fileComment{i}=fread(fID,bytes,'char=>char')';
    pointer=pointer+80;
    fseek(fID,pointer,'bof');
end;







