function [Pt] = Pt_Ps(Ps,M,g)
%
% [Pt] = Pt_Ps(Ps,M,g)
% Written by Maxfield Arnson
% Updated 10/3/2023
%
% This function computes the stagnation pressure of a flow given the static
% pressure and thermodynamic conditions
%
%
% INPUTS:
%
% Ps = static pressure
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
% Pt = stagnation pressure
%       size: scalar double

Pt = Ps*(1+ (g-1)/2*M.^2).^((g)/(g-1));
end