function [Engine] = ExampleTF()
%
% [Engine] = ExampleTF()
% Written By {User}
% Last Updated: {Today's Date}
%
% Engine specification function for use with the EngineModelPkg
%
% Type = {Turbofan}
% Applicable Aircraft = {Enter aircraft names that the engine is used on}


%% Design Point Values

% Design point Mach Number 
% If SLS, enter 0.05
Engine.Mach = NaN;

% Design point Altitude [m]
% If SLS, enter 0
Engine.Alt = NaN;

% Overall Pressure Ratio 
Engine.OPR = NaN;

% Fan Pressure Ratio
Engine.FPR = NaN;

% Bypass Ratio
Engine.BPR = NaN; 

% Combustion Temperature [K]
% If unknown, 2000 is a good guess
Engine.Tt4Max = NaN;

% Temperature Limits [K]
% Not functional yet. Leave these values as NaN
Engine.TempLimit.Val = NaN;
Engine.TempLimit.Type = NaN;

% Design point thrust [N]
Engine.DesignThrust = NaN;



%% Architecture

% Number of Spools
% Value between 1 and 3 (historically this is the case)
Engine.NoSpools = NaN;

% Spool RPMs
% Enter a 1xN vector where N = Engine.NoSpools
% in the order: Fan Spool, Intermediate Pressure Spool, High Pressure Spool
% omit any spools that do not exist but preserve the order
Engine.RPMs = [NaN,NaN,NaN];

% Gear Ratio
% enter NaN if not geared
% if ratio is entered, make sure Engine.RPMs(1) is the fan spool rpm (LPT rpm),
% not the fan rpm. This will get calculated from the gear ratio
Engine.FanGearRatio = NaN;

% Fan Boosters (Boolean: enter true or false)
% If the low pressure compressor is connected to the fan shaft or not
% it is almost always the case that an engine will not be geared and
% boosted
Engine.FanBoosters = false;

%% Airflows

% Passenger Bleeds
% Typically 0.03
Engine.CoreFlow.PaxBleed = NaN;

% Air leakage
% Typically 1%
Engine.CoreFlow.Leakage = NaN;

% Core Cooling Flow
Engine.CoreFlow.Cooling = NaN;

%% Sizing Limits

% Maximum iterations allowed in the engine sizing loop
Engine.MaxIter = 300;


%% Efficiencies
% Polytropic Component efficiencies
Engine.Eta.Inlet = 1;
Engine.Eta.Fan = 1;
Engine.Eta.Compressor = 1;
Engine.Eta.BypassNozzle = 1;
Engine.Eta.Combustor = 1;
Engine.Eta.HPT = 1;
Engine.Eta.LPT = 1;
Engine.Eta.CoreNozzle = 1;

end

