function [Aircraft] = RecomputeSplits(Aircraft, SegBeg, SegEnd, RecomputeAllSplits)
%
% [Aircraft] = RecomputeSplits(Aircraft, SegBeg, SegEnd, RecomputeAllSplits)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 03 sep 2025
%
% Re-compute the operational power splits for a "full throttle" setting
% during the mission.
%
% this function previously worked for two elements connected in parallel.
% it has now been generalized to work for any number of elements connected
% in parallel.
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
%     RecomputeAllSplits
%              - if true, recompute every mission-indexed downstream split.
%                if false or omitted, retain FAST's legacy sizing behavior.
%                size/type/units: 1-by-1 / logical / []
%
% OUTPUTS:
%     Aircraft - structure with the updated power splits. Only LamTSPS is
%                updated for now.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% preserve legacy sizing behavior unless full mission split recomputation
% is explicitly requested by off-design feasibility dispatch
if nargin < 4
    RecomputeAllSplits = false;
end

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

% get the propulsion architecture
Arch = Aircraft.Specs.Propulsion.PropArch.Arch;

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
if RecomputeAllSplits
    nsplit = size(LamDwn, 2);
else
    nsplit = length(Aircraft.Specs.Power.LamDwn.SLS);
end

% Use an interior probe to identify which split controls each parallel
% branch.  A segment can begin at a shared point where the preceding
% depleted-battery segment left every LamDwn value at zero.  Probing the
% topology at that disconnected zero state makes EvalSplit appear
% insensitive to every split, so no branch is recomputed and the fan can
% subsequently receive power with no contributing source.  The topology is
% independent of the operating split value; 0.5 keeps every branch connected
% while its sensitivity is detected.
TmpSplit = 0.5 .* ones(1, size(LamDwn, 2));

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
    
    % get all indices
    jdx = [imain, isupp];
    
    % find the upstream split
    iups = find(sum(Arch(jdx, :), 1) == length(isupp) + 1);
    
    % get the total power output at any given time from those sources
    Pout = sum(Pav(idx, jdx), 2);
        
    % find the downstream split contributing
    for kdx = jdx
        for isplit = 1:nsplit
            
            % perturb a split
            TmpSplit(isplit) = TmpSplit(isplit) + 0.01;
            
            % get the new matrix
            OperNew = PropulsionPkg.EvalSplit(Aircraft.Specs.Propulsion.PropArch.OperDwn, TmpSplit);
            
            % check if the matrices are different
            if (abs(OperDwn(iups, kdx) - OperNew(iups, kdx)) > 1.0e-06)
                
                % recompute the power split
                LamDwn(idx, isplit) = Pav(idx, kdx) ./ Pout;
                
            end
            
            % remove the perturbation
            TmpSplit(isplit) = TmpSplit(isplit) - 0.01;
            
        end
    end            
end

% if any are NaN, return 0 (assume it's from 0 power available)
LamDwn(isnan(LamDwn)) = 0;

% remember the power split
Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :) = LamDwn;

% ----------------------------------------------------------

end
