function [Aircraft] = LM100J_Hybrid()
%
% [Aircraft] = LM100J_Hybrid()
% originally written by Paul Mokotoff, prmoko@umich.edu
% last updated: 16 dec 2024
%
% Define the LM100J from Lockheed Martins' Brochure with the NASA-specified
% propulsion architecture.
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
Aircraft.Specs.TLAR.EIS = 2016;

% ** REQUIRED ** aircraft class, either:
%     (1) "Piston"    = piston aircraft
%     (2) "Turboprop" = turboprop
%     (3) "Turbofan"  = turbojet or turbofan
Aircraft.Specs.TLAR.Class = "Turboprop";
            
% ** REQUIRED **: number of passengers
Aircraft.Specs.TLAR.MaxPax = 4e4/209;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% performance parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% takeoff speed (m/s)
Aircraft.Specs.Performance.Vels.Tko = NaN;

% cruise  speed (mach)
Aircraft.Specs.Performance.Vels.Crs = 0.59;

% takeoff altitude (m)
Aircraft.Specs.Performance.Alts.Tko = NaN;

% cruise altitude (m)
Aircraft.Specs.Performance.Alts.Crs = NaN;

% ** REQUIRED **: design range (m)
Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength(2390, "naut mi", "m");

% maximum rate-of-climb (m/s)
Aircraft.Specs.Performance.RCMax = NaN;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aerodynamic parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% lift-drag ratio at climb
Aircraft.Specs.Aero.L_D.Clb = 12.3;

% lift-drag ratio at cruise
Aircraft.Specs.Aero.L_D.Crs = 14.3;

% lift-drag ratio at descent
Aircraft.Specs.Aero.L_D.Des = NaN;

% maximum wing loading (kg/m^2)
Aircraft.Specs.Aero.W_S.SLS = 74389.1487 / ...
                              UnitConversionPkg.ConvLength((132 + 7 / 12), "ft", "m") / ...
                              UnitConversionPkg.ConvLength(10, "ft", "m");

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% weights                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
% maximum takeoff weight (kg)
Aircraft.Specs.Weight.MTOW = 74389.1487;

% block fuel (kg)
Aircraft.Specs.Weight.Fuel = NaN;

% landing weight (kg)
Aircraft.Specs.Weight.MLW = NaN;

% battery weight (kg)
Aircraft.Specs.Weight.Batt = 0;

% electric motor weight (kg)
Aircraft.Specs.Weight.EM = NaN;

% electric generator weight (kg)
Aircraft.Specs.Weight.EG = NaN;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion architecture    %
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
Aircraft.Specs.Propulsion.PropArch.Type = "O";

% architecture matrix
Aircraft.Specs.Propulsion.PropArch.Arch = ...
    [0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0; ...
     0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0; ...
     0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0; ...
     0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0; ...
     0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] ;
 
% upstream operational matrix
Aircraft.Specs.Propulsion.PropArch.OperUps = @(lam) ...
    [0, 0, 1, 1, 0, 0, 0, 0, 0  , 0  , 0; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0  , 0  , 0; ...
     0, 0, 0, 0, 0, 0, 1, 0, 0  , 0  , 0; ...
     0, 0, 0, 0, 0, 0, 0, 1, 0  , 0  , 0; ...
     0, 0, 0, 0, 0, 0, 0, 0, lam, 0  , 0; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0  , lam, 0; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0  , 0  , 1; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0  , 0  , 1; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0  , 0  , 1; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0  , 0  , 1; ...
     0, 0, 0, 0, 0, 0, 0, 0, 0  , 0  , 0] ;
 
% downstream operational matrix
Aircraft.Specs.Propulsion.PropArch.OperDwn = @(lam) ...
    [0, 0, 0, 0, 0, 0,         0,         0,   0,    0, 0; ...
     0, 0, 0, 0, 0, 0,         0,         0,   0,    0, 0; ...
     1, 0, 0, 0, 0, 0,         0,         0,   0,    0, 0; ...
     1, 0, 0, 0, 0, 0,         0,         0,   0,    0, 0; ...
     0, 1, 0, 0, 0, 0,         0,         0,   0,    0, 0; ...
     0, 1, 0, 0, 0, 0,         0,         0,   0,    0, 0; ...
     0, 0, 1, 0, 0, 0,         0,         0,   0,    0, 0; ...
     0, 0, 0, 1, 0, 0,         0,         0,   0,    0, 0; ...
     0, 0, 0, 0, 1, 0,         0,         0,   0,    0, 0; ...
     0, 0, 0, 0, 0, 1,         0,         0,   0,    0, 0; ...
     0, 0, 0, 0, 0, 0, 0.5 - lam, 0.5 - lam, lam , lam, 0];
 
% upstream efficiency matrix
Aircraft.Specs.Propulsion.PropArch.EtaUps = ...
    [1, 1, 1, 1, 1   , 1   , 1   , 1   , 1   , 1   , 1; ...
     1, 1, 1, 1, 0.96, 0.96, 1   , 1   , 1   , 1   , 1; ...
     1, 1, 1, 1, 1   , 1   , 0.80, 1   , 1   , 1   , 1; ...
     1, 1, 1, 1, 1   , 1   , 1   , 0.80, 1   , 1   , 1; ...
     1, 1, 1, 1, 1   , 1   , 1   , 1   , 0.80, 1   , 1; ... 
     1, 1, 1, 1, 1   , 1   , 1   , 1   , 1   , 0.80, 1; ...
     1, 1, 1, 1, 1   , 1   , 1   , 1   , 1   , 1   , 1; ...
     1, 1, 1, 1, 1   , 1   , 1   , 1   , 1   , 1   , 1; ...
     1, 1, 1, 1, 1   , 1   , 1   , 1   , 1   , 1   , 1; ...
     1, 1, 1, 1, 1   , 1   , 1   , 1   , 1   , 1   , 1; ...
     1, 1, 1, 1, 1   , 1   , 1   , 1   , 1   , 1   , 1] ;

% downstream efficiency matrix
Aircraft.Specs.Propulsion.PropArch.EtaDwn = ...
    [1, 1   , 1   , 1   , 1   , 1   , 1, 1, 1, 1, 1; ...
     1, 1   , 1   , 1   , 1   , 1   , 1, 1, 1, 1, 1; ...
     1, 1   , 1   , 1   , 1   , 1   , 1, 1, 1, 1, 1; ...
     1, 1   , 1   , 1   , 1   , 1   , 1, 1, 1, 1, 1; ...
     1, 0.96, 1   , 1   , 1   , 1   , 1, 1, 1, 1, 1; ...
     1, 0.96, 1   , 1   , 1   , 1   , 1, 1, 1, 1, 1; ...
     1, 1   , 0.80, 1   , 1   , 1   , 1, 1, 1, 1, 1; ...
     1, 1   , 1   , 0.80, 1   , 1   , 1, 1, 1, 1, 1; ...
     1, 1   , 1   , 1   , 0.80, 1   , 1, 1, 1, 1, 1; ...
     1, 1   , 1   , 1   , 1   , 0.80, 1, 1, 1, 1, 1; ...
     1, 1   , 1   , 1   , 1   , 1   , 1, 1, 1, 1, 1] ; 

% source type
Aircraft.Specs.Propulsion.PropArch.SrcType = [1, 0];

% transmitter type
Aircraft.Specs.Propulsion.PropArch.TrnType = [1, 1, 0, 0, 2, 2, 2, 2];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion system          %
% specifications             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% total power available at sea-level (W)
Aircraft.Specs.Power.SLS = NaN;

% engine propulsive efficiency
Aircraft.Specs.Propulsion.Eta.Prop = 0.8;

% number of engines
Aircraft.Specs.Propulsion.NumEngines = 4;

% engine specification
Aircraft.Specs.Propulsion.Engine = EngineModelPkg.EngineSpecsPkg.AE2100_D3;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% power specifications       %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% gravimetric specific energy of combustible fuel (kWh/kg)  
Aircraft.Specs.Power.SpecEnergy.Fuel = (43.2e+6) / (3.6e+6);

% gravimetric specific energy of battery (kWh/kg)
Aircraft.Specs.Power.SpecEnergy.Batt = 0.35;

% electric motor efficiency
Aircraft.Specs.Power.Eta.EM = 0.96;

% electric generator efficiency
Aircraft.Specs.Power.Eta.EG = 0.96;

% propeller efficiency
Aircraft.Specs.Power.Eta.Propeller = 0.8;

% aircraft power-weight ratio (kW/kg)
Aircraft.Specs.Power.P_W.SLS = 4 * 3410 / UnitConversionPkg.ConvMass(164e+03, "lbm", "kg");

% downstream operational splits
Aircraft.Specs.Power.LamDwn.SLS = 0.05;
Aircraft.Specs.Power.LamDwn.Tko = 0.03;
Aircraft.Specs.Power.LamDwn.Clb = 0.01;
Aircraft.Specs.Power.LamDwn.Crs = 0.00;
Aircraft.Specs.Power.LamDwn.Des = 0.00;
Aircraft.Specs.Power.LamDwn.Lnd = 0.00;

% upstream operational splits
Aircraft.Specs.Power.LamUps.SLS = 1;
Aircraft.Specs.Power.LamUps.Tko = 1;
Aircraft.Specs.Power.LamUps.Clb = 1;
Aircraft.Specs.Power.LamUps.Crs = 0;
Aircraft.Specs.Power.LamUps.Des = 0;
Aircraft.Specs.Power.LamUps.Lnd = 0;

% electric motor power-weight ratio (kW/kg)
Aircraft.Specs.Power.P_W.EM = 10;

% electric generator power-weight ratio (kW/kg)
Aircraft.Specs.Power.P_W.EG = NaN;

% specify battery (none for now)
Aircraft.Specs.Power.Battery.SerCells = NaN;
Aircraft.Specs.Power.Battery.ParCells = NaN;

% specify an initial battery SOC (none for now)
Aircraft.Specs.Power.Battery.BegSOC = NaN;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% mission analysis           %
% properties                 %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% points in takeoff segment
Aircraft.Settings.TkoPoints = 5;

% points in climb   segment
Aircraft.Settings.ClbPoints = 10;

% points in cruise  segment
Aircraft.Settings.CrsPoints = 10;

% points in descent  segment
Aircraft.Settings.DesPoints = 5;

% maximum iterations when sizing OEW
Aircraft.Settings.OEW.MaxIter = NaN;

% convergence tolerance when sizing OEW
Aircraft.Settings.OEW.Tol = NaN;

% maximum iterations when sizing entire aircraft
Aircraft.Settings.Analysis.MaxIter = NaN;

% on design/off design analysis
% 1  = on design
% -1 = off design
Aircraft.Settings.Analysis.Type = +1;

% plot results/ do no
% 0 = no plotting
% 1 = plotting
Aircraft.Settings.Plotting = 0;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% power split optimization   %
% settings                   %
%                            %
% comment the lines below if %
% the power optimization is  %
% not being used             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % optimization settings
% Aircraft.PowerOpt.Settings.DesnTS   = 1;
% Aircraft.PowerOpt.Settings.OperTS   = 0;
% Aircraft.PowerOpt.Settings.DesnTSPS = 0;
% Aircraft.PowerOpt.Settings.OperTSPS = 0;
% Aircraft.PowerOpt.Settings.DesnPSPS = 0;
% Aircraft.PowerOpt.Settings.OperPSPS = 0;
% Aircraft.PowerOpt.Settings.DesnPSES = 0;
% Aircraft.PowerOpt.Settings.OperPSES = 0;
% 
% % power optimization tolerance and iteration limits
% Aircraft.PowerOpt.Tol     = 1.0e-02;
% Aircraft.PowerOpt.MaxIter = 2      ;
% 
% % optimization objective function, if optimization is requested
% Aircraft.PowerOpt.ObjFun = "FuelBurn";

% ----------------------------------------------------------

end