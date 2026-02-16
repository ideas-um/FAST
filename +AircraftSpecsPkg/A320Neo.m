function [Aircraft] = A320Neo()
%
% [Aircraft] = A320Neo()
% written by Max Arnson, marnson@umich.edu and Yi-Chih Wang,
% ycwangd@umich.edu
% last updated: 16 feb 2026
% 
% create a baseline model of the A320neo WV054. this version uses a 
% conventional propulsion architecture.
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


%% MODEL CALIBRATION FACTORS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calibration factors for lift-drag ratios
Aircraft.Specs.Aero.L_D.ClbCF = 1;
Aircraft.Specs.Aero.L_D.CrsCF = 1;

% fuel flow calibration factor
Aircraft.Specs.Propulsion.MDotCF = 1.092;

% airframe weight calibration factor
Aircraft.Specs.Weight.WairfCF = 0.993;
 

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

% aerodynamic analysis method
Aircraft.Specs.Aero.L_D.Method = @(Aircraft) AerodynamicsPkg.DragPolar(Aircraft);

% lift-drag ratio during climb  
Aircraft.Specs.Aero.L_D.Clb = 16 * Aircraft.Specs.Aero.L_D.ClbCF;

% lift-drag ratio during cruise 
Aircraft.Specs.Aero.L_D.Crs = 18.23 * Aircraft.Specs.Aero.L_D.CrsCF;

% assume same lift-drag ratio during climb and descent
Aircraft.Specs.Aero.L_D.Des = Aircraft.Specs.Aero.L_D.Clb;

% wing loading (kg / m^2)
Aircraft.Specs.Aero.W_S.SLS = 79000 / 126.5;

% ----------------------------------------------------------

% scale factors for drag contributions
Aircraft.Specs.Aero.ScaleCD0 = 1;
Aircraft.Specs.Aero.ScaleCDI = 1;
Aircraft.Specs.Aero.ScaleSub = 0.8016;
Aircraft.Specs.Aero.ScaleSup = 1;
Aircraft.Specs.Aero.ScaleWnd = 1;

% get the component properties --- fuse, htail, vtail, wing, eng1, eng2
Aircraft.Specs.Aero.Components.Cf = [0.0026, 0.0026, 0.0026, 0.0026, 0.0026, 0.0026];
Aircraft.Specs.Aero.Components.Re = [2e+6, 2e+6, 2e+6, 2e+6, 2e+6, 2e+6];
Aircraft.Specs.Aero.Components.Fine = [9.5114, 0.12, 0.12, 0.12, 1.5928, 1.5928];
Aircraft.Specs.Aero.Components.Swet = [441.0079, 49.1499, 46.6784, 200.0672, 17.4970, 17.4970];
Aircraft.Specs.Aero.Components.LamFracUpper = [0, 0, 0, 0, 0, 0];
Aircraft.Specs.Aero.Components.LamFracLower = [0, 0, 0, 0, 0, 0];

% get the wing geometry and properties
Aircraft.Specs.Aero.Wing.S = 126.5;
Aircraft.Specs.Aero.Wing.AirfoilTech = 1;

% get the excrescences drag factor
Aircraft.Specs.Aero.ExcrescencesDrag = 0.06;

% get the design conditions
Aircraft.Specs.Aero.DesignCL = 0.5;
Aircraft.Specs.Aero.DesignMach = 0.82;

% get the wing geometry
Aircraft.Specs.Aero.Wing.AR = 10.1315; % 35.80 ^ 2 / 126.5;
Aircraft.Specs.Aero.Wing.MaxCamber = 0.02;
Aircraft.Specs.Aero.Wing.t_c = 0.12;
Aircraft.Specs.Aero.Wing.e = 0.85;
Aircraft.Specs.Aero.Wing.Sweep = 26.9085;
Aircraft.Specs.Aero.Wing.TR = 0.2702; % 1.64 / 6.07

% check option for extreme taper ratios
Aircraft.Specs.Aero.Wing.Redux = 0;

% get the vertical tail geometry
Aircraft.Specs.Aero.Vtail.AR = 3.38;
Aircraft.Specs.Aero.Vtail.e = 1;
Aircraft.Specs.Aero.Vtail.S = 22.7550;
Aircraft.Specs.Aero.Vtail.Eta = 1;
Aircraft.Specs.Aero.Vtail.TAF = 0.9;
Aircraft.Specs.Aero.Vtail.VArm = 17.24;

% get the rudder geometry
Aircraft.Specs.Aero.Rudder.S = 6.519;
Aircraft.Specs.Aero.Rudder.b = 6.068;

% get the fuselage geometry
Aircraft.Specs.Aero.Fuse.Area = 13.4614; % pi * (4.14 / 2) ^ 2;
Aircraft.Specs.Aero.Fuse.Len_Diam = 9.0749; % 37.57 / 4.14;
Aircraft.Specs.Aero.Fuse.Diam_Span = 0.1156; % 4.14 / 35.80;
Aircraft.Specs.Aero.Fuse.DistToEng = 5.701; % m

% get the base area
Aircraft.Specs.Aero.BaseArea = 0;


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
Aircraft.Specs.Propulsion.PropArch.Type = "C";

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

% engine inlet areas (account for all components)
Aircraft.Specs.Propulsion.InletArea = [NaN(1, 3), repmat(1.9831, 1, 2), NaN];


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

% battery cells in series and parallel 
Aircraft.Specs.Power.Battery.ParCells = NaN;
Aircraft.Specs.Power.Battery.SerCells = NaN;

% initial battery SOC
Aircraft.Specs.Power.Battery.BegSOC = NaN;

% windmilling engines
Aircraft.Specs.Power.Windmill.Tko = 0;
Aircraft.Specs.Power.Windmill.Clb = 0;
Aircraft.Specs.Power.Windmill.Crs = 0;
Aircraft.Specs.Power.Windmill.Des = 0;
Aircraft.Specs.Power.Windmill.Lnd = 0;


%% SETTINGS (LEAVE AS NaN FOR DEFAULTS) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% number of control points in each segment
Aircraft.Settings.TkoPoints = 10;
Aircraft.Settings.ClbPoints = 10;
Aircraft.Settings.CrsPoints = 10;
Aircraft.Settings.DesPoints = 10;

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

% check if the aircraft should be visualized
if (Aircraft.Settings.VisualizeAircraft == 1)
    
    % connect a geometry to the aircraft
    Aircraft.Geometry.Preset = VisualizationPkg.GeometrySpecsPkg.Transport;    
    
    % specify a fuselage length
    Aircraft.Geometry.LengthSet = convlength(180, "ft", "m");
    
end

% ----------------------------------------------------------

end