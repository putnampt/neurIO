if(nargin ~= 2)
   disp('2 input arguments are required')
   return
end

if(isempty(filename))
   [fname, pathname] = uigetfile('*.plx', 'Select a plx file');
	filename = strcat(pathname, fname);
end
fID = fopen(filename, 'r');