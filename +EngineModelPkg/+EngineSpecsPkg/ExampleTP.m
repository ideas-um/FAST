function [Engine] = ExampleTP()
%
% [Engine] = ExampleTF()
% Written By {User}
% Last Updated: {Today's Date}
%
% Engine specification function for use with the EngineModelPkg
%
% Type = {Turboprop}
% Applicable Aircraft = {Enter aircraft names that the engine is used on}

% Flight Conditions
Engine.Mach = 0.05;
Engine.Alt = 0;
Engine.OPR = 15;

% Architecture

% Burner total temp (Kelvin)
Engine.Tt4Max = 1200;   % kelvin

% Required Power Output (Watts)
Engine.ReqPower = 3e6;

% Initial Guess for Nozzle Pressure Ratio: Pt7/Ps9
Engine.NPR = 1.3;

% Number of Spools
Engine.NoSpools = 2;

% Spool RPMs, highest pressure to lowest
Engine.RPMs = [15000,12000];

% Efficiencies
Engine.EtaPoly.Inlet = 0.99;
Engine.EtaPoly.Diffusers = 0.99;
Engine.EtaPoly.Compressors = 0.9;
Engine.EtaPoly.Combustor = 0.98;
Engine.EtaPoly.Turbines = 0.9;
Engine.EtaPoly.Nozzles = 0.985;

end