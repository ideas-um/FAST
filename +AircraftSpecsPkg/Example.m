function [Aircraft] = Example()
%
% [Aircraft] = Example()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 31 may 2024
%
% Provide an example aircraft definition for the user. Here, the Embraer 
% E190-E2 is defined from "Advanced 2030 Single Aisle Aircraft Modeling for
% the Electrified Powertrain Flight Demonstration Program", and is used for
% aircraft sizing/performance analysis.
%
% Anything with a "** REQUIRED **" is an input that the user must provde.
% All other inputs can remain NaN, and a regression function will fill in
% the missing data. The more data that can be provided in this function
% will yield a more realistically sized design.
%
% See AircraftSpecsPkg.README for a comprehensive review of building
% aircraft specification files
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

% ** REQUIRED ** aircraft class, either:
%     (1) "Piston"    = piston aircraft (not currently functional)
%     (2) "Turboprop" = turboprop
%     (3) "Turbofan"  = turbojet or turbofan
Aircraft.Specs.TLAR.Class = "Turbofan";
            
% ** REQUIRED ** number of passengers
Aircraft.Specs.TLAR.MaxPax = 100;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% performance parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% takeoff speed (m/s)
Aircraft.Specs.Performance.Vels.Tko = UnitConversionPkg.ConvVel(135, "kts", "m/s");

% cruise  speed (mach)
Aircraft.Specs.Performance.Vels.Crs = 0.8;

% takeoff altitude (m)
Aircraft.Specs.Performance.Alts.Tko = 0;

% cruise altitude (m)
Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(35000, "ft", "m");

% ** REQUIRED ** design range (m)
Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength(3350, "naut mi", "m");

% maximum rate-of-climb (m/s)
Aircraft.Specs.Performance.RCMax = UnitConversionPkg.ConvVel(2000/60, "ft/s", "m/s");

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aerodynamic parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% lift-drag ratio at climb
Aircraft.Specs.Aero.L_D.Clb = 10.936;

% lift-drag ratio at cruise
Aircraft.Specs.Aero.L_D.Crs = 18.227;

% lift-drag ratio at descent
Aircraft.Specs.Aero.L_D.Des = 10.936;

% maximum wing loading (kg/m^2)
Aircraft.Specs.Aero.W_S.SLS = UnitConversionPkg.ConvMass(  112.56, "lbm", "kg") / ...
                              UnitConversionPkg.ConvLength(  1   , "ft" ,  "m") ^ 2    ;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% weights                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
% maximum takeoff weight (kg)
Aircraft.Specs.Weight.MTOW = UnitConversionPkg.ConvMass(124341, "lbm", "kg");

% block fuel (kg)
Aircraft.Specs.Weight.Fuel = UnitConversionPkg.ConvMass(27452, "lbm", "kg");

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
% propulsion specifications  %
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
Aircraft.Specs.Propulsion.PropArch.Type = "C";

% aircraft thrust-weight ratio
Aircraft.Specs.Propulsion.T_W.SLS = 0.3817;

% total sea level static thrust (N)
Aircraft.Specs.Propulsion.Thrust.SLS = UnitConversionPkg.ConvForce(23814 * 2, "lbf", "N");

% engine propulSive efficiency
Aircraft.Specs.Propulsion.Eta.Prop = 0.8;

% Number of engines
Aircraft.Specs.Propulsion.NumEngines = 2;

% get the engine
Aircraft.Specs.Propulsion.Engine = EngineModelPkg.EngineSpecsPkg.CF34_8E5;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% power specifications       %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% gravimetric specific energy of combustible fuel (kWh/kg)  
Aircraft.Specs.Power.SpecEnergy.Fuel = (43.2e+6) / (3.6e+6);

% gravimetric specific energy of battery (kWh/kg)
Aircraft.Specs.Power.SpecEnergy.Batt = 0.25;

% electric motor efficiency
Aircraft.Specs.Power.Eta.EM = 0.96;

% electric generator efficiency
Aircraft.Specs.Power.Eta.EG = 0.96;

% aircraft power-weight ratio (kW/kg)
Aircraft.Specs.Power.P_W.SLS = NaN;

% electric motor power-weight ratio (kW/kg)
Aircraft.Specs.Power.P_W.EM = NaN;

% electric generator power-weight ratio (kW/kg)
Aircraft.Specs.Power.P_W.EG = NaN;

% number of battery cells in series and parallel
Aircraft.Specs.Power.Battery.SerCells = NaN;
Aircraft.Specs.Power.Battery.ParCells = NaN;

% initial battery state-of-charge (SOC)
Aircraft.Specs.Power.Battery.BegSOC   = NaN;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% mission analysis settings  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% points in takeoff segment
Aircraft.Settings.TkoPoints = 3;

% points in climb   segment
Aircraft.Settings.ClbPoints = 5;

% points in cruise  segment
Aircraft.Settings.CrsPoints = 5;

% points in descent  segment
Aircraft.Settings.DesPoints = 5;

% maximum iterations when sizing OEW
Aircraft.Settings.OEW.MaxIter = NaN;

% convergence tolerance when sizing OEW
Aircraft.Settings.OEW.Tol = NaN;

% maximum iterations when sizing entire aircraft
Aircraft.Settings.Analysis.MaxIter = NaN;

% on design/off design analysis
% +1 = on design
% -1 = off design
Aircraft.Settings.Analysis.Type = +1;

% plot results
% 0 = no plotting
% 1 = plotting
Aircraft.Settings.Plotting = NaN;

% ----------------------------------------------------------

end