function [Astar] = Astar_A(A,M,gamma)
%
% [Astar] = Astar_A(A,M,gamma)
% Written by Maxfield Arnson
% Updated 10/3/2023
%
% This function computes the choked flow area given an unchoked area 
% and thermodynamic conditions of the flow. It is the reciprocol of A_Astar
%
%
% INPUTS:
%
% A = flow area
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
% Astar = choked flow area at conditions M,gamma if A is 
%       the unchoked flow area
%       size: scalar double
Astar = A/((gamma+1)/2)^(-(gamma+1)/(2*gamma-2))...
    /((1+(gamma-1)/2*M^2)^((gamma+1)/(2*gamma-2))/M);
end