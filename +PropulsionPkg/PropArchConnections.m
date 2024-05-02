function [Aircraft] = PropArchConnections(Aircraft)
%
% [Aircraft] = PropArchConnections(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 08 mar 2024
%
% Given a propulsion architecture, identify any parallel electric motor /
% engine connections. These connections are used to reduce the power
% supplied by an engine to turn the fan/propeller.
%
% INPUTS:
%     Aircraft - structure containing information about the aircraft and
%                its propulsion architecture from
%                "Aircraft.Specs.Propulsion.PropArch".
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - structure identifying the companion engines / electric
%                motors that are arranged in parallel.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the TSPS matrix
TSPS = Aircraft.Specs.Propulsion.PropArch.TSPS;

% get the number of power sources
[~, nps] = size(TSPS);

% assume there are no parallel connections
Aircraft.Specs.Propulsion.PropArch.ParConns = cell(1, nps);


%% FIND THE POWER SOURCES IN PARALLEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% find the number of power sources driving each thrust source
npsDriving = sum(TSPS, 2);

% find the rows that have multiple power sources driving a thrust source
MultiplePS = find(npsDriving > 1);

% get the number of rows to check
nrow = length(MultiplePS);

% if no sources in parallel, exit out
if (nrow < 1)
    return;
end


%% FLAG PARALLEL ENGINE-EM CONNECTIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the cell array showing the engine and electric motor connections
ParConns = Aircraft.Specs.Propulsion.PropArch.ParConns;

% identify the electric motors
EM = Aircraft.Specs.Propulsion.PropArch.PSType == 0;

% set any zero entries to -1 for logical evaluations
TSPS(TSPS < 1) = -1;

% find the electric motors in the architecture
CheckParallel = TSPS + EM;

% loop through the necessary rows
for irow = 1:nrow
    
    % get the current row
    jrow = MultiplePS(irow);
    
    % extract the row from the matrix
    CheckRow = CheckParallel(jrow, :);
        
    % distinguish between engines and electric motors
    [~, IsEM ] = find(CheckRow == 2);
    [~, IsEng] = find(CheckRow == 1);
    
    % get the number of eletric motors connected
    neng = length(IsEng);
    
    % loop through the electric motors
    for ieng = 1:neng
        
        % get the electric motor index
        jeng = IsEng(ieng);
        
        % update its cell
        ParConns{jeng} = [ParConns{jeng}; IsEM];
        
    end            
end

% return the updated set of parallel connections
Aircraft.Specs.Propulsion.PropArch.ParConns = ParConns;

% ----------------------------------------------------------

end