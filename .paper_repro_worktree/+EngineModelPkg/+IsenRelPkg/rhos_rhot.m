function [rhos] = rhos_rhot(rhot,M,gamma)
%
% [rhos] = rhos_rhot(rhot,M,gamma)
% Written by Maxfield Arnson
% Updated 10/3/2023
%
% This function computes the static density of a flow given the stagnation
% density and thermodynamic conditions
%
%
% INPUTS:
%
% rhot = stagnation density
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
% rhos = static density
%       size: scalar double

rhos = rhot/(1+ (gamma-1)/2*M.^2).^((1)/(gamma-1));
end