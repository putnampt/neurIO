function [ output_args ] = neurIO_plx( input_args )
%NEURIO_PLX Summary of this function goes here
%   Detailed explanation goes here
fID = fopen(filename);
if(nargin ~= 2)
   disp('2 input arguments are required')
   return
end

if(isempty(filename))
   [fname, pathname] = uigetfile('*.plx', 'Select a plx file');
	filename = strcat(pathname, fname);
end


if(fID == -1)
	disp('cannot open file');
   return
end

end

function [info] = getInfo(fID)
header = fread(fID, 64, 'int32');
version = header(2);
freq = header(35);  % frequency
ndsp = header(36);  % number of dsp channels
nevents = header(37); % number of external events
nslow = header(38);  % number of slow channels
npw = header(39);  % number of points in wave
npr = header(40);  % number of points before threshold
% disp(strcat('version = ', num2str(version)));
% disp(strcat('frequency = ', num2str(freq)));
% disp(strcat('number of DSP headers = ', num2str(ndsp)));
% disp(strcat('number of Event headers = ', num2str(nevents)));
% disp(strcat('number of A/D headers = ', num2str(nslow)));
tscounts = fread(fID, [5, 130], 'int32');
wfcounts = fread(fID, [5, 130], 'int32');
evcounts = fread(fID, [1, 512], 'int32');

   % reset counters
   tscounts = zeros(5, 130);
   wfcounts = zeros(5, 130);
   evcounts = zeros(1, 512);
   % skip variable headers
   fseek(fID, 1020*ndsp + 296*nevents + 296*nslow, 'cof');
	record = 0;
	while feof(fID) == 0
   	type = fread(fID, 1, 'int16');
		upperbyte = fread(fID, 1, 'int16');
		timestamp = fread(fID, 1, 'int32');
		channel = fread(fID, 1, 'int16');
   	unit = fread(fID, 1, 'int16');
	   nwf = fread(fID, 1, 'int16');
   	nwords = fread(fID, 1, 'int16');
	   toread = nwords;
        if toread > 0
      	   wf = fread(fID, toread, 'int16');
        end
      if type == 1
         tscounts(unit+1, channel+1) = tscounts(unit+1, channel+1) + 1;
         if toread > 0
            wfcounts(unit+1, channel+1) = wfcounts(unit+1, channel+1) + 1;
         end
      end
      if type == 4
         evcounts(channel+1) = evcounts(channel+1) + 1;
      end
      
   	record = record + 1;
	   if feof(fID) == 1
   	   break
	   end
	end
   disp(strcat('number of records = ', num2str(record)));

% disp(' ');
% disp(' Timestamps:');
% disp(' ch unit  count');
for i=1:130
   for j=1:5
      if tscounts(j, i) > 0
         disp(sprintf('%3d %4d %6d', i-1, j-1, tscounts(j, i)));
      end
   end
end

% disp(' ');
% disp(' Waveforms:');
% disp(' ch unit  count');
for i=1:130
   for j=1:5
      if wfcounts(j, i) > 0
         disp(sprintf('%3d %4d %6d', i-1, j-1, wfcounts(j, i)));
      end
   end
end

% disp(' ');
% disp(' Events:');
% disp(' ch count');
for i=1:300
  if evcounts(i) > 0
     disp(sprintf('%3d %6d', i-1, evcounts(i)));
   end
end

% disp(' ');
% disp(' A/D channels:');
% disp(' ch count');
for i=301:364
  if evcounts(i) > 0
     disp(sprintf('%3d %6d', i-301, evcounts(i)));
   end
end

info.tscounts = tscounts;
info.wfcounts = wfcounts;
info.evcounts = evcounts;

end

function  [adfreq, n, ts, fn, ad] = getADChannel(fID, ch)
i = 0;
n = 0;
ts = 0;
fn = 0;
ad = 0;


if(fID == -1)
	disp('cannot open file');
   return
end

% calculate file size
fseek(fID, 0, 'eof');
fsize = ftell(fID);
fseek(fID, 0, 'bof');


disp(strcat('file = ', filename));

% read file header
header = fread(fID, 64, 'int32');
freq = header(35);  % frequency
ndsp = header(36);  % number of dsp channels
nevents = header(37); % number of external events
nslow = header(38);  % number of slow channels
npw = header(39);  % number of points in wave
npr = header(40);  % number of points before threshold
tscounts = fread(fID, [5, 130], 'int32');
wfcounts = fread(fID, [5, 130], 'int32');
evcounts = fread(fID, [1, 512], 'int32');

% A/D counts are stored in evcounts (301, 302, etc.)
count = 0;
if evcounts(301+ch) > 0
	count = evcounts(301+ch);
	ad = 1:count;
end

% skip DSP and Event headers
fseek(fID, 1020*ndsp + 296*nevents, 'cof');

% read one A/D header and get the frequency
adheader = fread(fID, 74, 'int32');
adfreq = adheader(10);

% skip all other a/d headers
fseek(fID, 296*(nslow-1), 'cof');

record = 0;

wf = zeros(1, npw);
adpos = 1;

while feof(fID) == 0
   type = fread(fID, 1, 'int16');
	upperbyte = fread(fID, 1, 'int16');
	timestamp = fread(fID, 1, 'int32');
	channel = fread(fID, 1, 'int16');
   unit = fread(fID, 1, 'int16');
   nwf = fread(fID, 1, 'int16');
   nwords = fread(fID, 1, 'int16');
   if nwords > 0
      wf = fread(fID, [1 nwords], 'int16');
   end
   if nwords > 0
      if type == 5
         if channel == ch 
        	i = i + 1;
			n = n + nwords;
         	ts(i) = timestamp/freq;
			fn(i) = nwords;
			if count > 0
			    if adpos+nwords-1 <= count
				    ad(adpos:adpos+nwords-1) = wf(1:nwords);
					adpos = adpos + nwords;
			    else
					for i=1:nwords
						ad(adpos) = wf(i); adpos = adpos + 1;
					end
			    end
			else
				ad = [ad wf(1, 1:nwords)];
			end
      	 end
      end
   end
   
   record = record + 1;
   if mod(record, 1000) == 0
       disp(sprintf('records %d points %d (%.1f%%)', record, n, 100*ftell(fID)/fsize));
   end

   if feof(fID) == 1
      break
   end
   
end

if adpos-1 < count
   ad = ad(1:adpos-1);
end

disp(strcat('number of data points = ', num2str(n)));

end
