function [ varargout ] = neurIO( varargin )
%NEURIO File input/output from binary neurophysiology data formats
%   Philip Putnam, 2014.
%   Version 0.1.1
%   This function serves as a wrapper, parsing input and utilizing the
%   format specific functions for actual file reading and writing.

%%  Hard coded varibles
validFormats = {'.smr';'.plx';'.pl2';'.nev'}; % List of valid formats for input files

%%  If no input parameters are specified, use pop-up to locate data file
if size(varargin) == [0,0]
     [FileName,PathName,FilterIndex] = uigetfile('*.*');
    varargin{1} = fullfile(PathName, FileName);
end

%%  Parse the input parameters
p = inputParser; % Create input parser objection

%   Default values
defaultStart = -1; % Time in miliseconds to start extraction, value of -1 is first time point
defaultStop = -1; % Time in miliseconds to end extract, value of -1 is last time point
defaultResample = -1;
defaultChannels = [];
defaultWrite = -1;

checkFile = @(x) exist(x, 'file'); % Function to check input file exists

%   Set Parser
addRequired(p,'filename',checkFile);
addParameter(p,'start',defaultStart,@isnumeric);
addParameter(p,'stop',defaultStop,@isnumeric);
addParameter(p,'resample',defaultResample,@isnumeric);
addParameter(p,'channels',defaultChannels);
addParameter(p,'write',defaultWrite);
p.KeepUnmatched = true; % Don't worry about case-matching for inputs

parse(p,varargin{:}); % Parse the input

fprintf('File name: %s\n\n',p.Results.filename)

if ~isempty(fieldnames(p.Unmatched))
    fprintf('Extra inputs:')
    disp(p.Unmatched)
end
if ~isempty(p.UsingDefaults)
    fprintf('Using default: ')
    disp(p.UsingDefaults)
end

[pathstr,name,ext] = fileparts(p.Results.filename); % Split filename input
ext = lower(ext); % Make sure the extension is lowercase for plaintext comparisons
any(validatestring(ext,validFormats)); % Check to see if it's a valid format

options =  p.Results; % Assign the matched parameters to a stucture

switch ext
    case '.smr' 
        fprintf('Opening %s as .SMR file.\n', p.Results.filename)
        neurIO_smr('filename', p.Results.filename, 'channels', p.Results.channels, 'start', p.Results.start, 'stop', p.Results.stop, 'resample', p.Results.resample, 'write', p.Results.write)
    case {'.plx'}
        fprintf('Opening %s as .PLX file.\n', p.Results.filename)
        neurIO_plx('filename', p.Results.filename, 'channels', p.Results.channels, 'start', p.Results.start, 'stop', p.Results.stop, 'resample', p.Results.resample, 'write', p.Results.write)
    case {'.pl2'}
        fprintf('Opening %s as .PL2 file.\n', p.Results.filename)
    case {'.nev'}
        fprintf('Opening %s as .NEV file.\n', p.Results.filename)
    case {'.nsx'}
        fprintf('Opening %s as .NSX file.\n', p.Results.filename)
    case {'.ddt'}
        fprintf('Opening %s as .DDT file.\n', p.Results.filename)
    otherwise
        warning('Unexpected format.');
end


end




% function [file] = neurIO_resample(file, fs)
% %NEURIO_RESAMPLE Resamples all channels to a specified frequency (hertz)
% end
% 
% function neurIO_writeFile(file, path)
% %NEURIO_WRITEFILE Writes file output to disk
% end