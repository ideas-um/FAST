function [W] = PistonEngineWeight(P)
%
% [W] = PistonEngineWeight(P)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 20 apr 2026
%
% predict the weight of a piston engine using a regression.
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
W(P > 0) = 0.5649 .* P(P > 0) .^ 0.7742;

end