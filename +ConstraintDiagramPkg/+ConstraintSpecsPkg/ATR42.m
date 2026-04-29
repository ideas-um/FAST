function [] = ATR42()
%
% [] = ATR42()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 25 sep 2025
%
% create a constraint diagram for an ATR 42.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%

% initial cleanup
clc, close all


%% DEFINE THE AIRCRAFT'S PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% top-level aircraft         %
% requirements               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% aircraft class
Aircraft.Specs.TLAR.Class = "Turboprop";

% aircraft regulations
Aircraft.Specs.TLAR.CFRPart = 25;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% performance parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% altitudes
Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(25000, "ft", "m");
Aircraft.Specs.Performance.Alts.Srv = UnitConversionPkg.ConvLength(27000, "ft", "m");

% stall speed
Aircraft.Specs.Performance.Vels.Stl = sqrt(2 * 341.2844 * 9.81 / 2 / 1.225);

% cruise mach number
Aircraft.Specs.Performance.Vels.Crs = 0.4984;

% runway lengths and obstacle clearances ???
Aircraft.Specs.Performance.TOFL    = 1165;
Aircraft.Specs.Performance.LFL     =  966;
Aircraft.Specs.Performance.ObstLen = UnitConversionPkg.ConvLength( 1000, "ft", "m");

% multiplicative factors for OEI conditions
Aircraft.Specs.Performance.TempInc = 1.25;
Aircraft.Specs.Performance.MaxCont = 1 / 0.94;

% design specific excess power loss ???
Aircraft.Specs.Performance.PsLoss = 0;

% landing weight as a fraction of MTOW
Aircraft.Specs.Performance.Wland_MTOW = 0.65;

% requirement type (0 = Roskam; 1 = Mattingly, 2 = de Vries et al.)
Aircraft.Specs.TLAR.ReqType = 1;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aerodynamic parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% wing loading
Aircraft.Specs.Aero.W_S.SLS = 18600 / 54.5;

% aspect ratio
Aircraft.Specs.Aero.AR = 24.57 ^ 2 / 54.5;

% lift coefficients ???
Aircraft.Specs.Aero.CL.Crs = 0.9;
Aircraft.Specs.Aero.CL.Tko = 2.5;
Aircraft.Specs.Aero.CL.Lnd = 4;

% parasite drag coefficients ???
Aircraft.Specs.Aero.CD0.Tko = 0.0618;
Aircraft.Specs.Aero.CD0.Crs = 0.0168;
Aircraft.Specs.Aero.CD0.Lnd = 0.1168;

% Oswald efficiency factors ???
Aircraft.Specs.Aero.e.Crs = 0.7789;
Aircraft.Specs.Aero.e.Tko = 0.7329;
Aircraft.Specs.Aero.e.Lnd = 0.6872;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% weights                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% MTOW
Aircraft.Specs.Weight.MTOW = 18600;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion system          %
% specifications             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% power-weight ratio (kW/kg)
Aircraft.Specs.Power.P_W.SLS = 1610 * 2 / 18600;

% number of engines
Aircraft.Specs.Propulsion.NumEngines = 2;


%% RUN THE CONSTRAINT ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% determine which constraints to use (0 = 14 CFR 25; 1 = novel)
Aircraft.Settings.ConstraintType = 0;

% create a constraint diagram
ConstraintDiagramPkg.ConstraintDiagram(Aircraft);

% add the existing sizing point
hold on
scatter(Aircraft.Specs.Aero.W_S.SLS * 9.81 / 1000, 1 / (Aircraft.Specs.Power.P_W.SLS / 9.81 * 1000), 48, "o", "MarkerEdgeColor", "red", "MarkerFaceColor", "red");


end