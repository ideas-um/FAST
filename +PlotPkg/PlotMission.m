function [] = PlotMission(Aircraft)
%
% [] = PlotMission(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 19 aug 2024
%
% Obtain the mission history from the aircraft structure, convert necessary
% values from SI to English units, and plot them.
%
% INPUTS:
%     Aircraft - structure with "Aircraft.Mission.History.SI" filled after
%                flying a given mission.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     none
%

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get performance metrics    %
% from the structure         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% flight time (convert to minutes)
Time = Aircraft.Mission.History.SI.Performance.Time ./ 60;

% altitude
Alt = Aircraft.Mission.History.SI.Performance.Alt;

% distance flown (convert to km)
Dist = Aircraft.Mission.History.SI.Performance.Dist ./ 1000;

% true airspeed
TAS = Aircraft.Mission.History.SI.Performance.TAS;

% rate of climb (convert from m/s to m/min)
RC = Aircraft.Mission.History.SI.Performance.RC .* 60;

% fuel burn
Fburn = Aircraft.Mission.History.SI.Weight.Fburn;

% power and thrust output as vectors (convert to MW and kN, respectively)
PoutVector = Aircraft.Mission.History.SI.Power.Pout_PS ./ 1.0e+06;
ToutVector = Aircraft.Mission.History.SI.Power.Tout_PS ./ 1.0e+03;

% state of charge
SOC = Aircraft.Mission.History.SI.Power.SOC;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% profile above parameters   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create figure and maximize it
figure;
set(gcf, 'Position', get(0, 'Screensize'));

% plot altitude against time
subplot(4, 2, 1);
PlotPkg.PlotPerfParam(Time, Alt, "", sprintf("Altitude \n (m)"));

% plot velocity against time
subplot(4, 2, 3);
PlotPkg.PlotPerfParam(Time, TAS, "", sprintf("Airspeed \n (m/s)"));

% plot rate of climb against time
subplot(4, 2, 5);
PlotPkg.PlotPerfParam(Time(1:end-1), RC(1:end-1), "", sprintf("Rate of \n Climb (m/min)"));

% plot distance against time
subplot(4, 2, 7);
PlotPkg.PlotPerfParam(Time, Dist, "Flight Time (min)", sprintf("Distance \n Flown(km)"));

% plot the power output
subplot(4, 2, 2);
PlotPkg.PlotPerfParam(Time, PoutVector(:, [1, 3]), "", sprintf("Shaft Power \n (MW)"));
legend("Gas Turbine Engine", "Electric Motor", "Location", "north");

% plot thrust output against time
subplot(4, 2, 4);
PlotPkg.PlotPerfParam(Time(1:end-1), ToutVector(1:end-1, [1, 3]), "", sprintf("Net Thrust \n (kN)"));
legend("Gas Turbine Engine", "Electric Motor", "Location", "north");

% plot the fuel burn against time
subplot(4, 2, 6);
PlotPkg.PlotPerfParam(Time, Fburn(:, 1), "", sprintf("Fuel Burn \n (kg)"));

% plot the SOC
subplot(4, 2, 8);
PlotPkg.PlotPerfParam(Time, SOC(:, 2), "Flight Time (min)", sprintf("Battery State \n of Charge (%%)"));

% ----------------------------------------------------------

end