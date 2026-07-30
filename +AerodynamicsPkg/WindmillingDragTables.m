function [] = WindmillingDragTables()
%
% [] = WindmillingDragTables()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 06 jun 2025
%
% using the "WindmillingDrag" data, develop interpolation tables that can
% be saved as a .mat file and loaded for analyses in the future.
%
% INPUTS:
%     none - however, ensure that "WindmillingDrag.xlsx" is in the
%            "AerodynamicsPkg" before running this code.
%
% OUTPUTS:
%     none - but it will create "WindmillingDrag.mat", a MATLAB data file.
%


%% IMPORT THE SPREADSHEET %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% import the spreadsheet
ImportedSheet = readtable(fullfile("+AerodynamicsPkg", "WindmillingDrag.xlsx"));

% get the specific thrust
SpecThrust = ImportedSheet{:, 1};

% get the theoretical drag coefficient
TheoryCD = ImportedSheet{:, 2};

% get the drag coefficient deltas
DeltaCD = ImportedSheet{:, 3:7};


%% CREATE INTERPOLANTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% mach numbers for interpolation
MachNumber = 0.2 : 0.2 : 1.0;

% interpolant for the theoretical CD
InterpTheoryCD = griddedInterpolant(SpecThrust, TheoryCD);

% interpolant for the drag coefficient delta
InterpDeltaCD  = griddedInterpolant({SpecThrust, MachNumber}, DeltaCD );

% save the interpolants
save(fullfile("+AerodynamicsPkg", "WindmillingDrag.mat"), ...
     "InterpTheoryCD", "InterpDeltaCD");

% ----------------------------------------------------------

end