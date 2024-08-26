function [] = BADAValidation(SizedEngine, Lambda)
%
% [] = BADAValidation()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 09 aug 2024
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

% % if no engine is given, assume the traditional CF34-8E5 engine
% if (nargin < 1)
%     EngineModel = EngineModelPkg.EngineSpecsPkg.CF34_8E5;
% end
% 
% % get the engine specifications
% EngineSpecs = EngineModel;
% 
% % turn on the sizing flag
% EngineSpecs.Sizing = 1;
% 
% % size the engine before running off-design
% SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);

% remember the SLS thrust
SLSThrust = SizedEngine.Thrust.Net;


%% OFF-DESIGN TESTS %%
%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run off-design at SLS      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set flight conditions
OffParams.FlightCon.Mach = 0.05;
OffParams.FlightCon.Alt  = UnitConversionPkg.ConvLength(0, "ft", "m");

% set the thrust required
OffParams.Thrust = SLSThrust;

% remember the design thrust and SFC
OffDesign = EngineModelPkg.SimpleOffDesign(SizedEngine, OffParams, 0);

% get the results
BaseSLSTout = OffDesign.Thrust;
BaseSLSTSFC = OffDesign.TSFC_Imperial;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run off-design conditions  %
% at SLS                     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get a variety of thrusts
Thrust = linspace(0.50, 1.20, 200)' .* BaseSLSTout;

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
NormThrust = Tout ./ BaseSLSTout;
NormSFC    = TSFC ./ BaseSLSTSFC;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% plot the results           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create a figure
figure;

% plot sea-level results
plot(NormThrust(:, 1), NormSFC(:, 1), '-', 'LineWidth', 2, 'Color', 'black');

% format plot
title(sprintf("Engine Performance at SLS (%d%% Split)\nThrust = %.4e; SFC = %.4f", Lambda, BaseSLSTout, BaseSLSTSFC));
xlabel("Normalized Thrust");
ylabel("Normalized SFC"   );
grid on
set(gca, "FontSize", 18);
set(gcf, "Position", get(0, "Screensize"));

% set the file name
FileName = sprintf("EngineVal-%02d-SLS.svg", Lambda);

% save the plot
saveas(gcf, FileName);

% ----------------------------------------------------------

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
BaseCrsTout = OffDesign.Thrust;
BaseCrsTSFC = OffDesign.TSFC_Imperial;
        
% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run off-design conditions  %
% at SLS                     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get a variety of thrusts
Thrust = linspace(0.50, 1.20, 200)' .* BaseCrsTout;

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
NormThrust = Tout ./ BaseCrsTout;
NormSFC    = TSFC ./ BaseCrsTSFC;


%% PLOT THE RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%

% create a figure
figure;

% plot sea-level results
plot(NormThrust(:, 1), NormSFC(:, 1), '-', 'LineWidth', 2, 'Color', 'black');

% format plot
title(sprintf("Engine Performance at Cruise (%d%% Split)\nThrust = %.4e; SFC = %.4f", Lambda, BaseCrsTout, BaseCrsTSFC));
xlabel("Normalized Thrust");
ylabel("Normalized SFC"   );
grid on
set(gca, "FontSize", 18);
set(gcf, "Position", get(0, "Screensize"));

% set the file name
FileName = sprintf("EngineVal-%02d-Crs.svg", Lambda);

% save the plot
saveas(gcf, FileName);

end