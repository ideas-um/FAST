function [Aircraft] = SimplexPost(Aircraft, ielem, LamOpt)
%
% [Aircraft] = SimplexPost(Aircraft, ielem, PhiOpt)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% After solving via the Simplex Method, determine if any constraints are
% violated and return the optimum power splits to the aircraft structure.
%
% INPUTS:
%     Aircraft - structure containing information about the aircraft.
%                size/type/units: 1-by-1 / struct / []
%
%     ielem    - array with control point indices to be hybridized.
%                size/type/units: n-by-1 / int / []
%
%     LamOpt   - optimum power split and slack variables.
%                size/type/units: m-by-1 / int / []
%
% OUTPUTS:
%     Aircraft - updated structure with the optimum power splits.
%                size/type/units: 1-by-1 / struct / []
%


%% PROCESS INPUTS %%
%%%%%%%%%%%%%%%%%%%%

% get number of control points in the segment
npnt = length(ielem);

% power splits returned will be one less
nphi = npnt - 1;


%% UPDATE THE AIRCRAFT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the appropriate power splits
Lam = LamOpt(1:nphi);

% fill the aircraft structure's mission history
Aircraft.Mission.History.SI.Power.LamTSPS(ielem(1:nphi)) = Lam;

Aircraft.Specs.Power.LamTSPS.Split = Aircraft.Mission.History.SI.Power.LamTSPS;

% ----------------------------------------------------------

end