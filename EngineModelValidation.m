function [] = EngineModelValidation(TSLS, Time, Alt, Mach, Treq, SFC)
%
% [] = EngineModelValidation()
% written by Paul Mokotoff, prmoko@umich.edu
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
clc, close all


%% GET THE ENGINE TO TEST %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the engine specifications
EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;

% update the design thrust
EngineSpecs.DesignThrust = TSLS;

% turn on the sizing flag
EngineSpecs.Sizing = 1;

% size the engine before running off-design
SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);


%% OFF-DESIGN TESTS %%
%%%%%%%%%%%%%%%%%%%%%%

% get the number of points in the mission profile
ntime = length(Time);

% allocate memory for the outputs
Tout = zeros(ntime, 1);
Fuel = zeros(ntime, 1);
TSFC = zeros(ntime, 1);

for itime = 1:ntime
    
    % set flight conditions
    OffParams.FlightCon.Mach = Mach(itime);
    OffParams.FlightCon.Alt  = Alt( itime);
    
    % set the thrust required
    OffParams.Thrust = Treq(itime);
    
    % run the analysis
    OffDesign = EngineModelPkg.TurbofanOffDesign(SizedEngine, OffParams, 0);
    
    % get the results
    Tout(itime) = OffDesign.Thrust;
    Fuel(itime) = OffDesign.Fuel;
    TSFC(itime) = OffDesign.TSFC_Imperial;
    
end


%% PLOT THE RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%

% scale time to minutes
Time = Time / 60;

% create a figure
figure;

% overall figure title
sgtitle("Engine Model Validation out of FAST");

% subplot: altitude as a function of time
subplot(2, 2, 1);
plot(Time, Alt , "-", "LineWidth", 2, "Color", "black");
xlabel("Time (min)");
ylabel("Altitude (m)");
set(gca, "FontSize", 16);

% subplot: mach number as a function of time
subplot(2, 2, 2);
plot(Time, Mach, "-", "LineWidth", 2, "Color", "black");
xlabel("Time (min)");
ylabel("Mach Number");
set(gca, "FontSize", 16);

% subplot: thrust required as a function of time
subplot(2, 2, 3);
hold on
plot(Time, Treq,  "-", "LineWidth", 2, "Color", "black");
plot(Time, Tout, "--", "LineWidth", 2, "Color", "red"  );
xlabel("Time (min)");
ylabel("Thrust (N)");
legend("FAST", "Off-Design", "Location", "northeast");
set(gca, "FontSize", 16);

% subplot: SFC as a function of time
subplot(2, 2, 4);
hold on
plot(Time,  SFC,  "-", "LineWidth", 2, "Color", "black");
plot(Time, TSFC, "--", "LineWidth", 2, "Color", "red"  );
xlabel("Time (min)");
ylabel("SFC (/hr)");
legend("FAST", "Off-Design", "Location", "northeast");
set(gca, "FontSize", 16);

end