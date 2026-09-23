function [Engine] = PW_123()
%
% [Engine] = PW_123()
% Written By Maxfield Arnson
% Last Updated: 03/09/2024
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
% Type = Turboprop
% Applicable Aircraft = ATR 72


% Flight Conditions
Engine.Mach = 0.05;
Engine.Alt = 0;
Engine.OPR = 13.8;

% Architecture

% Burner total temp (Kelvin)
Engine.Tt4Max = 1300;   % kelvin

% Required Power Output (Watts)
Engine.ReqPower = 1775e3; % kW to W

% Initial Guess for Nozzle Pressure Ratio: Pt7/Ps9
Engine.NPR = 1.3;

% Number of Spools
Engine.NoSpools = 3;

% Spool RPMs, highest pressure to lowest
Engine.RPMs = [28800,33300,1200];

% Efficiencies
Engine.EtaPoly.Inlet = 0.99;
Engine.EtaPoly.Diffusers = 0.99;
Engine.EtaPoly.Compressors = 0.9;
Engine.EtaPoly.Combustor = 0.995;
Engine.EtaPoly.Turbines = 0.9;
Engine.EtaPoly.Nozzles = 0.985;

end