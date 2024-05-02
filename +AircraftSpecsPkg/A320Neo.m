function [Aircraft] = A320Neo()
%
% [Aircraft] = A320Neo()
% written by Max Arnson, marnson@umich.edu
% last updated: 14 feb 2024
% 
% create a baseline model of the ERJ 175, long-range version (also known as
% an ERJ 170-200). this version uses a conventional propulsion
% architecture.
%
% all required inputs contain "** required **" before the description of
% the parameter to be specified. all other parameters may remain as NaN,
% and they will be filled in by a statistical regression. for improved
% accuracy, it is suggested to provide as many parameters as possible.
%
% inputs : none     
% outputs: Aircraft - aircraft data structure to be used for analysis.
%


%% TOP-LEVEL AIRCRAFT REQUIREMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% expected entry-into-service year
Aircraft.Specs.TLAR.EIS = 2016;

% ** required **
% aircraft class, can be either:
%     'Piston'    = piston engine
%     'Turboprop' = turboprop engine
%     'Turbofan'  = turbojet or turbofan engine
Aircraft.Specs.TLAR.Class = 'Turbofan';

% ** required **
% approximate number of passengers
Aircraft.Specs.TLAR.MaxPax = 15309/95;
 

%% VEHICLE PERFORMANCE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% takeoff speed (kts)
Aircraft.Specs.Performance.Vels.Tko = UnitConversionPkg.ConvVel(135,'kts','m/s');

% cruise speed (kts)
Aircraft.Specs.Performance.Vels.Crs = 0.82;

% specified speed type, either:
%     'EAS' = equivalent airspeed
%     'TAS' = true       airspeed
Aircraft.Specs.Performance.Vels.Type = 'TAS';

% takeoff altitude (ft)
Aircraft.Specs.Performance.Alts.Tko =     0;

% cruise altitude (ft)
Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(35000,'ft','m');

% ** required **
% design range (nmi)
Aircraft.Specs.Performance.Range = 4815e3;

% maximum rate of climb (ft/s), assumed 2,250 ft/min
Aircraft.Specs.Performance.RCMax = UnitConversionPkg.ConvLength(2250/60,'ft','m');


%% AERODYNAMICS %%
%%%%%%%%%%%%%%%%%%

% calibration factors for lift-drag ratios
crLDcf = 1.00; % aim for +/- 10%
cbLDcf = 1.00; % aim for +/- 10%

% lift-drag ratio during climb  (assumed same as ERJ175, standard range)
Aircraft.Specs.Aero.L_D.Clb = 16 * cbLDcf;

% lift-drag ratio during cruise (assumed same as ERJ175, standard range)
Aircraft.Specs.Aero.L_D.Crs = NaN; %18.23 * crLDcf;

% assume same lift-drag ratio during climb and descent
Aircraft.Specs.Aero.L_D.Des = Aircraft.Specs.Aero.L_D.Clb;

% wing loading (lbf / ft^2)
Aircraft.Specs.Aero.W_S.SLS = 79000/126.5;


%% WEIGHTS %%
%%%%%%%%%%%%%

% maximum takeoff weight (lbm)
Aircraft.Specs.Weight.MTOW = 79000;

% electric generator weight (lbm)
Aircraft.Specs.Weight.EG = NaN;

% electric motor weight (lbm)
Aircraft.Specs.Weight.EM = NaN;

% block fuel weight (lbm)
Aircraft.Specs.Weight.Fuel = 19000;

% battery weight (lbm), leave NaN for propulsion systems without batteries
Aircraft.Specs.Weight.Batt = NaN;


%% PROPULSION %%
%%%%%%%%%%%%%%%%

% ** required **
% propulsion architecture, can be either:
% 'AC'  = conventional
% 'E'   = fully electric
% 'PHE' = parallel hybrid electric
% 'SHE' = series hybrid electric
% 'TE'  = fully turboelectric
% 'PE'  = partially turboelectric
Aircraft.Specs.Propulsion.Arch.Type = "C";

% get the engine
Aircraft.Specs.Propulsion.Engine = EngineModelPkg.EngineSpecsPkg.LEAP_1A26;

% number of engines
Aircraft.Specs.Propulsion.NumEngines = 2;

% thrust-weight ratio (if a turbojet/turbofan)
Aircraft.Specs.Propulsion.T_W.SLS = 2.37e5/(73500*9.81);

% total sea-level static thrust available (lbf)
Aircraft.Specs.Propulsion.Thrust.SLS = 2.37e5;

% engine propulsive efficiency
Aircraft.Specs.Propulsion.Eta.Prop = 0.8;


%% POWER %%
%%%%%%%%%%%

% gravimetric specific energy of combustible fuel (kWh/kg)
Aircraft.Specs.Power.SpecEnergy.Fuel = 12;

% gravimetric specific energy of battery (kWh/kg), not used here
Aircraft.Specs.Power.SpecEnergy.Batt = NaN;

% electric motor and generator efficiencies, not used here just in HEA one
Aircraft.Specs.Power.Eta.EM = NaN;
Aircraft.Specs.Power.Eta.EG = NaN;

% power-weight ratio for the aircraft (kW/kg, if a turboprop)
Aircraft.Specs.Power.P_W.SLS = NaN;

% power-weight ratio for the electric motor and generator (kW/kg)
% leave as NaN if an electric motor or generator isn't in the powertrain
Aircraft.Specs.Power.P_W.EM = NaN;
Aircraft.Specs.Power.P_W.EG = NaN;

% thrust splits (thrust / total thrust)
Aircraft.Specs.Power.LamTS.Tko = 0;
Aircraft.Specs.Power.LamTS.Clb = 0;
Aircraft.Specs.Power.LamTS.Crs = 0;
Aircraft.Specs.Power.LamTS.Des = 0;
Aircraft.Specs.Power.LamTS.Lnd = 0;
Aircraft.Specs.Power.LamTS.SLS = 0;

% power splits between power/thrust sources (electric power / total power)
Aircraft.Specs.Power.LamTSPS.Tko = 0;
Aircraft.Specs.Power.LamTSPS.Clb = 0;
Aircraft.Specs.Power.LamTSPS.Crs = 0;
Aircraft.Specs.Power.LamTSPS.Des = 0;
Aircraft.Specs.Power.LamTSPS.Lnd = 0;
Aircraft.Specs.Power.LamTSPS.SLS = 0;

% power splits between power/power sources (electric power / total power)
Aircraft.Specs.Power.LamPSPS.Tko = 0;
Aircraft.Specs.Power.LamPSPS.Clb = 0;
Aircraft.Specs.Power.LamPSPS.Crs = 0;
Aircraft.Specs.Power.LamPSPS.Des = 0;
Aircraft.Specs.Power.LamPSPS.Lnd = 0;
Aircraft.Specs.Power.LamPSPS.SLS = 0;

% power splits between energy/power sources (electric power / total power)
Aircraft.Specs.Power.LamPSES.Tko = 0;
Aircraft.Specs.Power.LamPSES.Clb = 0;
Aircraft.Specs.Power.LamPSES.Crs = 0;
Aircraft.Specs.Power.LamPSES.Des = 0;
Aircraft.Specs.Power.LamPSES.Lnd = 0;
Aircraft.Specs.Power.LamPSES.SLS = 0;

% battery cells in series and parallel 
Aircraft.Specs.Power.Battery.ParCells = NaN;
Aircraft.Specs.Power.Battery.SerCells = NaN;

% initial battery SOC
Aircraft.Specs.Power.Battery.BegSOC = NaN;


%% SETTINGS (LEAVE AS NaN FOR DEFAULTS) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% number of control points in each segment
Aircraft.Settings.TkoPoints = NaN;
Aircraft.Settings.ClbPoints = NaN;
Aircraft.Settings.CrsPoints = NaN;
Aircraft.Settings.DesPoints = NaN;

% maximum number of iterations during oew estimation
Aircraft.Settings.OEW.MaxIter = 50;

% oew relative tolerance for convergence
Aircraft.Settings.OEW.Tol = 0.001;

% maximum number of iterations during aircraft sizing
Aircraft.Settings.Analysis.MaxIter = 50;

% analysis type, either:
%     +1 for on -design mode (aircraft performance and sizing)
%     -1 for off-design mode (aircraft performance           )
Aircraft.Settings.Analysis.Type = +1;

% plotting, either:
%     1 for plotting on
%     0 for plotting off
Aircraft.Settings.Plotting = 1;

Aircraft.Settings.Table = 0;

Aircraft.Settings.VisualizeAircraft = 0;

% ----------------------------------------------------------

end