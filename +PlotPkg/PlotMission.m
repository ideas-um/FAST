function [] = PlotMission(Aircraft)
%
% [] = PlotMission(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 29 aug 2024
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

% flight time
Time = Aircraft.Mission.History.SI.Performance.Time;

% altitude
Alt = Aircraft.Mission.History.SI.Performance.Alt;

% distance flown
Dist = Aircraft.Mission.History.SI.Performance.Dist;

% true airspeed
TAS = Aircraft.Mission.History.SI.Performance.TAS;

% aircraft mass
Mass = Aircraft.Mission.History.SI.Weight.CurWeight;

% fuel burn
Fburn = Aircraft.Mission.History.SI.Weight.Fburn;

% rate of climb
RC = Aircraft.Mission.History.SI.Performance.RC;

% power required/available as scalars (convert to MW) and spec. excess pow.
PreqScalar = Aircraft.Mission.History.SI.Power.Req      ./ 1.0e+06;
PavScalar  = Aircraft.Mission.History.SI.Power.TV       ./ 1.0e+06;
Ps         = Aircraft.Mission.History.SI.Performance.Ps           ;

% power required/available/output as vectors (convert to MW)
PreqVector = Aircraft.Mission.History.SI.Power.Preq_PS ./ 1.0e+06;
 PavVector = Aircraft.Mission.History.SI.Power.Pav_PS  ./ 1.0e+06;
PoutVector = Aircraft.Mission.History.SI.Power.Pout_PS ./ 1.0e+06;

% thrust required/available/output as vectors (convert to kN)
TreqVector = Aircraft.Mission.History.SI.Power.Treq_PS ./ 1000;
 TavVector = Aircraft.Mission.History.SI.Power.Tav_PS  ./ 1000;
ToutVector = Aircraft.Mission.History.SI.Power.Tout_PS ./ 1000;

% SFC (then convert to lbm/hp/hr)
if (strcmpi(Aircraft.Specs.TLAR.Class, "Turbofan") == 1)
    
    % convert to english units (taken from TurbofanOnDesignCycle)
    SFC = Aircraft.Mission.History.SI.Propulsion.TSFC * 3600 / UnitConversionPkg.ConvForce(1, 'N', 'lbf') * UnitConversionPkg.ConvMass(1, 'kg', 'lbm');
    
elseif ((strcmpi(Aircraft.Specs.TLAR.Class, "Turboprop") == 1) || ...
        (strcmpi(Aircraft.Specs.TLAR.Class, "Piston"   ) == 1) )
    
    % convert to english units (taken from TurbopropOnDesignCycle)
    SFC = Aircraft.Mission.History.SI.Propulsion.TSFC * 3.6e3 / 0.00134102 * 2.20462;
   
else
    
    % throw an error
    error("ERROR - PlotMission: invalid aircraft class.");
    
end

% fuel flow
MDotFuel = Aircraft.Mission.History.SI.Propulsion.MDotFuel;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% convert to english units   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert time to minutes
Time = Time ./ 60;

% convert altitude to ft
Alt  = UnitConversionPkg.ConvLength(Alt , 'm', 'ft');

% convert distance flown to nmi
Dist = UnitConversionPkg.ConvLength(Dist, 'm', 'naut mi');

% convert airspeed to kts
TAS = UnitConversionPkg.ConvVel(TAS, 'm/s', 'kts');

% convert r/c to ft/min
RC  = UnitConversionPkg.ConvVel(RC , 'm/s', 'ft/min');

% convert masses to lbf
Weight = UnitConversionPkg.ConvMass(Mass , 'kg', 'lbm');
Fburn  = UnitConversionPkg.ConvMass(Fburn, 'kg', 'lbm');

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% profile flight performance %
% parameters: 2-by-2 subplot %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create figure and maximize it
figure;
set(gcf, 'Position', get(0, 'Screensize'));

% plot altitude against time
subplot(2, 2, 1);
PlotPkg.PlotPerfParam(Time, Alt, 0, "Flight Time (min)", "Altitude (ft)", "Altitude");

% plot distance against time
subplot(2, 2, 3);
PlotPkg.PlotPerfParam(Time, Dist, 0, "Flight Time (min)", "Distance Flown (nmi)", "Distance");

% plot velocity against time
subplot(2, 2, 2);
PlotPkg.PlotPerfParam(Time, TAS, 0, "Flight Time (min)", "Airspeed (kts)", "Airspeed (TAS)");

% plot rate of climb against time
subplot(2, 2, 4);
PlotPkg.PlotPerfParam(Time(1:end-1), RC(1:end-1), 1, "Flight Time (min)", "Rate of Climb (ft/min)", "Rate of Climb");

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% profile aircraft weights:  %
% 2-by-2 subplot with time   %
% and distance flown         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create figure and maximize it
figure;
set(gcf, 'Position', get(0, 'Screensize'));

% plot altitude against time
subplot(2, 2, 1);
PlotPkg.PlotPerfParam(Time, Alt, 0, "Flight Time (min)", "Altitude (ft)", "Altitude");

% plot distance against time
subplot(2, 2, 3);
PlotPkg.PlotPerfParam(Time, Dist, 0, "Flight Time (min)", "Distance Flown (nmi)", "Distance");

% plot the total weight
subplot(2, 2, 2);
PlotPkg.PlotPerfParam(Time, Weight, 0, "Flight Time (min)", "Aircraft Weight (lbf)", "Weight");

% plot the fuel burned
subplot(2, 2, 4);
PlotPkg.PlotPerfParam(Time, Fburn, 0, "Flight Time (min)", "Total Fuel Burned (lbf)", "Fuel Burn");

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% profile aircraft power/    %
% propulsion:                %
% 2-by-2 subplot with time   %
% and altitude               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create figure and maximize it
figure;
set(gcf, 'Position', get(0, 'Screensize'));

% plot altitude against time
subplot(2, 2, 1);
PlotPkg.PlotPerfParam(Time, Alt, 0, "Flight Time (min)", "Altitude (ft)", "Altitude");

% plot the power output
subplot(2, 2, 3);
PlotPkg.PlotPerfParam(Time, PoutVector, 0, "Flight Time (min)", "Power Output (MW)", "Power Output");

% plot the fuel flow
subplot(2, 2, 2);
PlotPkg.PlotPerfParam(Time, MDotFuel, 1, "Flight Time (min)", "Fuel Flow (kg/s)", "Fuel Flow");

% plot the sfc
subplot(2, 2, 4);
PlotPkg.PlotPerfParam(Time, SFC, 0, "Flight Time (min)", "SFC (lbm/hp/hr)", "SFC");

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% profile more power params: %
% 3-by-3 subplot             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create figure and maximize it
figure;
set(gcf, 'Position', get(0, 'Screensize'));

% plot altitude against time
subplot(3, 3, 1);
PlotPkg.PlotPerfParam(Time, Alt, 0, "Flight Time (min)", "Altitude (ft)", "Altitude");

% plot airspeed against time
subplot(3, 3, 4);
PlotPkg.PlotPerfParam(Time, TAS, 0, "Flight Time (min)", "Airspeed (kts)", "Airspeed (TAS)");

% plot rate of climb against time
subplot(3, 3, 7);
PlotPkg.PlotPerfParam(Time(1:end-1), RC(1:end-1), 1, "Flight Time (min)", "Rate of Climb (ft/min)", "Rate of Climb");

% plot power available/required against time
subplot(3, 3, [2, 3]);
hold on
PlotPkg.PlotPerfParam(Time,  PavVector, 0, "Flight Time (min)", "Power (MW)", "Power");
PlotPkg.PlotPerfParam(Time, PreqVector, 0, "Flight Time (min)", "Power (MW)", "Power");

% plot thrust available/required against time
subplot(3, 3, [5, 6]);
hold on
PlotPkg.PlotPerfParam(Time,  TavVector, 0, "Flight Time (min)", "Thrust (kN)", "Thrust");
PlotPkg.PlotPerfParam(Time, TreqVector, 0, "Flight Time (min)", "Thrust (kN)", "Thrust");

% plot thrust output against time
subplot(3, 3, 8);
PlotPkg.PlotPerfParam(Time(1:end-1), ToutVector(1:end-1, :), 0, "Flight Time (min)", "Thrust Output (N)", "Thrust Output");

% plot power output against time
subplot(3, 3, 9);
PlotPkg.PlotPerfParam(Time(1:end-1), PoutVector(1:end-1, :), 0, "Flight Time (min)", "Power Output (MW)", "Power Output");

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% profile more power params: %
% 2-by-2 subplot             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create figure and maximize it
figure;
set(gcf, 'Position', get(0, 'Screensize'));

% plot altitude against time
subplot(2, 2, 1);
PlotPkg.PlotPerfParam(Time, Alt, 0, "Flight Time (min)", "Altitude (ft)", "Altitude");

% plot specific excess power against time
subplot(2, 2, 3);
PlotPkg.PlotPerfParam(Time, Ps, 0, "Flight Time (min)", "Specific Excess Power (m/s)", "Specific Excess Power");

% plot power available against time
subplot(2, 2, 2);
PlotPkg.PlotPerfParam(Time, PavScalar, 0, "Flight Time (min)", "Power Available (MW)", "Total Power Available");

% plot power available against time
subplot(2, 2, 4);
PlotPkg.PlotPerfParam(Time, PreqScalar, 0, "Flight Time (min)", "Power Required (MW)", "Total Power Required");

% ----------------------------------------------------------

end