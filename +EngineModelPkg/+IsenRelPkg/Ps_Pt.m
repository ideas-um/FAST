function [Ps] = Ps_Pt(Pt,M,gamma)
%
% [Ps] = Ps_Pt(Pt,M,gamma)
% Written by Maxfield Arnson
% Updated 10/3/2023
%
% This function computes the static pressure of a flow given the stagnation
% pressure and thermodynamic conditions
%
%
% INPUTS:
%
% Pt = stagnation pressure
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
% Ps = static pressure
%       size: scalar double

Ps = Pt/(1+ (gamma-1)/2*M.^2).^((gamma)/(gamma-1));
end