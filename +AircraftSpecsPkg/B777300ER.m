function [Aircraft] = B777300ER()
%
% [Aircraft] = B777300ER()
%
% Create a baseline Boeing 777-300ER model for sizing/performance analysis.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Aircraft - aircraft structure to be used for analysis.
%                size/type/units: 1-by-1 / struct / []
%


%% TOP-LEVEL AIRCRAFT REQUIREMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% expected entry-into-service year
Aircraft.Specs.TLAR.EIS = 2004;

% aircraft class
Aircraft.Specs.TLAR.Class = "Turbofan";

% typical two-class passengers
Aircraft.Specs.TLAR.MaxPax = 396;


%% MODEL CALIBRATION FACTORS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calibration factors for lift-drag ratios
Aircraft.Specs.Aero.L_D.ClbCF = 1.000;
Aircraft.Specs.Aero.L_D.CrsCF = 1.000;

% fuel flow calibration factor
Aircraft.Specs.Propulsion.MDotCF = 1.000;

% airframe weight calibration factor
Aircraft.Specs.Weight.WairfCF = 1.000;


%% VEHICLE PERFORMANCE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% takeoff speed (m/s)
Aircraft.Specs.Performance.Vels.Tko = UnitConversionPkg.ConvVel(170, "kts", "m/s");

% cruise speed (mach)
Aircraft.Specs.Performance.Vels.Crs = 0.84;

% takeoff altitude (m)
Aircraft.Specs.Performance.Alts.Tko = 0;

% service ceiling used by the standard turbofan mission profile (m)
Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(40000, "ft", "m");

% design range (m)
Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength(7370, "naut mi", "m");

% maximum rate of climb (m/s)
Aircraft.Specs.Performance.RCMax = UnitConversionPkg.ConvVel(2000, "ft/min", "m/s");


%% AERODYNAMICS %%
%%%%%%%%%%%%%%%%%%

% aerodynamic analysis method
Aircraft.Specs.Aero.L_D.Method = @(Aircraft) AerodynamicsPkg.ConstantLD(Aircraft);

% lift-drag ratio during climb
Aircraft.Specs.Aero.L_D.Clb = 14.5 * Aircraft.Specs.Aero.L_D.ClbCF;

% lift-drag ratio during cruise
Aircraft.Specs.Aero.L_D.Crs = 19.0 * Aircraft.Specs.Aero.L_D.CrsCF;

% lift-drag ratio during descent
Aircraft.Specs.Aero.L_D.Des = Aircraft.Specs.Aero.L_D.Clb;

% wing loading (kg / m^2)
Aircraft.Specs.Aero.W_S.SLS = 695.5;

% ----------------------------------------------------------

% scale factors for drag contributions
Aircraft.Specs.Aero.ScaleCD0 = 1;
Aircraft.Specs.Aero.ScaleCDI = 1;
Aircraft.Specs.Aero.ScaleSub = 1;
Aircraft.Specs.Aero.ScaleSup = 1;
Aircraft.Specs.Aero.ScaleWnd = 1;

% simplified component properties for drag polar compatibility if requested
Aircraft.Specs.Aero.Components.Cf = [0.0026, 0.0026, 0.0026, 0.0026, 0.0026, 0.0026];
Aircraft.Specs.Aero.Components.Re = [2e+6, 2e+6, 2e+6, 2e+6, 2e+6, 2e+6];
Aircraft.Specs.Aero.Components.Fine = [10.0, 0.12, 0.12, 0.12, 1.7, 1.7];
Aircraft.Specs.Aero.Components.Swet = [1200, 130, 110, 437, 30, 30];
Aircraft.Specs.Aero.Components.LamFracUpper = [0, 0, 0, 0, 0, 0];
Aircraft.Specs.Aero.Components.LamFracLower = [0, 0, 0, 0, 0, 0];

% wing geometry and properties
Aircraft.Specs.Aero.Wing.S = 500;
Aircraft.Specs.Aero.Wing.AirfoilTech = 1;
Aircraft.Specs.Aero.Wing.AR = 9.8;
Aircraft.Specs.Aero.Wing.MaxCamber = 0.02;
Aircraft.Specs.Aero.Wing.t_c = 0.12;
Aircraft.Specs.Aero.Wing.e = 0.85;
Aircraft.Specs.Aero.Wing.Sweep = 31.6;
Aircraft.Specs.Aero.Wing.TR = 0.15;
Aircraft.Specs.Aero.Wing.Redux = 0;

% tail and fuselage placeholders for optional geometry/drag tools
Aircraft.Specs.Aero.Vtail.AR = 1.8;
Aircraft.Specs.Aero.Vtail.e = 1;
Aircraft.Specs.Aero.Vtail.S = 80;
Aircraft.Specs.Aero.Vtail.Eta = 1;
Aircraft.Specs.Aero.Vtail.TAF = 0.9;
Aircraft.Specs.Aero.Vtail.VArm = 33;
Aircraft.Specs.Aero.Rudder.S = 20;
Aircraft.Specs.Aero.Rudder.b = 10;
Aircraft.Specs.Aero.Fuse.Area = 30.2;
Aircraft.Specs.Aero.Fuse.Len_Diam = 12.2;
Aircraft.Specs.Aero.Fuse.Diam_Span = 0.095;
Aircraft.Specs.Aero.Fuse.DistToEng = 10;
Aircraft.Specs.Aero.BaseArea = 0;
Aircraft.Specs.Aero.ExcrescencesDrag = 0.06;
Aircraft.Specs.Aero.DesignCL = 0.5;
Aircraft.Specs.Aero.DesignMach = 0.84;


%% WEIGHTS %%
%%%%%%%%%%%%%

% maximum takeoff weight (kg)
Aircraft.Specs.Weight.MTOW = 351530;

% block fuel weight (kg)
Aircraft.Specs.Weight.Fuel = 145540;

% landing weight (kg)
Aircraft.Specs.Weight.MLW = NaN;

% electric generator weight (kg)
Aircraft.Specs.Weight.EG = NaN;

% electric motor weight (kg)
Aircraft.Specs.Weight.EM = 0;

% battery weight (kg)
Aircraft.Specs.Weight.Batt = 0;


%% PROPULSION %%
%%%%%%%%%%%%%%%%

% propulsion system architecture
Aircraft.Specs.Propulsion.PropArch.Type = "C";

% engine
Aircraft.Specs.Propulsion.Engine = EngineModelPkg.EngineSpecsPkg.GE90_115B;

% number of engines
Aircraft.Specs.Propulsion.NumEngines = 2;

% total sea-level static thrust available (N)
Aircraft.Specs.Propulsion.Thrust.SLS = 2 * UnitConversionPkg.ConvForce(115300, "lbf", "N");

% thrust-weight ratio
Aircraft.Specs.Propulsion.T_W.SLS = Aircraft.Specs.Propulsion.Thrust.SLS / ...
                                    (Aircraft.Specs.Weight.MTOW * 9.80665);

% engine propulsive efficiency
Aircraft.Specs.Propulsion.Eta.Prop = 0.8;

% engine inlet areas (account for all components)
Aircraft.Specs.Propulsion.InletArea = [NaN(1, 3), repmat(8.30, 1, 2), NaN];


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

% electric motor and generator efficiencies, not used here
Aircraft.Specs.Power.Eta.EM = NaN;
Aircraft.Specs.Power.Eta.EG = NaN;

% power-weight ratio for the aircraft (kW/kg, if a turboprop)
Aircraft.Specs.Power.P_W.SLS = NaN;

% power-weight ratio for the electric motor and generator
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


%% BATTERY %%
%%%%%%%%%%%%%

% nominal cell voltage (V)
Aircraft.Specs.Battery.NomVolCell = 3.6;

% maximum extracted voltage (V)
Aircraft.Specs.Battery.MaxExtVolCell = 4.0880;

% maximum cell capacity (Ah)
Aircraft.Specs.Battery.CapCell = 3;

% internal resistance (Ohm)
Aircraft.Specs.Battery.IntResist = 0.0199;

% exponential voltage (V)
Aircraft.Specs.Battery.ExpVol = 0.0986;

% exponential capacity ((Ah)^-1)
Aircraft.Specs.Battery.ExpCap = 30;

% acceptable SOC threshold
Aircraft.Specs.Battery.MinSOC = 20;

% initial SOC
Aircraft.Specs.Battery.BegSOC = 100;

% acceptable max c-rate during discharging
Aircraft.Specs.Battery.MaxAllowCRate = 5;

% charging rate
Aircraft.Specs.Battery.Charging = 500 * 1000;

% battery degradation effect analysis
Aircraft.Specs.Battery.Degradation = 0;


%% SETTINGS %%
%%%%%%%%%%%%%%

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

% analysis type, either +1 for on-design or -1 for off-design
Aircraft.Settings.Analysis.Type = +1;

% plotting off for automated runs
Aircraft.Settings.Plotting = 0;

% mission history table off
Aircraft.Settings.Table = 0;

% visualization off
Aircraft.Settings.VisualizeAircraft = 0;

% geometry preset
Aircraft.Geometry.Preset = @(Aircraft) VisualizationPkg.GeometrySpecsPkg.SmallDoubleAisleTurbofan(Aircraft);

% ----------------------------------------------------------

end
