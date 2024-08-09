function [] = BADAValidation()
%
% [] = BADAValidation()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 08 aug 2024
%
% Test the off-design engine model.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%

% initial cleanup
clc, close all


%% GET THE ENGINE TO TEST %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the engine specifications
EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;

% turn on the sizing flag
EngineSpecs.Sizing = 1;

% size the engine before running off-design
SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);

% remember the SLS thrust
SLSThrust = SizedEngine.Thrust.Net;


%% OFF-DESIGN TESTS %%
%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run off-design at cruise   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set flight conditions
OffParams.FlightCon.Mach = 0.8;
OffParams.FlightCon.Alt  = UnitConversionPkg.ConvLength(35000, "ft", "m");

% get the flight conditions
[~, ~, ~, ~, ~, RhoSLS] = MissionSegsPkg.ComputeFltCon(0                      , 0, "Mach", 0);
[~, ~, ~, ~, ~, RhoCrs] = MissionSegsPkg.ComputeFltCon(OffParams.FlightCon.Alt, 0, "Mach", 0);

% get the density ratio
RhoRatio = RhoCrs / RhoSLS;

% set the thrust required
OffParams.Thrust = SLSThrust * RhoRatio;

% remember the design thrust and SFC
OffDesign = EngineModelPkg.SimpleOffDesign(SizedEngine, OffParams, 0);

% get the results
BaseTout = OffDesign.Thrust;
BaseTSFC = OffDesign.TSFC_Imperial;
        
% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run off-design conditions  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get a variety of thrusts
Thrust = linspace(0.50, 1.20, 200)' .* BaseTout;

% get the number of thrust/altitude combinations
nthrust = length(Thrust);

% allocate memory for the outputs
Tout = zeros(nthrust, 1);
Fuel = zeros(nthrust, 1);
TSFC = zeros(nthrust, 1);

% loop through all flight conditions
for ithrust = 1:nthrust
        
    % set the thrust required
    OffParams.Thrust = Thrust(ithrust);
    
    % run the analysis
    OffDesign = EngineModelPkg.SimpleOffDesign(SizedEngine, OffParams, 0);
    
    % get the results
    Tout(ithrust) = OffDesign.Thrust;
    Fuel(ithrust) = OffDesign.Fuel;
    TSFC(ithrust) = OffDesign.TSFC_Imperial;
    
end

% normalize the thrust and SFC
NormThrust = Tout ./ BaseTout;
NormSFC    = TSFC ./ BaseTSFC;


%% PLOT THE RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%

% create a figure
figure;

% plot sea-level results
plot(NormThrust(:, 1), NormSFC(:, 1), '-', 'LineWidth', 2, 'Color', 'black');

% format plot
title("ERJ Engine Performance at Cruise");
xlabel("Normalized Thrust");
ylabel("Normalized SFC"   );
grid on
set(gca, "FontSize", 18);

end