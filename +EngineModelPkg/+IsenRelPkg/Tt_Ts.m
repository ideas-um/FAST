function [Tt] = Tt_Ts(Ts,M,gamma)
%
% [Tt] = Tt_Ts(Ts,M,gamma)
% Written by Maxfield Arnson
% Updated 10/3/2023
%
% This function computes the stagnation temperature of a flow given the static
% temperature and thermodynamic conditions
%
%
% INPUTS:
%
% Ts = static temperature
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
% Tt = stagnation temperature
%       size: scalar double
Tt = Ts*(1+ (gamma-1)/2*M.^2);
end