function [] = DemoModelingTechniques()
%
% [] = DemoModelingTechniques()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 16 feb 2026
%
% size a notional Airbus A320 model using three different modeling
% approaches to showcase the accuracy and efficiency of the problem
% relative to historical data.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%

%% NOTIONAL A320 SIZING %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% initial cleanup
clear, clc, close all


%% ONLY DEFINE TOP-LEVEL AIRCRAFT REQUIREMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the required inputs: number of passengers, aircraft class, design
% range, and propulsion system architecture
TLARsOnly.Specs.TLAR.MaxPax              =  160      ;
TLARsOnly.Specs.Performance.Range        = 4815e+03  ; % (km)
TLARsOnly.Specs.TLAR.Class               = "Turbofan";
TLARsOnly.Specs.Propulsion.PropArch.Type = "C"       ;

% start a timer
tic;

% size the aircraft on the known A320 mission profile
TLARsOnly = Main(TLARsOnly,@MissionProfilesPkg.A320);

% stop the timer
toc;

% print percent error for MTOW, OEW, fuel, and engine weights
PrintError(TLARsOnly)


%% SIZE FROM THE AIRCRAFT SPECIFICATION FILE USING CONSTANT L/D RATIOS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the aircraft
ConstantLD = AircraftSpecsPkg.A320Neo;

% use a constant L/D
ConstantLD.Specs.Aero.L_D.Method = @(Aircraft) AerodynamicsPkg.ConstantLD(Aircraft);

% start a timer
tic;

% size the configuration
ConstantLD = Main(ConstantLD, @MissionProfilesPkg.A320);

% stop the timer
toc;

% print percent error for MTOW, OEW, fuel, and engine weights
PrintError(ConstantLD);


%% SIZE FROM THE AIRCRAFT SPECIFICATION FILE USING AVIARY'S DRAG POLAR %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the aircraft
DragPolar = AircraftSpecsPkg.A320Neo;

% use a constant L/D
DragPolar.Specs.Aero.L_D.Method = @(Aircraft) AerodynamicsPkg.DragPolar(Aircraft);

% start a timer
tic;

% size the configuration
DragPolar = Main(DragPolar, @MissionProfilesPkg.A320);

% stop the timer
toc;

% print percent error for MTOW, OEW, fuel, and engine weights
PrintError(DragPolar);


%% PLOT THE L/D CURVES FOR EACH CONFIGURATION ANALYZED %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create a figure
figure;

% enable multiple plots
hold on

% plot the L/D curves
plot( TLARsOnly.Mission.History.SI.Performance.Time ./ 60,  TLARsOnly.Mission.History.SI.Aero.L_D, "-", "LineWidth", 3, "Color", "black");
plot(ConstantLD.Mission.History.SI.Performance.Time ./ 60, ConstantLD.Mission.History.SI.Aero.L_D, "-", "LineWidth", 3, "Color", "blue" );
plot( DragPolar.Mission.History.SI.Performance.Time ./ 60,  DragPolar.Mission.History.SI.Aero.L_D, ":", "LineWidth", 3, "Color", "red"  );

% axis labels
xlabel("Time (min.)");
ylabel("Lift-to-Drag Ratio");

% turn on the grid
grid on

% add a legend
legend("TLARs Only", "Constant L/D", "Drag Polar", "Location", "south");

% enlarge font
set(gca, "FontSize", 20);


end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [] = PrintError(Aircraft)
%
% [] = PrintError(Aircraft)
% written by Maxfield Arnson
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 16 feb 2026
%
% print the error associated with the sized aircraft relative to the
% historical data.
%
% INPUTS:
%     Aircraft - data structure with information about the aircraft.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     none
%

% actual A320 weights (MTOW, OEW, fuel, engines)
TrueWeights = [79000,42600,19051,2990*2];
   
% get the weights from the model
ModelWeights = [Aircraft.Specs.Weight.MTOW,Aircraft.Specs.Weight.OEW,Aircraft.Specs.Weight.Fuel,Aircraft.Specs.Weight.Engines];

% compute the percent error
Error = 100 .* (ModelWeights - TrueWeights) ./ TrueWeights;

% print the error
fprintf(1, "Weight Errors:        \n"          );
fprintf(1,"------------------     \n"          );
fprintf(1, "MTOW:       %+05.1f%% \n", Error(1));
fprintf(1, "OEW:        %+05.1f%% \n", Error(2));
fprintf(1, "Fuel:       %+05.1f%% \n", Error(3));
fprintf(1, "Engine(s):  %+05.1f%% \n", Error(4));
fprintf(1,"------------------     \n"          );


end