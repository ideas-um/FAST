function [Engine] = GE90_115B()
%
% [Engine] = GE90_115B()
%
% Engine specification function for the GE90-115B turbofan.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Engine - struct storing engine design point, architecture, airflow,
%              sizing, and efficiency assumptions for EngineModelPkg.
%


%% DESIGN POINT VALUES %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% design point mach number
Engine.Mach = 0.05;

% design point altitude (m)
Engine.Alt = 0;

% overall pressure ratio
Engine.OPR = 42;

% fan pressure ratio
Engine.FPR = 1.4;

% bypass ratio
Engine.BPR = 9;

% combustion temperature (K)
Engine.Tt4Max = 1600;

% temperature limits are not functional yet
Engine.TempLimit.Val = NaN;
Engine.TempLimit.Type = NaN;

% design point thrust (N), 115,300 lbf
Engine.DesignThrust = UnitConversionPkg.ConvForce(115300, "lbf", "N");


%% ARCHITECTURE %%
%%%%%%%%%%%%%%%%%%

% GE90 is a two-spool high-bypass turbofan.
Engine.NoSpools = 2;

% spool RPMs, ordered by fan/low-pressure spool then high-pressure spool
Engine.RPMs = [2500, 9332];

% not geared
Engine.FanGearRatio = NaN;

% low-pressure compressor is connected to the fan shaft
Engine.FanBoosters = true;


%% AIRFLOWS %%
%%%%%%%%%%%%%%

% passenger bleed fraction
Engine.CoreFlow.PaxBleed = 0.03;

% air leakage fraction
Engine.CoreFlow.Leakage = 0.01;

% core cooling flow fraction
Engine.CoreFlow.Cooling = 0.0;


%% SIZING LIMITS %%
%%%%%%%%%%%%%%%%%%%

% maximum iterations allowed in the engine sizing loop
Engine.MaxIter = 300;


%% EFFICIENCIES %%
%%%%%%%%%%%%%%%%%%

Engine.EtaPoly.Inlet = 0.99;
Engine.EtaPoly.Diffusers = 0.99;
Engine.EtaPoly.Fan = 0.99;
Engine.EtaPoly.Compressors = 0.96;
Engine.EtaPoly.BypassNozzle = 0.99;
Engine.EtaPoly.Combustor = 0.995;
Engine.EtaPoly.Turbines = 0.96;
Engine.EtaPoly.CoreNozzle = 0.99;
Engine.EtaPoly.Nozzles = 0.99;
Engine.EtaPoly.Mixing = 0.0;


%% OFFDESIGN COEFFICIENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% BADA-style fuel-flow coefficients used by SimpleOffDesign.
Engine.Cff3 = 0.7000;
Engine.Cff2 = -0.6500;
Engine.Cff1 = 1.2000;
Engine.Cffch = 1.5 * 10^-6;
Engine.HEcoeff = 1;

end
