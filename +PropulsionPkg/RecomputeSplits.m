function [Aircraft] = RecomputeSplits(Aircraft, SegBeg, SegEnd)
%
% [Aircraft] = RecomputeSplits(Aircraft, SegBeg, SegEnd)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 16 sep 2026
%
% Re-compute the operational power splits for a "full throttle" setting
% during the mission.
%
% Each parallel target is recomputed from the power actually delivered to
% that target. Separate targets may share an engine without sharing a split.
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

% get the propulsion architecture
Arch = Aircraft.Specs.Propulsion.PropArch.Arch;

% get the number of sources and transmitters
nsrc = length(Aircraft.Specs.Propulsion.PropArch.SrcType);
TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;

% get the power available (equal to power output for "full throttle" case)
Pav = Aircraft.Mission.History.SI.Power.Pav(SegBeg:SegEnd, :);

% get the power splits
LamUps = Aircraft.Mission.History.SI.Power.LamUps(SegBeg:SegEnd, :);
LamDwn = Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :);

% re-compute the power splits that are nonzero, so get their indices
idx = any(LamUps > 0, 2);

% get the number of downstream splits
nsplit = length(Aircraft.Specs.Power.LamDwn.SLS);

OperUps = Aircraft.Specs.Propulsion.PropArch.OperUps;
OperDwn = Aircraft.Specs.Propulsion.PropArch.OperDwn;
EtaUps = Aircraft.Specs.Propulsion.PropArch.EtaUps;

% Collect each parallel target's incoming edges. An engine can contribute
% to several targets, so its helpers cannot be treated as one group.
Source = [];
Target = [];
for itarget = nsrc + (1:length(TrnType))
    Parents = find(Arch(:, itarget))';
    Transmitters = Parents(Parents > nsrc & Parents <= nsrc + length(TrnType));
    Engine = Transmitters(TrnType(Transmitters - nsrc) == 1);
    Motor = Transmitters(TrnType(Transmitters - nsrc) == 0);
    if (~isempty(Engine) && ~isempty(Motor))
        Source = [Source, Parents];
        Target = [Target, repmat(itarget, 1, length(Parents))];
    end
end

if (isempty(Source) || nsplit == 0)
    return
end

ncomp = size(Arch, 1);
DownIndex = sub2ind([ncomp, ncomp], Target, Source);
UpIndex = sub2ind([ncomp, ncomp], Source, Target);
for ipoint = find(idx)'
    Active = Pav(ipoint, Target) > 0;
    if (~any(Active))
        continue
    end
    Current = LamDwn(ipoint, :);
    UpMatrix = PropulsionPkg.EvalSplit(OperUps, LamUps(ipoint, :));
    DownMatrix = PropulsionPkg.EvalSplit(OperDwn, Current);
    EdgePower = Pav(ipoint, Source(Active))';
    TargetPower = Pav(ipoint, Target(Active))';
    UpFraction = UpMatrix(UpIndex(Active));
    UpEfficiency = EtaUps(UpIndex(Active));
    Desired = EdgePower .* UpFraction(:) .* UpEfficiency(:) ./ TargetPower;
    Baseline = DownMatrix(DownIndex(Active));
    Baseline = Baseline(:);
    Sensitivity = zeros(sum(Active), nsplit);
    for isplit = 1:nsplit
        Perturbed = Current;
        Perturbed(isplit) = Perturbed(isplit) + 0.01;
        NewMatrix = PropulsionPkg.EvalSplit(OperDwn, Perturbed);
        NewFraction = NewMatrix(DownIndex(Active));
        Sensitivity(:, isplit) = (NewFraction(:) - Baseline) / 0.01;
    end
    Change = Sensitivity \ (Desired(:) - Baseline(:));
    Updated = Current + Change';
    NewMatrix = PropulsionPkg.EvalSplit(OperDwn, Updated);
    Actual = NewMatrix(DownIndex(Active));
    if (any(~isfinite(Updated)) || any(abs(Actual(:) - Desired(:)) > 1.0e-06))
        error("FAST:EdgePowerInconsistent", ...
              "Edge power is not consistent. Your power splits are over-constrained.");
    end
    LamDwn(ipoint, :) = Updated;
end

% if any are NaN, return 0 (assume it's from 0 power available)
LamDwn(isnan(LamDwn)) = 0;

% remember the power split
Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :) = LamDwn;

% ----------------------------------------------------------

end
