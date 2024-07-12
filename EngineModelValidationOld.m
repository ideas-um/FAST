function [] = EngineModelValidationOld()
%
% [] = EngineModelValidationOld()
% written by ???
% updated by Paul Mokotoff, prmoko@umich.edu
% last updated: 20 jun 2024
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
clc%, close all

%% GET THE ENGINE %%
%%%%%%%%%%%%%%%%%%%%

% get the engine specifications
EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;

% turn on the sizing flag
EngineSpecs.Sizing = 1;

% resize the engine
%EngineSpecs.DesignThrust = 6.131651085555836e+04;

% size the engine before running off-design
SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);


%% OFF-DESIGN TESTS %%
%%%%%%%%%%%%%%%%%%%%%%

% set the flight conditions
OffParams.FlightCon.Mach = 0.78;
OffParams.FlightCon.Alt  = convlength(35000, "ft", "m");

% set a range of power codes
power_code_range = 0.01:0.001:1.1;

for i = 1:length(power_code_range)
    
    OffParams.Thrust = EngineSpecs.DesignThrust*power_code_range(i);
    
    OffDesign = EngineModelPkg.TurbofanOffDesign(SizedEngine,OffParams,0);
    Thrust(i) = OffDesign.Thrust/1000;
    Fuel(i) = OffDesign.Fuel;
    TSFC(i) = OffDesign.TSFC_Imperial;
end
figure;
plot(Thrust,Fuel, "LineWidth", 2)
hold on
plot(Thrust, 0.0194 * Thrust, "--", "LineWidth", 2)
legend("Engine Model", "Approximation");
xlabel("Thrust, kN");
ylabel('Fuel, kg/s')
set(gca, "FontSize", 16);
figure;
plot(Thrust,TSFC, "LineWidth", 2)
hold on
plot(Thrust, repmat(UnitConversionPkg.ConvTSFC(0.0194 / 1000, "SI", "Imp"), length(Thrust), 1), "--", "LineWidth", 2);
xlabel("Thrust, kN");
ylabel('TSFC, lb/lbf-hr')
set(gca, "FontSize", 16);
legend("Engine Model", "Approximation");

% fig = figure;
% subplot(1,3,1)
% plot(Thrust,Fuel, "LineWidth", 2)
% ylabel('Fuel, kg/s')
% set(gca,"FontSize", 16);
% subplot(1,3,2)
% plot(Thrust,Thrust, "LineWidth", 2)
% ylabel('Thrust, kN')
% set(gca,"FontSize", 16);
% subplot(1,3,3)
% plot(Thrust,TSFC, "LineWidth", 2)
% ylabel('TSFC, lb/lbf-hr')
% set(gca,"FontSize", 16);
% sgtitle('CF34-8E5')
% han=axes(fig,'visible','off');
% han.XLabel.Visible='on';
% set(gca,"FontSize", 16);
% xlabel(han,'Thrust, kN');
end