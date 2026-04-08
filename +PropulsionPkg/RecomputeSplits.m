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


% get the number of sources and transmitters
nsrc = length(Aircraft.Specs.Propulsion.PropArch.SrcType);
TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;
ntrn = length(TrnType);

% get the power available (equal to power output for "full throttle" case)
% do not include sources (sink is inluded)
Pav = Aircraft.Mission.History.SI.Power.Pav(SegBeg:SegEnd, :);
Pout = Aircraft.Mission.History.SI.Power.Pout(SegBeg:SegEnd, :);

% get the power splits
LamUps = Aircraft.Mission.History.SI.Power.LamUps(SegBeg:SegEnd, :);
LamDwn = Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :);

% re-compute the power splits that are nonzero, so get their indices
idx = any(LamUps > 0, 2);

% get the number of downstream splits
nsplit = Aircraft.Settings.nargOperDwn;

% loop through each power split
for i = 1:2

    % get the total power output at any given time from those sources
    Out = sum(Pout(idx, [i+nsrc, i+nsrc+2]), 2);
    
    % compute the downstream power split
    LamDwn(idx, i) = Pout(idx, i+nsrc) ./ Out;
    % compute the downstream power split
    LamDwn(idx, i+2) = Pout(idx, i+2+nsrc) ./ Out;

    % compute up stream power splits
    LamUps(idx, i) = Pout(idx, i+nsrc) ./ Pav(idx, i+nsrc);
    % compute up stream power splits
    LamUps(idx, i+2) = Pout(idx, i+nsrc+2) ./ Pav(idx, i+nsrc+2);
    %end

end

% if any are NaN, return 0 (assume it's from 0 power available)
LamDwn(isnan(LamDwn)) = 0;
LamUps(isnan(LamUps)) = 0;

% remeber the down stream power split
Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :) = LamDwn;
Aircraft.Specs.Power.LamDwn.Miss(SegBeg:SegEnd, :) = LamDwn;

% get the upstream power splits in this setting
%if Aircraft.Settings.PowerStrat == 1
 %   Aircraft.Mission.History.SI.Power.LamUps(SegBeg:SegEnd, :) = LamUps;
  %  Aircraft.Specs.Power.LamUps.Miss(SegBeg:SegEnd, :) = LamUps;
%end


% ----------------------------------------------------------

end