function [Aircraft] = RecomputeSplits(Aircraft, SegBeg, SegEnd)
%
% [Aircraft] = RecomputeSplits(Aircraft, SegBeg, SegEnd)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 23 apr 2024
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

% check for any parallel connections
ParIndx = find(cellfun(@(x) ~isempty(x), ParConns));

% get the number of parallel connections
npar = length(ParIndx);

% get the power available (equal to power output for "full throttle" case)
%Pav_PS = Aircraft.Mission.History.SI.Power.Pav_PS(SegBeg:SegEnd, :);

% get power output for computing splits
Pout_PS = Aircraft.Mission.History.SI.Power.Pout_PS(SegBeg:SegEnd, :);
Pav_PS  = Aircraft.Mission.History.SI.Power.Pav_PS(SegBeg:SegEnd, :);

%% RE-COMPUTE THE POWER SPLITS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% don't re-compute if there aren't any splits, only get engine power code
if (Aircraft.Specs.Power.LamTSPS.SLS == 0)
    PC_Eng = Pout_PS./Pav_PS;
    nans = isnan(PC_Eng);
    PC_Eng(nans) = 0;
    Aircraft.Mission.History.SI.Power.PC(SegBeg:SegEnd, :) = PC_Eng(:, 1);
    return;
end

% get EM power avalibale - constant
PavEM = Aircraft.Specs.Weight.EM * 10^3 / 2;

% loop through each power split
for ipar = 1:npar
    
    % get the index of the main connection
    imain = ParIndx(ipar);
    
    % get the supplemental connection(s)
    isupp = ParConns{imain};
    
    % get the total power output at any given time from each source
    PoutEng = Pout_PS(:, imain);
    PoutEM  = Pout_PS(:, isupp);

    % get total power avalible at each segment
    PavEng = Pav_PS(:, imain);
    
    % compute the downstream power split
    SplitTSPS = PoutEM ./ (PoutEng + PoutEM);
    
    % remember the actual power split
    LamTSPS = SplitTSPS;

    % Compute the power code
    PC_Eng = PoutEng./PavEng;
    PC_EM = PoutEM./PavEM;
    PC_EM_NaN = isnan(PC_EM);
    PC_EM(PC_EM_NaN) = 0;

    Aircraft.Mission.History.SI.Power.PC(SegBeg:SegEnd, imain) = PC_Eng;
    Aircraft.Mission.History.SI.Power.PC(SegBeg:SegEnd, isupp) = PC_EM;
    
end

% remember the power split
Aircraft.Mission.History.SI.Power.LamTSPS(SegBeg:SegEnd, :) = LamTSPS;

% Remeber power code
Aircraft.Specs.Power.PC = Aircraft.Mission.History.SI.Power.PC;

% ----------------------------------------------------------

end