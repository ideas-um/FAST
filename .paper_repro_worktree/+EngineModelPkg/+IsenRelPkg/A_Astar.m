function [A] = A_Astar(Astar,M,gamma)
%
% [A] = A_Astar(Astar,M,gamma)
% Written by Maxfield Arnson
% Updated 10/3/2023
%
% This function computes flow area given a choked area and thermodynamic
% conditions. It is the reciprocol of Astar_A
%
%
% INPUTS:
%
% Astar = Choked flow area
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
% A = flow area at conditions M,gamma if Astar is the choked flow area
%       size: scalar double

A = Astar*((gamma+1)/2)^(-(gamma+1)/(2*gamma-2))...
    *((1+(gamma-1)/2*M^2)^((gamma+1)/(2*gamma-2))/M);
end
