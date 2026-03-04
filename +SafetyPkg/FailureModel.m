function [ProbFail] = FailureModel(BaseRate, Exposure)
%
% [ProbFail] = FailureModel(BaseRate, Exposure)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 apr 2025
%
% given a component's base failure rate and a given exposure time, compute
% the probability that the component fails.
%
% INPUTS:
%     BaseRate - the component's baseline failure rate.
%                size/type/units: m-by-1 / double / [/T]
%
%     Exposure - the exposure time (how long the component operates in a
%                given cycle)
%                size/type/units: 1-by-n / double / [T]
%
% OUTPUTS:
%     ProbFail - the probability that the component fails.
%                size/type/units: m-by-n / double / []
%

% compute the probability of failure
ProbFail = 1 - exp(-BaseRate .* Exposure);

end