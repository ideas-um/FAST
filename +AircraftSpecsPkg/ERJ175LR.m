function [Aircraft] = ERJ175LR()
%
% [Aircraft] = ERJ175LR()
% originally written for E175 by Nawa Khailany
% modified to E175LR by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 oct 2024
% 
% Create a baseline model of the ERJ 175, long-range version (also known as
% an ERJ 170-200). This version uses a conventional propulsion
% architecture.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Aircraft - an aircraft structure to be used for analysis.
%                size/type/units: 1-by-1 / struct / []
%


%% TOP-LEVEL AIRCRAFT REQUIREMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% expected entry-into-service year
Aircraft.Specs.TLAR.EIS = 2005;

% ** REQUIRED **
% aircraft class, can be either:
%     'Piston'    = piston engine
%     'Turboprop' = turboprop engine
%     'Turbofan'  = turbojet or turbofan engine
Aircraft.Specs.TLAR.Class = "Turbofan";

% ** REQUIRED **
% approximate number of passengers
Aircraft.Specs.TLAR.MaxPax = 78;


%% MODEL CALIBRATION FACTORS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calibration factors for lift-drag ratios
Aircraft.Specs.Aero.L_D.ClbCF = 1.002;
Aircraft.Specs.Aero.L_D.CrsCF = 1.000;

% fuel flow calibration factor
Aircraft.Specs.Propulsion.MDotCF = 1.029;

% airframe weight calibration factor
Aircraft.Specs.Weight.WairfCF = 1.018;
 

%% VEHICLE PERFORMANCE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% takeoff speed (m/s)
Aircraft.Specs.Performance.Vels.Tko = UnitConversionPkg.ConvVel(135, "kts", "m/s");

% cruise  speed (mach)
Aircraft.Specs.Performance.Vels.Crs = 0.78; % at 35,000 ft, Mach 0.78

% takeoff altitude (m)
Aircraft.Specs.Performance.Alts.Tko = 0;

% cruise altitude (m)
Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(35000, "ft", "m");

% ** REQUIRED **
% design range (m)
Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength(2150, "naut mi", "m");

% maximum rate of climb (m/s), assumed 2,250 ft/min (and converted), Im
% seeing in literature 1944.4 ft/min
Aircraft.Specs.Performance.RCMax = UnitConversionPkg.ConvVel(2250, "ft/min", "m/s");


%% AERODYNAMICS %%
%%%%%%%%%%%%%%%%%%

% lift-drag ratio during climb  (assumed same as ERJ175, standard range)
Aircraft.Specs.Aero.L_D.Clb = 10.9773 * Aircraft.Specs.Aero.L_D.ClbCF;

% lift-drag ratio during cruise (assumed same as ERJ175, standard range)
Aircraft.Specs.Aero.L_D.Crs = 15.2000 * Aircraft.Specs.Aero.L_D.CrsCF;

% assume same lift-drag ratio during climb and descent
Aircraft.Specs.Aero.L_D.Des = Aircraft.Specs.Aero.L_D.Clb;

% wing loading (kg / m^2)
Aircraft.Specs.Aero.W_S.SLS = UnitConversionPkg.ConvMass(109.25, "lbm", "kg") / ...
                              (UnitConversionPkg.ConvLength(1, "ft", "m")) ^ 2;


%% WEIGHTS %%
%%%%%%%%%%%%%

% maximum takeoff weight (kg)
Aircraft.Specs.Weight.MTOW = UnitConversionPkg.ConvMass(85517, "lbm", "kg");

% electric generator weight (kg)
Aircraft.Specs.Weight.EG = NaN;

% electric motor weight (kg)
Aircraft.Specs.Weight.EM = 0;

% block fuel weight (kg)
Aircraft.Specs.Weight.Fuel = UnitConversionPkg.ConvMass(20785, "lbm", "kg");

% battery weight (kg), leave NaN for propulsion systems without batteries
Aircraft.Specs.Weight.Batt = 0;


%% PROPULSION %%
%%%%%%%%%%%%%%%%

% ** REQUIRED ** propulsion system architecture, either:
%     (1) "C"   = conventional
%     (2) "E"   = fully electric
%     (3) "TE"  = fully turboelectric
%     (4) "PE"  = partially turboelectric
%     (5) "PHE" = parallel hybrid electric
%     (6) "SHE" = series hybrid electric
%     (7) "O"   = other architecture (specified by the user)
Aircraft.Specs.Propulsion.Arch.Type = "PHE";

% get the engine
Aircraft.Specs.Propulsion.Engine = EngineModelPkg.EngineSpecsPkg.CF34_8E5;

% number of engines
Aircraft.Specs.Propulsion.NumEngines = 2;

% thrust-weight ratio (if a turbojet/turbofan)
Aircraft.Specs.Propulsion.T_W.SLS = 0.3393;

% total sea-level static thrust available (N)
Aircraft.Specs.Propulsion.Thrust.SLS = UnitConversionPkg.ConvForce(2 * 14510, "lbf", "N");

% engine propulsive efficiency
Aircraft.Specs.Propulsion.Eta.Prop = 0.8;


%% POWER %%
%%%%%%%%%%%

% gravimetric specific energy of combustible fuel (kWh/kg)
Aircraft.Specs.Power.SpecEnergy.Fuel = 12;

% gravimetric specific energy of battery (kWh/kg), not used here
Aircraft.Specs.Power.SpecEnergy.Batt = 0.25;

% electric motor and generator efficiencies, not used here just in HEA one
Aircraft.Specs.Power.Eta.EM = 0.96;
Aircraft.Specs.Power.Eta.EG = 0.96;

% power-weight ratio for the aircraft (kW/kg, if a turboprop)
Aircraft.Specs.Power.P_W.SLS = NaN;

% power-weight ratio for the electric motor and generator (kW/kg)
% leave as NaN if an electric motor or generator isn't in the powertrain
Aircraft.Specs.Power.P_W.EM = 10;
Aircraft.Specs.Power.P_W.EG = NaN;

% EM Power code (only works for PHE right now)
Aircraft.Specs.Power.PC.EM.Split = .8;
Aircraft.Specs.Power.PC.EM.Alt =[0, 36000];

% thrust splits (thrust / total thrust)
Aircraft.Specs.Power.LamTS.Split = 0;
Aircraft.Specs.Power.LamTS.Alt = 0;
Aircraft.Specs.Power.LamTS.SLS = 0;

% power splits between power/thrust sources (electric power / total power)
Aircraft.Specs.Power.LamTSPS.Split = .085; %{.09, .01};
Aircraft.Specs.Power.LamTSPS.Alt = 0;
Aircraft.Specs.Power.LamTSPS.SLS = 0.085; %0.09;

% power splits between power/power sources (electric power / total power)
Aircraft.Specs.Power.LamPSPS.Split = 0;
Aircraft.Specs.Power.LamPSPS.Alt = 0;
Aircraft.Specs.Power.LamPSPS.SLS = 0;

% power splits between energy/power sources (electric power / total power)
Aircraft.Specs.Power.LamPSES.Split = 0;
Aircraft.Specs.Power.LamPSES.Alt = 0;
Aircraft.Specs.Power.LamPSES.SLS = 0;

% battery cells in series and parallel
% (commented values used for electrified aircraft)
Aircraft.Specs.Power.Battery.ParCells = 100;%100;
Aircraft.Specs.Power.Battery.SerCells = 62;% 62;

% initial battery SOC (commented value used for electrified aircraft)
Aircraft.Specs.Power.Battery.BegSOC = 100;%100;

% coefficient for HEA engine analysis
Aircraft.Specs.Propulsion.Engine.HEcoeff = 1 +  Aircraft.Specs.Power.LamTSPS.SLS;


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
Aircraft.Settings.Analysis.MaxIter = 20;

% analysis type, either:
%     +1 for on -design mode (aircraft performance and sizing)
%     -1 for off-design mode (aircraft performance           )
Aircraft.Settings.Analysis.Type = +1;

% constrain SOC from 20% to 100% for off design 
Aircraft.Settings.ConSOC = 1; 

% plotting, either:
%     1 for plotting on
%     0 for plotting off
Aircraft.Settings.Plotting = 0;

% make a tble of mission history
%     1 for make table
%     0 for no table
Aircraft.Settings.Table = 1;

% sizing comamand window output
%   1 output weights
%   0 no weight output
Aircraft.Settings.PrintOut = 1;
% ----------------------------------------------------------

end