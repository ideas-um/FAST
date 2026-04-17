function [W] = ElectricMachineWeight(P)
%
% [W] = ElectricMachineWeight(P)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 09 apr 2026
%
% predict the weight of an electric motor using a regression.
%
% INPUTS:
%     P - rated power.
%         size/type/units: m-by-n / double / [W]
%
%     W - weight.
%         size/type/units: m-by-n / double / [kg]
%

% convert the rated power from W to kW
P = P ./ 1000;

% memory for the output
W = zeros(size(P));

% compute the weight
W(P > 0) = 0.2118 .* P(P > 0) .^ 1.0332;

end