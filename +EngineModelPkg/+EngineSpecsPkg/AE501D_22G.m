function [Engine] = AE501D_22G()
%
% [Engine] = [Engine] = AE501D_22G()
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
% Applicable Aircraft = Super 580, Convair 5800

Engine.Mach = 0.05;
Engine.Alt = 0;
Engine.OPR = 9.6;
Engine.ITTMax = 1106.483; 
Engine.Tt4Max = 1350.2;   % kelvin

Engine.ReqPower = 3356e3; % kW to W 
Engine.NPR = 1.3;  % Guessing

Engine.NoSpools = 1;
Engine.RPMs = [13820];

% Efficiencies
Engine.EtaPoly.Inlet = 0.99;
Engine.EtaPoly.Diffusers = 0.99;
Engine.EtaPoly.Compressors = 0.9;
Engine.EtaPoly.Combustor = 0.995;
Engine.EtaPoly.Turbines = 0.9;
Engine.EtaPoly.Nozzles = 0.985;

end