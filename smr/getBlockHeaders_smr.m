function[header]=getBlockHeaders_smr(fID,chan)
% getBlockHeaders_smr returns a matrix containing the data block headers
% in file 'fID' for channel 'chan'.
% The returned header in memory contains, for each disk block,
% a column with rows 1-5 representing:
%                       Offset to start of block in file
%                       Start time in clock ticks
%                       End time in clock ticks
%                       Chan number
%                       Items
% See CED documentation for details - note this header is a modified form of
% the disk header

succBlock=2;
Info=getInfo_smr(fID,chan);

if(Info.firstblock==-1)
    warning('getBlockHeaders_smr: No data on channel #%d', chan);
    header=[];
    return;
end;
    
header=zeros(6,Info.blocks);                                %Pre-allocate memory for header data
fseek(fID,Info.firstblock,'bof');                           % Get first data block    
header(1:4,1)=fread(fID,4,'int32');                         % Last and next block pointers, Start and end times in clock ticks
header(5:6,1)=fread(fID,2,'int16');                         % Channel number and number of items in block

if(header(succBlock,1)==-1)
    header(1,1)=Info.firstblock;                            % If only one block
else
    fseek(fID,header(succBlock,1),'bof');                   % Loop if more blocks
    for i=2:Info.blocks
        header(1:4,i)=fread(fID,4,'int32');                         
        header(5:6,i)=fread(fID,2,'int16');
        fseek(fID,header(succBlock,i),'bof');
        header(1,i-1)=header(1,i);                          
    end;
    header(1,Info.blocks)=header(2,Info.blocks-1);          % Replace predBlock for previous column
end;
header(2,:)=[];                                           % Delete succBlock data


