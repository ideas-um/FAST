function [] = ElysianE9X()
%
% [] = ElysianE9X()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 20 nov 2025
%
% create a constraint diagram for a battery electric aircraft
% representative of the Elysian E9X.
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

% regulations for certification
Aircraft.Specs.Performance.ConstraintFuns = ["Jet25_119"; "Jet25_121a"; "Jet25_121b"; "Jet25_121c"; "Jet25_121d"; "JetApp"; "JetCrs"; "JetDiv"; "JetLFL"; "JetTOFL"];% "JetAEOClimb"];

% labels for regulations
Aircraft.Specs.Performance.ConstraintLabs = ["25.119"; "25.121a"; "25.121b"; "25.121c"; "25.121d"; "Approach"; "Cruise"; "Diversion"; "Landing"; "TOFL"];% "AEO Climb"];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% performance parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% altitudes
Aircraft.Specs.Performance.Alts.Crs = 7600; % [2024, 2025 says anywhere between 6400 and 9100 m]
Aircraft.Specs.Performance.Alts.Srv = 8000; % still approximated
Aircraft.Specs.Performance.Alts.Div = 4000; % [2024]

% stall speed [2024]
Aircraft.Specs.Performance.Vels.Stl = sqrt(2 * 509.6840 * 9.81 / 2.5 / 1.225);
Aircraft.Specs.Performance.Vels.App = UnitConversionPkg.ConvVel(145, "kts", "m/s");

% cruise mach number [2024]
Aircraft.Specs.Performance.Vels.Crs = 0.6;
Aircraft.Specs.Performance.Vels.Div = 0.4;

% runway lengths and obstacle clearances [2024]
Aircraft.Specs.Performance.TOFL    = 2000;
Aircraft.Specs.Performance.LFL     = 2000;
Aircraft.Specs.Performance.ObstLen = UnitConversionPkg.ConvLength(1000, "ft", "m");

% multiplicative factors for OEI conditions
Aircraft.Specs.Performance.TempInc = 1.25;
Aircraft.Specs.Performance.MaxCont = 1 / 0.94;

% design specific excess power loss ???
Aircraft.Specs.Performance.PsLoss = 0.4136;

% landing weight as a fraction of MTOW
Aircraft.Specs.Performance.Wland_MTOW = 1;

% requirement type (0 = Roskam, 1 = Mattingly, 2 = de Vries et al.)
Aircraft.Specs.TLAR.ReqType = 2;

% prescribe an extra AEO climb gradient
Aircraft.Specs.Performance.ExtraGrad = 0.08;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aerodynamic parameters     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% wing loading
Aircraft.Specs.Aero.W_S.SLS = 509.6840;

% aspect ratio
Aircraft.Specs.Aero.AR = 12;

% lift coefficients
Aircraft.Specs.Aero.CL.Crs = 1.0;
Aircraft.Specs.Aero.CL.Tko = 2.5;
Aircraft.Specs.Aero.CL.Lnd = 2.5; % (optionally 3.1, but seems unrealistic)

% parasite drag coefficients
Aircraft.Specs.Aero.CD0.Tko = 0.0618;
Aircraft.Specs.Aero.CD0.Crs = 0.0168;
Aircraft.Specs.Aero.CD0.Lnd = 0.1068;

% Oswald efficiency factors
Aircraft.Specs.Aero.e.Crs = 0.7861;
Aircraft.Specs.Aero.e.Tko = 0.7468;
Aircraft.Specs.Aero.e.Lnd = 0.7075;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% weights                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% MTOW
Aircraft.Specs.Weight.MTOW = 76000;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion system          %
% specifications             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% power-weight ratio (kW/kg)
Aircraft.Specs.Power.P_W.SLS = 1/(0.0666*1000/9.81); % approx. 0.1473;

% number of engines [2024 paper, actually 8, but uses 4-engine climb gradients]
Aircraft.Specs.Propulsion.NumEngines = 4;


%% RUN THE CONSTRAINT ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% determine which constraints to use (0 = 14 CFR 25; 1 = novel)
Aircraft.Settings.ConstraintType = 1;

% create a constraint diagram
ConstraintDiagramPkg.ConstraintDiagram(Aircraft);

% add the existing sizing point
hold on
scatter(Aircraft.Specs.Aero.W_S.SLS * 9.81 / 1000, 1 / (Aircraft.Specs.Power.P_W.SLS / 9.81 * 1000), 48, "o", "MarkerEdgeColor", [0, 0.251, 0.478], "MarkerFaceColor", [0, 0.251, 0.478]);

end