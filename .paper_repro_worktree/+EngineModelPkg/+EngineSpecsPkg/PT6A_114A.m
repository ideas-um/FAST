function [Engine] = PT6A_114A()
%
% [Engine] = PT6A_114A()
% Written By Maxfield Arnson, marnson@umich.edu
% Modified by Yilin Deng
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
% Applicable Aircraft = Cessna 208

Engine.Mach = 0.05;
Engine.Alt = 0;
Engine.OPR = 7;
Engine.Tt4Max = 1010;   % kelvin

Engine.JetThrust = 552; % Newtons

Engine.ReqPower = 541e3; % kW to W 
Engine.NPR = 1.3;  % Guessing

Engine.NoSpools = 2;
Engine.RPMs = [38100,32986];

% Efficiencies
Engine.EtaPoly.Inlet = 0.99;
Engine.EtaPoly.Diffusers = 0.99;
Engine.EtaPoly.Compressors = 0.83;
Engine.EtaPoly.Combustor = 0.92;
Engine.EtaPoly.Turbines = 0.83;
Engine.EtaPoly.Nozzles = 0.985;

end







