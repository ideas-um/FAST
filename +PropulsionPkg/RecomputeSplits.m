function [Aircraft] = RecomputeSplits(Aircraft, SegBeg, SegEnd)
%
% [Aircraft] = RecomputeSplits(Aircraft, SegBeg, SegEnd)
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
% OUTPUTS:
%     Aircraft - structure with the updated power splits. Only LamTSPS is
%                updated for now.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the parallel connections
ParConns = Aircraft.Specs.Propulsion.PropArch.ParConns;

% check if there are any parallel connections
if (isempty(ParConns))
    
    % don't re-compute if there aren't any splits
    return
    
end


%% RE-COMPUTE THE POWER SPLITS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the propulsion architecture
Arch = Aircraft.Specs.Propulsion.PropArch.Arch;

% get the number of parallel connections
npar = length(ParConns);

% get the power available (equal to power output for "full throttle" case)
Pav = Aircraft.Mission.History.SI.Power.Pav(SegBeg:SegEnd, :);

% get the power splits
LamUps = Aircraft.Mission.History.SI.Power.LamUps(SegBeg:SegEnd, :);
LamDwn = Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :);

% re-compute the power splits that are nonzero, so get their indices
idx = any(LamUps > 0, 2);

% get the number of downstream splits
nsplit = length(Aircraft.Specs.Power.LamDwn.SLS);

% get a temporary power split
TmpSplit = LamDwn(1, :);

% get the split definitions for the current mission segment
[OperUpsFun, OperDwnFun] = PropulsionPkg.SelectOperMatrices(Aircraft);
EtaUps = Aircraft.Specs.Propulsion.PropArch.EtaUps;

% get the original downstream matrix
OperDwn = PropulsionPkg.EvalSplit(OperDwnFun, TmpSplit);

% loop through each power split
for ipar = 1:npar
    
    % get this target-specific parallel group
    Group = ParConns(ipar);
    imain = Group.Driving;
    isupp = Group.Helping;
    
    % get all indices
    jdx = [imain, isupp];
    
    % use the target retained when the group was discovered
    iups = Group.Target;
    if (~all(Arch(jdx, iups) > 0))
        error("ERROR - RecomputeSplits: invalid parallel connection group.");
    end
    
    % Route each component's available power to this target before deriving
    % downstream shares. Reusing full component power at every target would
    % double-count engines or motors that have several outgoing connections.
    ActiveRows = find(idx);
    GroupPower = zeros(length(ActiveRows), length(jdx));
    for irow = 1:length(ActiveRows)
        ipnt = ActiveRows(irow);
        SplitUps = PropulsionPkg.EvalSplit(OperUpsFun, LamUps(ipnt, :));
        GroupPower(irow, :) = Pav(ipnt, jdx) .* SplitUps(jdx, iups)' .* ...
                              EtaUps(jdx, iups)';
    end
    Pout = sum(GroupPower, 2);
        
    % find the downstream split contributing
    for kdx = jdx
        for isplit = 1:nsplit
            
            % perturb a split
            TmpSplit(isplit) = TmpSplit(isplit) + 0.01;
            
            % get the new matrix
            OperNew = PropulsionPkg.EvalSplit(OperDwnFun, TmpSplit);
            
            % check if the matrices are different
            if (abs(OperDwn(iups, kdx) - OperNew(iups, kdx)) > 1.0e-06)
                
                % recompute the power split
                GroupIndex = find(jdx == kdx, 1);
                LamDwn(idx, isplit) = GroupPower(:, GroupIndex) ./ Pout;
                
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
