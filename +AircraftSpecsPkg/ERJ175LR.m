function [Aircraft] = ERJ175LR()
%
% [Aircraft] = ERJ175LR()
% originally written for E175 by Nawa Khailany
% modified to E175LR by Paul Mokotoff, prmoko@umich.edu
% last updated: 06 jan 2026
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
Aircraft.Specs.Aero.L_D.ClbCF = 1.000; % 1.002
Aircraft.Specs.Aero.L_D.CrsCF = 1.000; % 1.000

% fuel flow calibration factor
Aircraft.Specs.Propulsion.MDotCF = 1.050; % 1.029

% airframe weight calibration factor
Aircraft.Specs.Weight.WairfCF = 1.016; % 1.018
 

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

% maximum rate of climb (m/s), assumed 2,250 ft/min (and converted)
Aircraft.Specs.Performance.RCMax = UnitConversionPkg.ConvVel(2250, "ft/min", "m/s");


%% AERODYNAMICS %%
%%%%%%%%%%%%%%%%%%

% aerodynamic analysis method
Aircraft.Specs.Aero.L_D.Method = @(Aircraft) AerodynamicsPkg.DragPolar(Aircraft);

% lift-drag ratio during climb  (assumed same as ERJ175, standard range)
Aircraft.Specs.Aero.L_D.Clb = 10.9773 * Aircraft.Specs.Aero.L_D.ClbCF;

% lift-drag ratio during cruise (assumed same as ERJ175, standard range)
Aircraft.Specs.Aero.L_D.Crs = 15.2000 * Aircraft.Specs.Aero.L_D.CrsCF;

% assume same lift-drag ratio during climb and descent
Aircraft.Specs.Aero.L_D.Des = Aircraft.Specs.Aero.L_D.Clb;

% wing loading (kg / m^2)
Aircraft.Specs.Aero.W_S.SLS = UnitConversionPkg.ConvMass(109.25, "lbm", "kg") / ...
                              (UnitConversionPkg.ConvLength(1, "ft", "m")) ^ 2;

% ----------------------------------------------------------

% scale factors for drag contributions
Aircraft.Specs.Aero.ScaleCD0 = 1;
Aircraft.Specs.Aero.ScaleCDI = 1;
Aircraft.Specs.Aero.ScaleSub = 0.8942;
Aircraft.Specs.Aero.ScaleSup = 1;
Aircraft.Specs.Aero.ScaleWnd = 1;

% get the component properties --- fuse, htail, vtail, wing, eng1, eng2
Aircraft.Specs.Aero.Components.Cf = [0.0026, 0.0026, 0.0026, 0.0026, 0.0026, 0.0026];
Aircraft.Specs.Aero.Components.Re = [2e+6, 2e+6, 2e+6, 2e+6, 2e+6, 2e+6];
Aircraft.Specs.Aero.Components.Fine = [9.8385, 0.12, 0.12, 0.12, 1.6734, 1.6734];
Aircraft.Specs.Aero.Components.Swet = [301.4080, 37.3547, 35.3073, 126.2423, 8.4248, 8.4248];
Aircraft.Specs.Aero.Components.LamFracUpper = [0, 0, 0, 0, 0, 0];
Aircraft.Specs.Aero.Components.LamFracLower = [0, 0, 0, 0, 0, 0];

% get the wing geometry and properties
Aircraft.Specs.Aero.Wing.S = 79.8322;
Aircraft.Specs.Aero.Wing.AirfoilTech = 1;

% get the excrescences drag factor
Aircraft.Specs.Aero.ExcrescencesDrag = 0.06;

% get the design conditions
Aircraft.Specs.Aero.DesignCL = 0.5;
Aircraft.Specs.Aero.DesignMach = 0.78;

% get the wing geometry
Aircraft.Specs.Aero.Wing.AR = 10.3465; % 28.74 ^ 2 / 79.8322;
Aircraft.Specs.Aero.Wing.MaxCamber = 0.02;
Aircraft.Specs.Aero.Wing.t_c = 0.12;
Aircraft.Specs.Aero.Wing.e = 0.85;
Aircraft.Specs.Aero.Wing.Sweep = 26.4413; % 26.5 - (1 - 0.2441) / (10.3465 * (1 + 0.2441))
Aircraft.Specs.Aero.Wing.TR = 0.2441; % 1.35 / 5.53;

% check option for extreme taper ratios
Aircraft.Specs.Aero.Wing.Redux = 0;

% get the vertical tail geometry
Aircraft.Specs.Aero.Vtail.AR = 3.23;
Aircraft.Specs.Aero.Vtail.e = 1;
Aircraft.Specs.Aero.Vtail.S = 17.3102;
Aircraft.Specs.Aero.Vtail.Eta = 1;
Aircraft.Specs.Aero.Vtail.TAF = 0.9;
Aircraft.Specs.Aero.Vtail.VArm = 14.6485;

% get the rudder geometry
Aircraft.Specs.Aero.Rudder.S = 4.2353;
Aircraft.Specs.Aero.Rudder.b = 5.25;

% get the fuselage geometry
Aircraft.Specs.Aero.Fuse.Area = 9.8980; % pi * (3.55 / 2) ^ 2;
Aircraft.Specs.Aero.Fuse.Len_Diam = 8.9239; % 31.68 / 3.55;
Aircraft.Specs.Aero.Fuse.Diam_Span = 0.1235; % 3.55 / 28.74;
Aircraft.Specs.Aero.Fuse.DistToEng = 3.8688; % m

% get the base area
Aircraft.Specs.Aero.BaseArea = 0;


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
Aircraft.Specs.Propulsion.PropArch.Type = "C";

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

% engine inlet areas (account for all components)
Aircraft.Specs.Propulsion.InletArea = [NaN(1, 3), repmat(1.4914, 1, 2), NaN];


%% POWER %%
%%%%%%%%%%%

% gravimetric specific energy of combustible fuel (kWh/kg)
Aircraft.Specs.Power.SpecEnergy.Fuel = 12;

% gravimetric specific energy of battery (kWh/kg), not used here
Aircraft.Specs.Power.SpecEnergy.Batt = NaN;

% downstream power splits
Aircraft.Specs.Power.LamDwn.SLS = [];
Aircraft.Specs.Power.LamDwn.Tko = [];
Aircraft.Specs.Power.LamDwn.Clb = [];
Aircraft.Specs.Power.LamDwn.Crs = [];
Aircraft.Specs.Power.LamDwn.Des = [];
Aircraft.Specs.Power.LamDwn.Lnd = [];

% upstream power splits
Aircraft.Specs.Power.LamUps.SLS = [];
Aircraft.Specs.Power.LamUps.Tko = [];
Aircraft.Specs.Power.LamUps.Clb = [];
Aircraft.Specs.Power.LamUps.Crs = [];
Aircraft.Specs.Power.LamUps.Des = [];
Aircraft.Specs.Power.LamUps.Lnd = [];

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
% (commented values used for electrified aircraft)
Aircraft.Specs.Power.Battery.ParCells = NaN;%100;
Aircraft.Specs.Power.Battery.SerCells = NaN;% 62;

% initial battery SOC (commented value used for electrified aircraft)
Aircraft.Specs.Power.Battery.BegSOC = NaN;%100;

% windmilling engines
Aircraft.Specs.Power.Windmill.Tko = 0;
Aircraft.Specs.Power.Windmill.Clb = 0;
Aircraft.Specs.Power.Windmill.Crs = 0;
Aircraft.Specs.Power.Windmill.Des = 0;
Aircraft.Specs.Power.Windmill.Lnd = 0;


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
Aircraft.Settings.Analysis.MaxIter = 30;

% analysis type, either:
%     +1 for on -design mode (aircraft performance and sizing)
%     -1 for off-design mode (aircraft performance           )
Aircraft.Settings.Analysis.Type = +1;

% plotting, either:
%     1 for plotting on
%     0 for plotting off
Aircraft.Settings.Plotting = 0;

% make a tble of mission history
%     1 for make table
%     0 for no table
Aircraft.Settings.Table = 0;

% ----------------------------------------------------------

end