function[chanList]=listChannels_smr(fID)

h=getHeader_smr(fID);

if isempty(h)
    chanList=[];
    return;
end;

AcChan=0;
for i=1:h.channels
    c=getInfo_smr(fID,i);
    if(c.kind>0) 
        AcChan=AcChan+1;
        chanList(AcChan).number=i;
        chanList(AcChan).kind=c.kind;
        chanList(AcChan).title=c.title;
        chanList(AcChan).comment=c.comment;
        chanList(AcChan).phyChan=c.phyChan;
    end
end

            
            
            
