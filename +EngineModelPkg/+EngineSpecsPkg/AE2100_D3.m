function [Engine] = AE2100_D3()
%
% [Engine] = AE2100_D3()
% Written By Maxfield Arnson
% Last Updated: 11/20/2023
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
% Applicable Aircraft = LM-100J


% Flight Conditions
Engine.Mach = 0.05;
Engine.Alt = 0;
Engine.OPR = 16.6;

% Architecture

% Burner total temp (Kelvin)
Engine.Tt4Max = 1200;   % kelvin

% Required Power Output (Watts)
Engine.ReqPower = 3458e3; % kW to W

% Initial Guess for Nozzle Pressure Ratio: Pt7/Ps9
Engine.NPR = 1.3;

% Number of Spools
Engine.NoSpools = 2;

% Spool RPMs, highest pressure to lowest
Engine.RPMs = [15284,14267];

% Efficiencies
Engine.EtaPoly.Inlet = 0.99;
Engine.EtaPoly.Diffusers = 0.99;
Engine.EtaPoly.Compressors = 0.86;
Engine.EtaPoly.Combustor = 0.98;
Engine.EtaPoly.Turbines = 0.86;
Engine.EtaPoly.Nozzles = 0.985;

end









