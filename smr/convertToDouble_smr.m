function[out,h]=convertToDouble_smr(in,header)


if(nargin<2)
    header.scale=1;
    header.offset=0;
end;

if isstruct(header)
    if(isfield(header,'kind'))
        if header.kind~=1
            warning('convert2Double_smr: Not an ADC channel on input');
            out=[];
            h=[];
            return;
        end;
    end;
end;

if strcmp(class(in),'int16')~=1
    warning('convert2Double_smr: 16 bit integer expected');
    out=[];
    h=[];
    return;
end;

s=header.scale/6553.6;
o=header.offset;
out=(double(in)*s)+o;

if(nargin==2)
    h=header;
end;

if(nargout==2)
    h.max=(double(max(in(:)))*s)+o;
    h.min=(double(min(in(:)))*s)+o;
    h.kind=9;
end;
