function [Aircraft] = ERJ175LR_PHE()
%
% [Aircraft] = ERJ175LR_PHE()
%
% Define a parallel-hybrid-electric ERJ175LR for investigating FAST's
% behavior as the prescribed electric power fraction approaches zero. The
% calibrated conventional aircraft remains the source of every airframe,
% engine, mission, and numerical-analysis assumption.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Aircraft - an aircraft structure to be used for analysis.
%                size/type/units: 1-by-1 / struct / []
%


%% CONVENTIONAL BASELINE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Reuse the literature-matched ERJ175LR definition so this experiment changes
% only the propulsion architecture and its electric hardware assumptions.
Aircraft = AircraftSpecsPkg.ERJ175LR();


%% PARALLEL-HYBRID PROPULSION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Aircraft.Specs.Propulsion.PropArch.Type = "PHE";

% FAST sizes the battery and motors for the prescribed mission demand.
Aircraft.Specs.Weight.Batt = NaN;
Aircraft.Specs.Weight.EM = NaN;
Aircraft.Specs.Weight.EG = NaN;

% 500 Wh/kg battery specific energy and the shared detailed-cell assumptions.
Aircraft.Specs.Power.SpecEnergy.Batt = 0.5;
Aircraft.Specs.Power.Eta.EM = 0.96;
Aircraft.Specs.Power.Eta.EG = 0.96;
Aircraft.Specs.Power.P_W.EM = 10;
Aircraft.Specs.Power.P_W.EG = NaN;

Aircraft.Specs.Power.Battery.SerCells = 62;
Aircraft.Specs.Power.Battery.ParCells = 100;
Aircraft.Specs.Power.Battery.BegSOC = 100;

Aircraft.Specs.Battery.NomVolCell = 3.6;
Aircraft.Specs.Battery.CapCell = 3;
Aircraft.Specs.Battery.MaxExtVolCell = 4.088;
Aircraft.Specs.Battery.IntResist = 0.0199;
Aircraft.Specs.Battery.MinSOC = 20;
Aircraft.Specs.Battery.BegSOC = 100;
Aircraft.Specs.Battery.MaxAllowCRate = 5;


%% FIXED POWER MANAGEMENT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% A 1e-6 electric fraction reproduces the near-zero Case 28 architecture.
% Set this scalar to zero to recover the exact conventional PHE control, or
% increase it to study how the sizing result changes across the discontinuity.
FixedPowerSplit = 1e-5;

Aircraft.Specs.Power.LamDwn.SLS = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Tko = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Clb = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Crs = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Des = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Lnd = FixedPowerSplit;

% The downstream split above determines the electric share. The upstream
% electric branch remains fully connected whenever downstream power is drawn.
Aircraft.Specs.Power.LamUps.SLS = 1;
Aircraft.Specs.Power.LamUps.Tko = 1;
Aircraft.Specs.Power.LamUps.Clb = 1;
Aircraft.Specs.Power.LamUps.Crs = 1;
Aircraft.Specs.Power.LamUps.Des = 1;
Aircraft.Specs.Power.LamUps.Lnd = 1;

Aircraft.Settings.PowerManagement.Mode = "SupplyLambda";

end
