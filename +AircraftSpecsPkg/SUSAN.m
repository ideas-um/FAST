function [Aircraft] = SUSAN()
%
% [Aircraft] = Example()
% written by Paul Mokotoff, prmoko@umich.edu
% updated for SUSAN by Miranda Stockhausen, mstockha@umich.edu
% last updated: 14 Aug 2024
%
% Provide an initial SUSAN electrofan aircraft definition for the user. 
% This version is defined from the most recent update from NASA 
% (url: https://arc.aiaa.org/doi/abs/10.2514/6.2024-1326), and is used for
% aircraft sizing/performance analysis. This is the second major model
% diesng iteration. 
%
% Anything with a "** REQUIRED **" is an input that the user must provde.
% All other inputs can remain NaN, and a regression function will fill in
% the missing data. The more data that can be provided in this function
% will yield a more realistically sized design.
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
Aircraft.Specs.TLAR.EIS = 2040;

% ** REQUIRED ** aircraft class, either:
%     (1) "Piston"    = piston aircraft (not currently functional)
%     (2) "Turboprop" = turboprop
%     (3) "Turbofan"  = turbojet or turbofan
Aircraft.Specs.TLAR.Class = "Turbofan";
            
% ** REQUIRED ** number of passengers
Aircraft.Specs.TLAR.MaxPax = 250;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% performance parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% takeoff speed (m/s)
Aircraft.Specs.Performance.Vels.Tko = 77.2;

% cruise  speed (mach)
Aircraft.Specs.Performance.Vels.Crs = 0.785;

% takeoff altitude (m)
Aircraft.Specs.Performance.Alts.Tko = 0;

% cruise altitude (m)
Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(37000, "ft", "m");

% ** REQUIRED ** design range (m)
Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength(2500, "naut mi", "m");

% maximum rate-of-climb (m/s)
Aircraft.Specs.Performance.RCMax = NaN;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aerodynamic parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% lift-drag ratio at climb
Aircraft.Specs.Aero.L_D.Clb = NaN;

% lift-drag ratio at cruise
Aircraft.Specs.Aero.L_D.Crs = 19.7;

% lift-drag ratio at descent
Aircraft.Specs.Aero.L_D.Des = NaN;

% maximum wing loading (kg/m^2)
Aircraft.Specs.Aero.W_S.SLS = UnitConversionPkg.ConvMass(190890, 'lbm','kg') / 136.57;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% weights                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
% maximum takeoff weight (kg)
Aircraft.Specs.Weight.MTOW = UnitConversionPkg.ConvMass(190890, 'lbm','kg');

% block fuel (kg)
Aircraft.Specs.Weight.Fuel = 4722;

% landing weight (kg)
Aircraft.Specs.Weight.MLW = NaN;

% battery weight (kg)
Aircraft.Specs.Weight.Batt = NaN;

% electric motor weight (kg)
Aircraft.Specs.Weight.EM = NaN;

% electric generator weight (kg)
Aircraft.Specs.Weight.EG = NaN;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion architecture  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ** REQUIRED ** propulsion system architecture, either:
%     (1) "C"  = conventional
%     (2) "E"   = fully electric
%     (3) "TE"  = fully turboelectric
%     (4) "PE"  = partially turboelectric
%     (5) "PHE" = parallel hybrid electric
%     (6) "SHE" = series hybrid electric
%     (7) "O"   = other architecture (specified by the user)
Aircraft.Specs.Propulsion.Arch.Type = "O";

% thrust-power source matrix, built by components

% electric motors each run 1 propeller directly
A = eye(32);
% the generators do not power any propulsers directly
B = zeros(32,5);
% the turboshaft (PS1) powers only the fan (TS1)
C = zeros(1,37);
% set the first value to 1
C(1) = 1;
% construct the A + B matrix to fix scaling (32x37 matrix)
AB = [B, A];
% combine for final thrust-power source matrix
Aircraft.Specs.Propulsion.PropArch.TSPS = [C; AB];

% power-power source matrix, built by components

% electric motors each power only themselves
X = eye(32);
% driving source: turboshaft vector
A1 = [ones(5,1); zeros(32,1)];
% driving source: generator 1 drives 8 electric motors
A2 = [0; 1; 0; 0; 0; ones(8,1); zeros(24,1)];
% driving source: generator 2 drives 8 electric motors
A3 = [0; 0; 1; zeros(10,1); ones(8,1); zeros(16,1)];
% driving source: generator 3 drives 8 electric motors
A4 = [0; 0; 0; 1; zeros(17,1); ones(8,1); zeros(8,1)];
% driving source: generator 4 drives 8 electric motors
A5 = [0; 0; 0; 0; 1; zeros(24,1); ones(8,1)];
% the turboshaft is only driven by itself
B2 = zeros(5,32);
% construct power-power source matrix from components
% first five columns
Amat = [A1, A2, A3, A4, A5];
% top and body identity matrix
Bmat = [B2; X];
% final PSPS architecture matrix
Aircraft.Specs.Propulsion.PropArch.PSPS = [Amat, Bmat];

% power-energy source matrix
Aircraft.Specs.Propulsion.PropArch.PSES = [1; zeros(37,1)];


% thrust source operation
Aircraft.Specs.Propulsion.Oper.TS = @() [0.35, ones(1,32) * (0.65/32)];

% thrust-power source operation - same as architecture matrix
Aircraft.Specs.Propulsion.Oper.TSPS = @() [C; AB]; 

% power-power  source operation - same as architecture matrix
Aircraft.Specs.Propulsion.Oper.PSPS = @() [Amat, Bmat];

% power-energy source operation
Aircraft.Specs.Propulsion.Oper.PSES = @() [1; zeros(37,1)];


% thrust-power  source efficiency - construct via components
% efficienies: eff = [fan & EG (same value), EM, propeller]
eff = [0.99, 0.985, 0.8];
% column 1 for turboshaft, only directly connected to fan
CPTE1 = [eff(1); ones(32,1)]; 
% columns 2-5 for electric generators (connected to 8 EMs each)
CPTE2 = [1; (eff(2)*ones(8,1)); ones(24,1)];
CPTE3 = [ones(9,1); (eff(2)*ones(8,1)); ones(16,1)];
CPTE4 = [ones(17,1); (eff(2)*ones(8,1)); ones(8,1)];
CPTE5 = [ones(25,1); (eff(2)*ones(8,1))];
% electric motors power 1 prop each
BPTE = eff(3)*eye(32);   % set diagonal equal to required efficiency
BPTE(BPTE==0) = 1; % set non-diagonals to 1
% top row - fan is only connected to turboshaft
TPTE = ones(1,32);
% construct matrix from components
BodPTE = [TPTE; BPTE];
ColPTE = [CPTE1 CPTE2 CPTE3 CPTE4 CPTE5];

% combine for final TSPS efficiency matrix
Aircraft.Specs.Propulsion.Eta.TSPS  = [ColPTE, BodPTE];

% power -power  source efficiency - construct via components
% turboshaft connects to 4 electric generators
ColPPE1 = [1; (eff(1)*ones(4,1)); ones(32,1)];
% electric generator columns: each generator connects to 8 EMs
ColPPE2 = [ones(5,1); (eff(2)*ones(8,1)); ones(24,1)];
ColPPE3 = [ones(13,1); (eff(2)*ones(8,1)); ones(16,1)];
ColPPE4 = [ones(21,1); (eff(2)*ones(8,1)); ones(8,1)];
ColPPE5 = [ones(29,1); (eff(2)*ones(8,1))];
% combine column vectors
ColPPE = [ColPPE1 ColPPE2 ColPPE3 ColPPE4 ColPPE5];
% EMs only connect to self
BodPPE = ones(37,32);

% combine for final PSPS efficiency matrix
Aircraft.Specs.Propulsion.Eta.PSPS = [ColPPE BodPPE];

% power -energy source efficiency
% create vector of 1s of length 37x1
Aircraft.Specs.Propulsion.Eta.PSES = ones(37,1);
% correct first value to the assumed turboshaft efficiency (50%)
Aircraft.Specs.Propulsion.Eta.PSES(1) = 0.5;

% energy source type (1 = fuel, 0 = battery)
Aircraft.Specs.Propulsion.PropArch.ESType = 1;

% power source type (1 = engine, 0 = electric motor)
Aircraft.Specs.Propulsion.PropArch.PSType = [1, zeros(1,33)];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion specifications  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% aircraft thrust-weight ratio
Aircraft.Specs.Propulsion.T_W.SLS = 0.298;

% total sea level static thrust (N)
Aircraft.Specs.Propulsion.Thrust.SLS = NaN;

% engine propulSive efficiency
Aircraft.Specs.Propulsion.Eta.Prop = 0.9;

% Number of engines
Aircraft.Specs.Propulsion.NumEngines = 1;

% get the engine
Aircraft.Specs.Propulsion.Engine = EngineModelPkg.EngineSpecsPkg.LEAP_1A26;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% power specifications       %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% gravimetric specific energy of combustible fuel (kWh/kg)  
Aircraft.Specs.Power.SpecEnergy.Fuel = NaN;

% gravimetric specific energy of battery (kWh/kg)
Aircraft.Specs.Power.SpecEnergy.Batt = 1.5;

% electric motor efficiency
Aircraft.Specs.Power.Eta.EM = 0.985;

% electric generator efficiency
Aircraft.Specs.Power.Eta.EG = 0.99;

% aircraft power-weight ratio (kW/kg)
Aircraft.Specs.Power.P_W.SLS = 21000 / Aircraft.Specs.Weight.MTOW;

% electric motor power-weight ratio (kW/kg)
Aircraft.Specs.Power.P_W.EM = 20;

% electric generator power-weight ratio (kW/kg)
Aircraft.Specs.Power.P_W.EG = 25;

% number of battery cells in series and parallel
Aircraft.Specs.Power.Battery.SerCells = NaN;
Aircraft.Specs.Power.Battery.ParCells = NaN;

% initial battery state-of-charge (SOC)
Aircraft.Specs.Power.Battery.BegSOC   = NaN;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
%   Visualization settings   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% m-file preset for aircraft (if empty, single aisle twb)
Aircraft.Geometry.Preset = @(Aircraft) VisualizationPkg.GeometrySpecsPkg.SUSAN(Aircraft);
%Aircraft.Preset = NaN;

% Fuselage length (if empty, then use regression)
Aircraft.Geometry.LengthSet = UnitConversionPkg.ConvLength(140, "ft", "m");
%Aircraft.LengthSet = NaN;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% mission analysis settings  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% points in takeoff segment
Aircraft.Settings.TkoPoints = NaN;

% points in climb   segment
Aircraft.Settings.ClbPoints = NaN;

% points in cruise  segment
Aircraft.Settings.CrsPoints = NaN;

% points in descent  segment
Aircraft.Settings.DesPoints = NaN;

% maximum iterations when sizing OEW
Aircraft.Settings.OEW.MaxIter = NaN;

% convergence tolerance when sizing OEW
Aircraft.Settings.OEW.Tol = NaN;

% maximum iterations when sizing entire aircraft
Aircraft.Settings.Analysis.MaxIter = NaN;

% on design/off design analysis
% 1  = on design
% -2 = off design
Aircraft.Settings.Analysis.Type = 1;

% plot results
% 0 = no plotting
% 1 = plotting
Aircraft.Settings.Plotting = 1;

% plot visualization results
% 0 = no plotting
% 1 = plotting
Aircraft.Settings.VisualizeAircraft = 1;

% view results as a table
% 0 = no table
% 1 =    table
Aircraft.Settings.Table = 1;

% ----------------------------------------------------------

end