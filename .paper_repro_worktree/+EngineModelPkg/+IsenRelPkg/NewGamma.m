function [Ts,cp,cv,g] = NewGamma(Tt,M,g)
%
% [Ts,cp,cv,g] = NewGamma(Tt,M,g)
% Written by Maxfield Arnson
% Updated 10/3/2023
%
% This function computes the static temperature of a flow, the specific heat
% at constant pressure and volume, and the ratio of specific heats 
% given the stagnation temperature, the known Mach number, and an
% un-updated value of ratio of specific heats. It is a direct upgrade to
% Ts_Tt(), forgoing the assumption of a calorically perfect gas and
% adopting a thermally perfect model
%
%
% INPUTS:
%
% Tt = stagnation temperature
%       size: scalar double
%
% M = flow Mach number
%           function.
%       size: scalar double
%
% gamma = ratio of specific heats
%       size: scalar double
%
%
% OUTPUTS:
%
% Ts = static temperature
%       size: scalar double
%
% cp = specific heat at constant pressure
%       size: scalar double
%
% cp = specific heat at constant volume
%       size: scalar double
%
% gamma = ratio of specific heats
%       size: scalar double


% Iterate until gamma no longer changes
delg = 1;

while delg > 1e-3
    Ts = EngineModelPkg.IsenRelPkg.Ts_Tt(Tt,M,g);
    cp = EngineModelPkg.SpecHeatPkg.CpAir(Ts);
    cv = EngineModelPkg.SpecHeatPkg.CvAir(Ts);
    g2 = cp/cv;
    delg = abs(g2-g)/g;
    g = g2;
end
g = g2;

end

