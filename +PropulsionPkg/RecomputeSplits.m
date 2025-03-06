function [Aircraft] = RecomputeSplits(Aircraft, SegBeg, SegEnd)
%
% [Aircraft] = RecomputeSplits(Aircraft, SegBeg, SegEnd)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 05 mar 2025
%
% Re-compute the operational power splits for a "full throttle" setting
% during the mission.
%
% WARNING: this function only works for two elements connected in parallel
% right now (or conventional/electric architectures that don't have any
% power splits).
%
% INPUTS:
%     Aircraft - structure with information about the aircraft and mission
%                being flown.
%                size/type/units: 1-by-1 / struct / []
%
%     SegBeg   - beginning segment index.
%                size/type/units: 1-by-1 / int / []
%
%     SegEnd   - ending segment index.
%                size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     Aircraft - structure with the updated power splits. Only LamTSPS is
%                updated for now.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the parallel connections
ParConns = Aircraft.Specs.Propulsion.PropArch.ParConns;

% identify any parallel connections
ParIndx = find(cellfun(@(x) ~isempty(x), ParConns));

% check if there are any parallel connections
if (~any(ParIndx))
    
    % don't re-compute if there aren't any splits
    return
    
end


%% RE-COMPUTE THE POWER SPLITS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of parallel connections
npar = length(ParIndx);

% get the number of sources and transmitters
nsrc = length(Aircraft.Specs.Propulsion.PropArch.SrcType);

% get the power available (equal to power output for "full throttle" case)
Pav = Aircraft.Mission.History.SI.Power.Pav(SegBeg:SegEnd, :);

% get the power splits
LamUps = Aircraft.Mission.History.SI.Power.LamUps(SegBeg:SegEnd, :);
LamDwn = Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :);

% re-compute the power splits that are nonzero, so get their indices
idx = any(LamUps > 0, 2);

% get the number of downstream splits
nsplit = Aircraft.Settings.nargOperDwn;

% get a temporary power split
TmpSplit = LamDwn(1, :);

% get the original downstream matrix
OperDwn = PropulsionPkg.EvalSplit(Aircraft.Specs.Propulsion.PropArch.OperDwn, TmpSplit);

% loop through each power split
for ipar = 1:npar
    
    % get the index of the main connection
    imain = ParIndx(ipar);
    
    % get the supplemental connection(s)
    isupp = ParConns{imain};
    
    % account for the source indices
    imain = imain + nsrc;
    
    % assume neither split contributes
    UseSplit = false(1, nsplit);
    
    % find the downstream split contributing
    for isplit = 1:nsplit
        
        % perturb a split
        TmpSplit(isplit) = TmpSplit(isplit) + 0.01;
        
        % get the new matrix
        OperNew = PropulsionPkg.EvalSplit(Aircraft.Specs.Propulsion.PropArch.OperDwn, TmpSplit);
        
        % check if the matrices are different
        UseSplit(isplit) = OperDwn(isupp+nsrc, imain) ~= OperNew(isupp+nsrc, imain);
        
        % remove the perturbation
        TmpSplit(isplit) = TmpSplit(isplit) - 0.01;
        
    end
    
    % get the total power output at any given time from those sources
    Pout = sum(Pav(idx, [imain, isupp]), 2);
    
    % compute the downstream power split
    LamDwn(idx, UseSplit) = Pav(idx, isupp) ./ Pout;
            
end

% if any are NaN, return 0 (assume it's from 0 power available)
LamDwn(isnan(LamDwn)) = 0;

% remember the power split
Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :) = LamDwn;

% ----------------------------------------------------------

end