function [Aircraft] = SUSAN_Simplified()
%
% [Aircraft] = Example()
% written by Paul Mokotoff, prmoko@umich.edu
% updated for SUSAN by Miranda Stockhausen, mstockha@umich.edu
% last updated: 8 Jul 2024
%
% Provide an initial SUSAN electrofan aircraft definition for the user. 
% This version is defined from the most recent update from NASA 
% (url: https://arc.aiaa.org/doi/abs/10.2514/6.2024-1326), and is used for
% aircraft sizing/performance analysis. This is the second model design
% iteration with a simplified propulsion architecture. The electric 
% generators and motors are represented as combined "electric propulsors" 
% because FAST only allows 2 consecutive power sources in a propulsion 
% architecture. 
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
Aircraft.Specs.TLAR.MaxPax = 189;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% performance parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% takeoff speed (m/s)
Aircraft.Specs.Performance.Vels.Tko = NaN;

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
Aircraft.Specs.Aero.W_S.SLS = (UnitConversionPkg.ConvForce(190890, 'lbf','N') / 9.81) / 136.57;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% weights                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
% maximum takeoff weight (kg)
Aircraft.Specs.Weight.MTOW = 86586;

% block fuel (kg)
Aircraft.Specs.Weight.Fuel = 15077;

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

% thrust-power source architecture matrix
Aircraft.Specs.Propulsion.PropArch.TSPS = eye(33);

% power-power source architecture matrix
PSPSArch = eye(33);     % identity matrix for each PS driving itself
PSPSArch(2:end,1) = 1;  % column 1: turbo drives all electric propulsors

% final PSPS architecture matrix
Aircraft.Specs.Propulsion.PropArch.PSPS = PSPSArch;

% power-energy source architecture matrix
Aircraft.Specs.Propulsion.PropArch.PSES = [1; zeros(32,1)];


% thrust source operation
Aircraft.Specs.Propulsion.Oper.TS = @() [0.35, (0.65/32) * ones(1,32)];

% thrust-power source operation
Aircraft.Specs.Propulsion.Oper.TSPS = @() eye(33); 

% power-power  source operation
Aircraft.Specs.Propulsion.Oper.PSPS = @() PSPSArch;

% power-energy source operation
Aircraft.Specs.Propulsion.Oper.PSES = @() [1; zeros(32,1)];


% efficienies: eff = [fan, electric propulsor = EM*EG, propeller]
eff = [0.99, (0.99*0.985), 0.8];

% thrust-power  source efficiency - construct via components
TSPSEff = eye(33);
TSPSEff(1) = eff(1);               % turboshaft drives fan
TSPSEff(TSPSEff==1) = eff(3);   % turboshaft drives propellers
TSPSEff(TSPSEff==0) = 1;        % 100% efficiency when no connection
% combine for final TSPS efficiency matrix
Aircraft.Specs.Propulsion.Eta.TSPS  = TSPSEff;

% power -power  source efficiency - construct via components
PSPSEff = [zeros(33,1), ones(33,32)];   % 1 if no connection|driving self
PSPSEff(1) = 1;
PSPSEff(PSPSEff == 0) = eff(2);         % turbo drives electric propulsors
% combine for final PSPS efficiency matrix
Aircraft.Specs.Propulsion.Eta.PSPS = PSPSEff;

% power -energy source efficiency
Aircraft.Specs.Propulsion.Eta.PSES = [0.5; ones(32,1)];

% energy source type (1 = fuel, 0 = battery)
Aircraft.Specs.Propulsion.PropArch.ESType = 1;

% power source type (1 = engine, 0 = electric motor)
Aircraft.Specs.Propulsion.PropArch.PSType = [1, zeros(1,32)];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion specifications  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% aircraft thrust-weight ratio
Aircraft.Specs.Propulsion.T_W.SLS = 0.298;

% total sea level static thrust (N)
Aircraft.Specs.Propulsion.Thrust.SLS = UnitConversionPkg.ConvForce(54000, "lbf", "N");

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