function [Aircraft] = A320Neo()
%
% [Aircraft] = A320Neo()
% written by Max Arnson, marnson@umich.edu
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 25 jun 2024
% 
% Create a model of an Airbus A320neo with a conventional propulsion
% architecture.
%
% All required inputs contain "** required **" before the description of
% the parameter to be specified. All other parameters may remain as NaN,
% and they will be filled in by a statistical regression. For improved
% accuracy, it is suggested to provide as many parameters as possible.
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
Aircraft.Specs.TLAR.EIS = 2016;

% ** required **
% aircraft class, can be either:
%     "Piston"    = piston engine
%     "Turboprop" = turboprop engine
%     "Turbofan"  = turbojet or turbofan engine
Aircraft.Specs.TLAR.Class = "Turbofan";

% ** required **
% approximate number of passengers (payload / average passenger mass)
Aircraft.Specs.TLAR.MaxPax = 15309 / 95;
 

%% VEHICLE PERFORMANCE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% takeoff speed (m/s)
Aircraft.Specs.Performance.Vels.Tko = UnitConversionPkg.ConvVel(135, "kts", "m/s");

% cruise speed (mach)
Aircraft.Specs.Performance.Vels.Crs = 0.82;

% takeoff altitude (m)
Aircraft.Specs.Performance.Alts.Tko = 0;

% cruise altitude (m)
Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(35000, "ft", "m");

% ** required **
% design range (m)
Aircraft.Specs.Performance.Range = 4815e3;

% maximum rate of climb (m/s), assumed 2,250 ft/min
Aircraft.Specs.Performance.RCMax = UnitConversionPkg.ConvLength(2250/60, "ft", "m");


%% AERODYNAMICS %%
%%%%%%%%%%%%%%%%%%

% calibration factors for lift-drag ratios
crLDcf = 1.00; % aim for +/- 10%
cbLDcf = 1.00; % aim for +/- 10%

% lift-drag ratio during climb
Aircraft.Specs.Aero.L_D.Clb = 16 * cbLDcf;

% lift-drag ratio during cruise
Aircraft.Specs.Aero.L_D.Crs = NaN; % was 18.23 * crLDcf

% assume same lift-drag ratio during climb and descent
Aircraft.Specs.Aero.L_D.Des = Aircraft.Specs.Aero.L_D.Clb;

% wing loading (kg / m^2)
Aircraft.Specs.Aero.W_S.SLS = 79000 / 126.5;


%% WEIGHTS %%
%%%%%%%%%%%%%

% maximum takeoff weight (kg)
Aircraft.Specs.Weight.MTOW = 79000;

% electric generator weight (kg)
Aircraft.Specs.Weight.EG = NaN;

% electric motor weight (kg)
Aircraft.Specs.Weight.EM = NaN;

% block fuel weight (kg)
Aircraft.Specs.Weight.Fuel = 19000;

% battery weight (kg), leave NaN for propulsion systems without batteries
Aircraft.Specs.Weight.Batt = NaN;


%% PROPULSION %%
%%%%%%%%%%%%%%%%

% ** required **
% propulsion architecture, can be either:
% "C"  = conventional
% "E"   = fully electric
% "PHE" = parallel hybrid electric
% "SHE" = series hybrid electric
% "TE"  = fully turboelectric
% "PE"  = partially turboelectric
Aircraft.Specs.Propulsion.Arch.Type = "C";

% **required** for configurations using gas-turbine engines
% get the engine model
Aircraft.Specs.Propulsion.Engine = EngineModelPkg.EngineSpecsPkg.LEAP_1A26;

% number of engines
Aircraft.Specs.Propulsion.NumEngines = 2;

% thrust-weight ratio (if a turbojet/turbofan)
Aircraft.Specs.Propulsion.T_W.SLS = 2.37e5 / (73500 * 9.81);

% total sea-level static thrust available (N)
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
Aircraft.Settings.TkoPoints = 4;
Aircraft.Settings.ClbPoints = 5;
Aircraft.Settings.CrsPoints = 5;
Aircraft.Settings.DesPoints = 5;

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
Aircraft.Settings.Plotting = 0;

% return the mission history as a table (1) or not (0)
Aircraft.Settings.Table = 0;

% flag to visualize the aircraft while sizing
Aircraft.Settings.VisualizeAircraft = 1;

% check if the aircraft should be visualized
if (Aircraft.Settings.VisualizeAircraft == 1)
    
    % connect a geometry to the aircraft
    Aircraft.Geometry.Preset = VisualizationPkg.GeometrySpecsPkg.Transport;    
    
    % specify a fuselage length
    Aircraft.Geometry.LengthSet = convlength(180, "ft", "m");
    
end

% ----------------------------------------------------------

end