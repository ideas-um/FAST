function [Engine] = PW_127M()
%
% [Engine] = PW_127M()
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
Engine.OPR = 14.7;

% Architecture

% Burner total temp (Kelvin)
Engine.Tt4Max = 1110;   % kelvin

% Required Power Output (Watts)
Engine.ReqPower = 2051e3; % kW to W

% Initial Guess for Nozzle Pressure Ratio: Pt7/Ps9
Engine.NPR = 1.3;

% Number of Spools
Engine.NoSpools = 3;

% Spool RPMs, highest pressure to lowest
Engine.RPMs = [28870,33300,1200];

% Efficiencies
Engine.EtaPoly.Inlet = 0.99;
Engine.EtaPoly.Diffusers = 0.99;
Engine.EtaPoly.Compressors = 0.88;
Engine.EtaPoly.Combustor = 0.995;
Engine.EtaPoly.Turbines = 0.88;
Engine.EtaPoly.Nozzles = 0.985;

end