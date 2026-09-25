function [SizedAircraft, RunMetadata] = RunPaperERJ175LRSizing(OutputFile)
%RUNPAPERERJ175LRSIZING Reproduce the paper HEA sizing on the current branch.
%
% The electric motors are sized to provide 10 percent of total takeoff
% power. During climb they are limited to 30 percent of their installed
% rating; the gas turbines provide the remaining required power.

if nargin < 1
    OutputFile = fullfile(pwd, ...
        "ERJ175LR_current_Lam_10pctTko_30pctEMClimb.mat");
end

Aircraft = AircraftSpecsPkg.ERJ175LR_Elec;

Aircraft.Specs.Power.SpecEnergy.Batt = 0.25;

% Downstream allocation sizes the installed EMs at 10% of takeoff power.
Aircraft.Specs.Power.LamDwn.SLS = 0.10;
Aircraft.Specs.Power.LamDwn.Tko = 0.10;
% Sizing seed; RecomputeSplits derives the flown climb LamDwn from LamUps.
Aircraft.Specs.Power.LamDwn.Clb = 0.10;
Aircraft.Specs.Power.LamDwn.Crs = 0;
Aircraft.Specs.Power.LamDwn.Des = 0;
Aircraft.Specs.Power.LamDwn.Lnd = 0;

% Upstream EM power code: full installed power at takeoff, 30% in climb.
Aircraft.Specs.Power.LamUps.SLS = 1.00;
Aircraft.Specs.Power.LamUps.Tko = 1.00;
Aircraft.Specs.Power.LamUps.Clb = 0.30;
Aircraft.Specs.Power.LamUps.Crs = 0;
Aircraft.Specs.Power.LamUps.Des = 0;
Aircraft.Specs.Power.LamUps.Lnd = 0;

Aircraft.Settings.PowerOpt = 0;
Aircraft.Settings.PrintOut = 0;

SizedAircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);

RunMetadata = struct( ...
    "Branch", "emma_poweropt_update", ...
    "MissionProfile", "MissionProfilesPkg.ERJ_ClimbThenAccel", ...
    "BatterySpecificEnergy_Whkg", 250, ...
    "TakeoffElectricShare", 0.10, ...
    "ClimbEMPowerCode", 0.30, ...
    "Created", string(datetime("now")));

Metric = ["MTOW_kg"; "EmptyWeight_kg"; "BlockFuel_kg"; ...
          "BatteryWeight_kg"; "BatteryEnergy_kWh"; ...
          "ElectricMotorWeight_kg"];
% The paper reports EM power but does not report EM weight.
Paper = [41147; 23093; 9364; 996.4; 249.1; NaN];
CurrentBranch = [SizedAircraft.Specs.Weight.MTOW; ...
                 SizedAircraft.Specs.Weight.OEW; ...
                 SizedAircraft.Specs.Weight.Fuel; ...
                 SizedAircraft.Specs.Weight.Batt; ...
                 SizedAircraft.Specs.Weight.Batt * ...
                 SizedAircraft.Specs.Power.SpecEnergy.Batt / 3.6e6; ...
                 SizedAircraft.Specs.Weight.EM];
DifferencePercent = 100 .* (CurrentBranch - Paper) ./ Paper;
PaperComparison = table(Metric, Paper, CurrentBranch, DifferencePercent);

save(OutputFile, "SizedAircraft", "RunMetadata", "PaperComparison", "-v7.3");
end
