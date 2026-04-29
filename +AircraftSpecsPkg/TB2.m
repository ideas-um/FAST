function [Aircraft] = TB2()
%
% [Aircraft] = RQ_7AShadow()
% written by emma cassidy, emmasmit@umich.edu
% last updated: 24 apr 2026
% 
% model Bayraktar TB2 gas powered UAV
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Aircraft - aircraft data structure to be used for analysis
%                size/type/units: 1-by-1 / struct / []
%


%% TOP-LEVEL AIRCRAFT REQUIREMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% expected entry-into-service year
Aircraft.Specs.TLAR.EIS = 2035;

% ** required **
% aircraft class, can be either:
%     "Piston"    = piston engine
%     "Turboprop" = turboprop engine
%     "Turbofan"  = turbojet or turbofan engine
%     "UAV"       = uncrewed aerial vehicle
Aircraft.Specs.TLAR.Class = "UAV";

% % ** required **
% payload (kg)
Aircraft.Specs.Weight.Payload = 150;


%% MODEL CALIBRATION FACTORS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% overall efficiency:
% product of L/D and propeller efficiency for conventional UAVs
% product of L/D, propeller efficiency, and EM efficiency for electric UAVs
Aircraft.Specs.Performance.EtaOv = 2.55;

% OEW weight calibration factor
Aircraft.Specs.Weight.WairfCF = 1;
 

%% VEHICLE PERFORMANCE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% cruise speed (mach)
Aircraft.Specs.Performance.Vels.Crs = 36/343;

% cruise altitude (m)
Aircraft.Specs.Performance.Alts.Crs = 6000;

% endurance (min)
Aircraft.Specs.Performance.Endurance = 20*60;


%% AERODYNAMICS %%
%%%%%%%%%%%%%%%%%%

% lift-drag ratio during cruise 
Aircraft.Specs.Aero.L_D.Crs = 12; 

% wing loading (kg/m^2)
Aircraft.Specs.Aero.W_S.SLS = 7;


%% WEIGHTS %%
%%%%%%%%%%%%%

% maximum takeoff weight (kg)
Aircraft.Specs.Weight.MTOW = 700;

% block fuel weight (kg)
Aircraft.Specs.Weight.Fuel = 210;

% battery weight (kg)
Aircraft.Specs.Weight.Batt = 0;

% OEW (kg)
Aircraft.Specs.Weight.OEW = 340;

% crew weight (kg)
Aircraft.Specs.Weight.Crew = 0;


%% PROPULSION %%
%%%%%%%%%%%%%%%%

% ** required **
% propulsion architecture, can be either:
% "C"  = conventional
% "E"   = fully electric
Aircraft.Specs.Propulsion.PropArch.Type = "C";

% ** required **
% number of engines
Aircraft.Specs.Propulsion.NumEngines = 1;

% set the BSFC (kg/kW/hr)
Aircraft.Specs.Propulsion.SFC = 0.14;


%% POWER %%
%%%%%%%%%%%

% gravimetric specific energy of combustible fuel (kWh/kg)
Aircraft.Specs.Power.SpecEnergy.Fuel = 12;

% gravimetric specific energy of battery (kWh/kg), not used here
Aircraft.Specs.Power.SpecEnergy.Batt = 0.25;

% battery cells in series and parallel 
Aircraft.Specs.Power.Battery.ParCells = NaN;
Aircraft.Specs.Power.Battery.SerCells = NaN;

% initial battery SOC
Aircraft.Specs.Power.Battery.BegSOC = NaN;


%% SETTINGS (LEAVE AS NaN FOR DEFAULTS) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% maximum number of iterations during oew estimation
Aircraft.Settings.OEW.MaxIter = 50;

% oew relative tolerance for convergence
Aircraft.Settings.OEW.Tol = 0.001;

% maximum number of iterations during aircraft sizing
Aircraft.Settings.Analysis.MaxIter = 50;

% analysis type, either:
%     +1 for on -design mode (aircraft performance and sizing)
%     -1 for off-design mode (aircraft performance           )
Aircraft.Settings.Analysis.Type = 1;

% plotting, either:
%     1 for plotting on
%     0 for plotting off
Aircraft.Settings.Plotting = 0;

% return the mission history as a table (1) or not (0)
Aircraft.Settings.Table = 0;

% flag to visualize the aircraft while sizing
Aircraft.Settings.VisualizeAircraft = 0;

% initial set of cruise points
Aircraft.Settings.CrsPoints = 10;

% ----------------------------------------------------------

end