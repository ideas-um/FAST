function [PFail, FailModes] = FaultTreeAnalysis(Arch, Components, RemoveSrc)
%
% [PFail, FailModes] = FaultTreeAnalysis(Arch, Components, RemoveSrc)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 nov 2025
%
% Given an adjacency-like matrix, find the minimum cut sets that account
% for internal failures and redundant primary events. then, using the
% minimum cut sets, compute the system-level failure probability per
% flight.
%
% INPUTS:
%     Arch       - the architecture matrix representing the system
%                  architecture to be analyzed.
%                  size/type/units: n-by-n / integer / []
%
%     Components - a structure array containing each component in the
%                  system architecture and the following information about
%                  it:
%                      a) the component name, as a cell array of characters
%                      b) a column vector of failure probabilities
%                      c) a column vector of failure modes corresponding to
%                         the failure rates, as a cell array of characters
%                  size/type/units: 1-by-1 / struct / []
%
%     RemoveSrc  - a flag to indicate whether the sources should be removed
%                  from the system architecture (1) or not (0). if no
%                  argument is provided, the default is to not remove any
%                  components (0).
%                  size/type/units: 1-by-1 / integer / []
%
% OUTPUTS:
%     PFail      - the system-level failure probability (per flight hour).
%                  size/type/units: 1-by-1 / double / []
%
%     FailModes  - cell array of the different ways that the system
%                  architecture can fail (printed as character arrays).
%                  size/type/units: nfail-by-ncomp / cell / []
%


%% CHECK FOR VALID INPUTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check the architecture     %
% matrix                     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check that an architecture matrix was provided
if (nargin < 1)

    % throw an error
    error('ERROR - FaultTreeAnalysis: the architecture matrix was not provided.');

end

% get the size of the architecture matrix
[nrow, ncol] = size(Arch);

% check the that number of rows and columns match
if (nrow ~= ncol)

    % throw an error
    error('ERROR - FaultTreeAnalysis: architecture matrix must be square.');

end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check the component list   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check that the component list was provided
if (nargin < 2)

    % throw an error
    error('ERROR - FaultTreeAnalysis: component list was not provided.');

end

% get the number of components
[ncomp, ~] = size(Components.Name);

% check that there are the same number of components as entries in matrix
if (ncomp ~= nrow)

    % throw an error
    error('ERROR - FaultTreeAnalysis: number of compononents must match dimension of architecture matrix.');

end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check the flag             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if the "remove source" flag was included
if (nargin < 3)

    % if it isn't included, assume it should be 0
    RemoveSrc = 0;

end


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% check for connections
ConnCheck = Arch > 0;

% count the number of input/output connections
ninput  = sum(ConnCheck, 1)';
noutput = sum(ConnCheck, 2) ;

% count the number of elements to trigger the gate
ntrigger = sum(Arch, 1)' ./ ninput;

% find the sources, sinks, and transmitters
isrc = find(ninput == 0 & noutput >  0);
isnk = find(ninput >  0 & noutput == 0);

% get the number of sinks
nsnk = length(isnk);

% for a fault tree, there can only be one sink
if (nsnk > 1)

    % throw an error
    error('ERROR - FaultTreeAnalysis: there are multiple sinks in the architecture matrix.');

end

% check if sources must be removed
if (RemoveSrc == 1)

    % remove their connections, but keep them in the matrix
    Arch(isrc, :) = 0; %#ok<*FNDSB>

end

% memory for finding connections
ArchConns = cell(ncomp, 1);

% remember the connections
for icomp = 1:ncomp

    % find the connections
    ArchConns{icomp} = find(Arch(:, icomp));

end

% assign an ID to each failure mode
Components.FailID = (1 : ncomp)';


%% PERFORM A BOOLEAN ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get all failure modes from %
% the system architecture    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% recursively search the system architecture to extract all failure modes
EnumModes = SafetyPkg.CreateCutSets(ArchConns, Components, isnk, ntrigger, ninput);

% eliminate duplicate events in single failure mode (idempotent law)
EnumModes = SafetyPkg.IdempotentLaw(EnumModes);

% eliminate duplicate events across failure modes (law of absorption)
EnumModes = SafetyPkg.LawOfAbsorption(EnumModes);


%% COMPUTE THE FAILURE RATE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the size of the failure modes
[nrow, ncol] = size(EnumModes);

% allocate memory for the failure rates (allocate ones for ease of
% multiplying across rows in a later step)
FailRates = ones(nrow, ncol);
FailModes = cell(nrow, ncol);

% loop through each component and add in its failure rate
for icomp = 1:ncomp

    % find the component in the failure modes
    idx = EnumModes == icomp;

    % fill in the failure rate
    FailRates(idx) = Components.FailRate(    icomp );
    FailModes(idx) = cellstr(Components.Name{icomp});

end

% multiply failure rates in the given row
FRateIndiv = prod(FailRates, 2);

% add all failure rates together for the system-level failure rate
PFail = sum(FRateIndiv);

% ----------------------------------------------------------

end