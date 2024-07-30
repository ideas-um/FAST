function [Aircraft] = TestGeometry(iarch)
%
% TestGeometry.m
% written by Paul Mokotoff, prmoko@umich.edu
%            Nawa Khailany, nawakhai@umich.edu
% last updated: 3/28/2024
%
% try to create and plot an aircraft geometry configuration.
%
% inputs : none
% outputs: Aircraft - structure filled with the geometric parameters.
%

% ----------------------------------------------------------

% initial cleanup
clc, close all


%% GET THE GEOMETRIC PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the geometric parameters 
if     (iarch == 1)

    [Aircraft] = VisualizationPkg.GeometrySpecsPkg.Transport();

elseif (iarch == 2)

    [Aircraft] = VisualizationPkg.GeometrySpecsPkg.SmallDoubleAisleTurbofan();

elseif (iarch == 3)

    [Aircraft] = VisualizationPkg.GeometrySpecsPkg.LargeTurbofan();

elseif (iarch == 4)

    [Aircraft] = VisualizationPkg.GeometrySpecsPkg.LargeTurboprop();

elseif (iarch == 5)

    [Aircraft] = VisualizationPkg.GeometrySpecsPkg.SmallTurboprop();

elseif (iarch == 6)

    [Aircraft] = VisualizationPkg.GeometrySpecsPkg.LM100JNominalGeometry();

elseif (iarch == 7)

    [Aircraft] = VisualizationPkg.GeometrySpecsPkg.LM100JTrussBraced();

elseif (iarch == 8)

    [Aircraft] = VisualizationPkg.GeometrySpecsPkg.DeltaCanard();

elseif (iarch == 9)

    [Aircraft] = VisualizationPkg.GeometrySpecsPkg.SUSAN();

elseif (iarch == 10)

    [Aircraft] = VisualizationPkg.GeometrySpecsPkg.BWB();

end

% plot/view the geometry
[Aircraft, ~] = VisualizationPkg.vGeometry(Aircraft);

% ----------------------------------------------------------

end