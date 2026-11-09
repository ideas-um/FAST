function [Aircraft] = ATR42_PHE()
%
% [Aircraft] = ATR42_PHE()
%
% Define a parallel-hybrid-electric ATR 42 using a detailed battery-cell
% model and a fixed electric power split throughout the mission.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Aircraft - an aircraft structure to be used for analysis.
%                size/type/units: 1-by-1 / struct / []
%


%% INPUT VALUES %%
%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% top-level aircraft         %
% requirements               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% expected entry-into-service year
Aircraft.Specs.TLAR.EIS = NaN;

% aircraft class
Aircraft.Specs.TLAR.Class = "Turboprop";

% number of passengers
Aircraft.Specs.TLAR.MaxPax = 48;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% performance parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% takeoff speed (m/s)
Aircraft.Specs.Performance.Vels.Tko = NaN;

% cruise speed (mach)
Aircraft.Specs.Performance.Vels.Crs = 0.4;

% takeoff altitude (m)
Aircraft.Specs.Performance.Alts.Tko = NaN;

% cruise altitude (m)
Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(25000, "ft", "m");

% design range (m)
Aircraft.Specs.Performance.Range = 1326e3;

% maximum rate-of-climb (m/s)
Aircraft.Specs.Performance.RCMax = UnitConversionPkg.ConvVel(1475/60, "ft/s", "m/s");

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aerodynamic parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% aerodynamic analysis method
Aircraft.Specs.Aero.L_D.Method = @(Aircraft) AerodynamicsPkg.ConstantLD(Aircraft);

% lift-drag ratios
Aircraft.Specs.Aero.L_D.Clb = 10;
Aircraft.Specs.Aero.L_D.Crs = 12;
Aircraft.Specs.Aero.L_D.Des = NaN;

% maximum wing loading (kg/m^2)
Aircraft.Specs.Aero.W_S.SLS = 342;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% weights                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% baseline weights (kg); hybrid component weights are sized by FAST
Aircraft.Specs.Weight.MTOW = 18600;
Aircraft.Specs.Weight.Fuel = 4500;
Aircraft.Specs.Weight.MLW = NaN;
Aircraft.Specs.Weight.Batt = NaN;
Aircraft.Specs.Weight.EM = NaN;
Aircraft.Specs.Weight.EG = NaN;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion system          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parallel-hybrid-electric propulsion architecture
Aircraft.Specs.Propulsion.PropArch.Type = "PHE";

% aircraft thrust-weight ratio and total sea-level static power
Aircraft.Specs.Propulsion.T_W.SLS = NaN;
Aircraft.Specs.Power.SLS = NaN;

% engine and propeller specifications
Aircraft.Specs.Propulsion.Eta.Prop = 0.8;
Aircraft.Specs.Propulsion.NumEngines = 2;
Aircraft.Specs.Propulsion.Engine = EngineModelPkg.EngineSpecsPkg.PW_127M;
Aircraft.Specs.Power.Eta.Propeller = 0.8;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% power specifications       %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% gravimetric specific energy of combustible fuel (kWh/kg)
Aircraft.Specs.Power.SpecEnergy.Fuel = (43.2e+6) / (3.6e+6);

% battery specific-energy sweep point: 500 Wh/kg = 0.5 kWh/kg
Aircraft.Specs.Power.SpecEnergy.Batt = 0.5;

% A single prescribed split keeps 10% of propulsive power electric in
% every mission segment. Change this scalar to evaluate another fixed split.
FixedPowerSplit = 0.1;
Aircraft.Specs.Power.LamDwn.SLS = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Tko = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Clb = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Crs = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Des = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Lnd = FixedPowerSplit;

% The PHE architecture's upstream split is unity whenever the electric
% branch is active; LamDwn above determines the gas/electric power share.
Aircraft.Specs.Power.LamUps.SLS = 1;
Aircraft.Specs.Power.LamUps.Tko = 1;
Aircraft.Specs.Power.LamUps.Clb = 1;
Aircraft.Specs.Power.LamUps.Crs = 1;
Aircraft.Specs.Power.LamUps.Des = 1;
Aircraft.Specs.Power.LamUps.Lnd = 1;

% electric-machine assumptions
Aircraft.Specs.Power.Eta.EM = 0.96;
Aircraft.Specs.Power.Eta.EG = 0.96;
Aircraft.Specs.Power.P_W.SLS = 0.1731;
Aircraft.Specs.Power.P_W.EM = 10;
Aircraft.Specs.Power.P_W.EG = NaN;

% detailed battery pack configuration and initial state of charge
Aircraft.Specs.Power.Battery.SerCells = 62;
Aircraft.Specs.Power.Battery.ParCells = 100;
Aircraft.Specs.Power.Battery.BegSOC = 100;

% detailed cell model
Aircraft.Specs.Battery.NomVolCell = 3.6;
Aircraft.Specs.Battery.CapCell = 3;
Aircraft.Specs.Battery.MaxExtVolCell = 4.088;
Aircraft.Specs.Battery.IntResist = 0.0199;
Aircraft.Specs.Battery.MinSOC = 20;
Aircraft.Specs.Battery.BegSOC = 100;
Aircraft.Specs.Battery.MaxAllowCRate = 5;

% Shepherd-model curve parameters retained from FAST's detailed-cell model
Aircraft.Specs.Battery.ExpVol = 0.0986;
Aircraft.Specs.Battery.ExpCap = 30;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% mission analysis           %
% properties                 %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% use the supplied fixed power split instead of recomputing it by segment
Aircraft.Settings.PowerManagement.Mode = "SupplyLambda";

% on-design analysis
Aircraft.Settings.Analysis.Type = +1;

% plot results
Aircraft.Settings.Plotting = 0;

% ----------------------------------------------------------

end
