function [Engine] = Allison_250_C30G()
%ENGINESPEC Summary of this function goes here
%   Detailed explanation goes here

% Turboshaft
% Aircraft ---> Heli-Air Bell 222

Engine.Mach = 0.05;
Engine.Alt = 0;
Engine.OPR = 8.6;
Engine.ITTMax = 1106.483; 
Engine.Tt4Max = 1100;   % kelvin

Engine.JetThrust = 0; % Newtons

Engine.ReqPower = 485e3; % kW to W 
Engine.NPR = 1.3;  % Guessing

Engine.NoSpools = 2;
Engine.RPMs = [50340,30648];

% Efficiencies
Engine.EtaPoly.Inlet = 0.99;
Engine.EtaPoly.Diffusers = 0.99;
Engine.EtaPoly.Compressors = 0.9;
Engine.EtaPoly.Combustor = 0.995;
Engine.EtaPoly.Turbines = 0.9;
Engine.EtaPoly.Nozzles = 0.985;

end