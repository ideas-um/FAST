function [Ts] = Ts_Tt(Tt,M,gamma)
%
% [Ts] = Ts_Tt(Tt,M,gamma)
% Written by Maxfield Arnson
% Updated 10/3/2023
%
% This function computes the static temperature of a flow given the stagnation
% temperature and thermodynamic conditions
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

Ts = Tt/(1+ (gamma-1)/2*M.^2);
end