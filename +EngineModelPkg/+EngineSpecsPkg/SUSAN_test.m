function [Engine] = SUSAN_test()
%
% [Engine] = SUSAN()
% Written By Maxfield Arnson
% Last Updated: 09/04/2024
%
% Engine specification function for use with the EngineModelPkg
%
% INPUTS:
%
% [None]
%
%
% OUTPUTS:
%
% Engine = struct storing the information specified by the user for this
%           specific engine
%       size: 1x1 struct
%
%
% Information
% -----------
%
% Type = Turbofan
% Applicable Aircraft = SUSAN

%% Design Point Values

% Design point Mach Number 
% If SLS, enter 0.05
Engine.Mach = 0.785;

% Design point Altitude [m]
% If SLS, enter 0
Engine.Alt = UnitConversionPkg.ConvLength(37000,'ft','m');

% Overall Pressure Ratio 
Engine.OPR = 86;

% Fan Pressure Ratio
Engine.FPR = 1.37;

% Bypass Ratio
Engine.BPR = 5.66; 

% Combustion Temperature [K]
% If unknown, 2000 is a good guess
Engine.Tt4Max = 2385;  

% Temperature Limits [K]
% Not functional yet. Leave these values as NaN
Engine.TempLimit.Val = NaN;
Engine.TempLimit.Type = NaN;

% Design point thrust [N]
Engine.DesignThrust = UnitConversionPkg.ConvForce(7134,'lbf','N');  %120640  Prrvious data: 106760



%% Architecture

% Number of Spools
% Value between 1 and 3 (historically this is the case)
Engine.NoSpools = 2;

% Spool RPMs
% Enter a 1xN vector where N = Engine.NoSpools
% in the order: Fan Spool, Intermediate Pressure Spool, High Pressure Spool
% omit any spools that do not exist but preserve the order
Engine.RPMs = [2000,40000];

% Gear Ratio
% enter NaN if not geared
% if ratio is entered, make sure Engine.RPMs(1) is the fan spool rpm (LPT rpm),
% not the fan rpm. This will get calculated from the gear ratio
Engine.FanGearRatio = 1.7;

% Fan Boosters (Boolean: enter true or false)
% If the low pressure compressor is connected to the fan shaft or not
% it is almost always the case that an engine will not be geared and
% boosted
Engine.FanBoosters = false;

%% Airflows

% Passenger Bleeds
% Typically 0.03
Engine.CoreFlow.PaxBleed = 0.03;

% Air leakage
% Typically 1%
Engine.CoreFlow.Leakage = 0.01;

% Core Cooling Flow
Engine.CoreFlow.Cooling = 0.0;

%% Sizing Limits

% Maximum iterations allowed in the engine sizing loop
Engine.MaxIter = 300;


%% Efficiencies

% Polytropic component efficiencies
Engine.EtaPoly.Inlet = 0.99;
Engine.EtaPoly.Diffusers = 0.99;
Engine.EtaPoly.Fan = 0.91;
Engine.EtaPoly.Compressors = 0.91;
Engine.EtaPoly.BypassNozzle = 0.99;
Engine.EtaPoly.Combustor = 0.995;
Engine.EtaPoly.Turbines = 0.91;
Engine.EtaPoly.CoreNozzle = 0.99;
Engine.EtaPoly.Nozzles = 0.99;
Engine.EtaPoly.Mixing = 0.0;

end