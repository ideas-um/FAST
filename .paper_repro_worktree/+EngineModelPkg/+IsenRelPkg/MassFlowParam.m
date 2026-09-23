function [MFP] = MassFlowParam(M,g)
%
% [MFP] = MassFlowParam(M,g)
% Written by Maxfield Arnson
% Updated 10/3/2023
%
% This function computes the Mass flow parameter of a flow. mass flow
% parameter is a nondimensional quantity which is used to compare different
% engine performance at different flow conditions
%
%
% INPUTS:
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
% MFP = mass flow parameter
%       size: scalar double

R = 287;
MFP = sqrt(g/R)*M*(1+(g-1)/2*M^2)^((g+1)/(2*g-2));


end

