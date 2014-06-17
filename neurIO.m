function [ varargout ] = neurIO( filename, varargin )
%NEURIO File input/output from binary neurophysiology data formats
%   Philip Putnam, 2014.
%   Version 0.1.1
%   This function serves as a wrapper, parsing input and utilizing the
%   format specific functions for actual file reading and writing.

%%  Parse the input
p = inputParser; % Create input parser objection


[pathstr,name,ext] = fileparts(filename); % Split filename input
validFormats = {'.smr','.plx', '.pl2'}; % List of valid formats for input files
%checkFormat = @(x) any(validatestring(x,validFormats)); % Function to check if is a valid formats
any(validatestring(ext,validFormats))

defaultMode = 'pro'; % Default mode is programmatic 
validModes = {'pro','gui', 'pop'}; % Options are programmatic, GUI, or pop-up windows
checkMode = @(x) any(validatestring(x,validModes)); % Function to check if is a valid mode

checkFile = @(x) exist(x, 'file'); % Function to check input file exists


%   Default values
defaultStart = -1; % Time in miliseconds to start extraction, value of -1 is first time point
defaultStop = -1; % Time in miliseconds to end extract, value of -1 is last time point
defaultResample = -1;
defaultChannels = [];

%   Set Parser 
addRequired(p,'filename',checkFile);
addOptional(p,'mode',defaultMode,checkMode);
addParameter(p,'start',defaultStart,@isnumeric);
addParameter(p,'stop',defaultStop,@isnumeric);
addParameter(p,'resample',defaultResample,@isnumeric);
addParameter(p,'channels',defaultChannels);

p.KeepUnmatched = true; % Don't worry about case-matching for inputs

parse(p,filename,varargin{:}); % Parse the input

disp(['File name: ',p.Results.filename])
disp(['Mode: ', p.Results.mode])

if ~isempty(fieldnames(p.Unmatched))
   disp('Extra inputs:')
   disp(p.Unmatched)
end
if ~isempty(p.UsingDefaults)
   disp('Using defaults: ')
   disp(p.UsingDefaults)
end



%%
end

function [file] = neurIO_resample(file, fs)
%NEURIO_RESAMPLE Resample all channels to match fs
end