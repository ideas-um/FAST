function [] = TestAeroPkg(itest)
%
% [] = TestAeroPkg()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 06 jun 2025
%
% run tests to verify functionality or validate the aerodynamic package
% against a real-world example.
%
% INPUTS:
%     itest - index of test to run.
%             size/type/units: 1-by-1 / integer / []
%
% OUTPUTS:
%     none
%


%% PARSE INPUTS %%
%%%%%%%%%%%%%%%%%%

% check if a test is given
if (nargin < 1)
    
    % run a default test
    itest = 1;
    
end


%% TEST 0: FUNCTIONALITY ONLY %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (any(itest == 0))
   
    % get the segment ID
    Aircraft.Mission.Profile.SegsID = 1;
    
    % get the beginning and ending control point indices
    Aircraft.Mission.Profile.SegBeg =  1;
    Aircraft.Mission.Profile.SegEnd = 12;
    
    % get the mach number from the mission
    Aircraft.Mission.History.SI.Performance.Mach = [0.3; 0.4; 0.5; 0.6; 0.7; 0.8; 1.2; 1.4; 1.6; 1.8; 2.0; 2.2];
    Aircraft.Mission.History.SI.Aero.CL = [0.7500; 0.4219; 0.2700; 0.1875; 0.1378; 0.1055; 0.0469; 0.0344; 0.0264; 0.0208; 0.0169; 0.0139];

    % aerodynamic specifications
    Aircraft.Specs.Aero.DesignMach = 0.8;
    Aircraft.Specs.Aero.DesignCL = 0.5;
    Aircraft.Specs.Aero.BaseArea = 50 * UnitConversionPkg.ConvLength(1, "ft", "m") ^ 2;
    
    % wing specifications
    Aircraft.Specs.Aero.Wing.S = 1000 * UnitConversionPkg.ConvLength(1, "ft", "m") ^ 2;
    Aircraft.Specs.Aero.Wing.AR = 8;
    Aircraft.Specs.Aero.Wing.e = 0.95;
    Aircraft.Specs.Aero.Wing.Sweep = 30;
    Aircraft.Specs.Aero.Wing.TR = 0.3;
    Aircraft.Specs.Aero.Wing.t_c = 0.12;
    Aircraft.Specs.Aero.Wing.MaxCamber = 0.02;
    Aircraft.Specs.Aero.Wing.AirfoilTech = 1.05;
    Aircraft.Specs.Aero.Wing.Redux = 0;

    % fuselage specification
    Aircraft.Specs.Aero.Fuse.Area = 100 * UnitConversionPkg.ConvLength(1, "ft", "m") ^ 2;
    Aircraft.Specs.Aero.Fuse.Len_Diam = 10;
    Aircraft.Specs.Aero.Fuse.Diam_Span = 0.1;

    % component parameters for skin friction
    Aircraft.Specs.Aero.Components.Cf = [0.0025, 0.0023, 0.0022];
    Aircraft.Specs.Aero.Components.Fine = [0.13, 0.125, 0.1195];
    Aircraft.Specs.Aero.Components.LamFracUpper = [0.03, 0.03, 0.03];
    Aircraft.Specs.Aero.Components.LamFracLower = [0.02, 0.02, 0.02];
    Aircraft.Specs.Aero.Components.Re = [2e+6, 3e+6, 4e+6];
    Aircraft.Specs.Aero.Components.Swet = [2396.56, 592.65, 581.13] .* UnitConversionPkg.ConvLength(1, "ft", "m") ^ 2;
    
    % modeling/calibration assumptions
    Aircraft.Specs.Aero.ExcrescencesDrag = 1.06;
    Aircraft.Specs.Aero.ScaleCD0 = 1;
    Aircraft.Specs.Aero.ScaleCDI = 1;
    Aircraft.Specs.Aero.ScaleSub = 1;
    Aircraft.Specs.Aero.ScaleSup = 1;
    
end

%% TEST 1: ATR 42 %%
%%%%%%%%%%%%%%%%%%%%

if (any(itest == 1))
    
    % RESULTS FROM FAST:
    %     CD  = [ 0.042193;  0.031052;  0.027634;  0.038967]
    %     L_D = [18.064919; 16.036851; 16.572745; 18.253321]
    %
    % RESULTS FROM E-PASS:
    %     CD  = [ 0.044397;  0.033237;  0.028449;  0.040746];
    %     L_D = [17.160   ; 17.491   ; 16.090   ; 17.451   ];
    %
    % OTHER E-PASS INFO:
    % P = [1413.9; 784.7; 1361.7; 2003.4];  % lbf/ft^2
    % q = [90.7863; 136.4629; 141.0704; 86.6438];  % lbf/ft^2
    % L = [40595; 39864; 37899; 36152];  % lbf
    % t = [12.325; 49.608; 149.78; 243.89]; % min
    % h = [10731; 25000; 11690; 1500]; % m
    % D = [2365.7; 2662.7; 2355.5; 2071.6]; % lbf
    %
    
    % get the segment ID
    Aircraft.Mission.Profile.SegsID = 1;
    
    % get the beginning and ending control point indices
    Aircraft.Mission.Profile.SegBeg = 1;
    Aircraft.Mission.Profile.SegEnd = 4;
    
    % get the mach number from the mission
    Aircraft.Mission.History.SI.Performance.Mach = [0.30287; 0.49843; 0.3847; 0.24856];
    Aircraft.Mission.History.SI.Aero.CL = [0.762214; 0.497971; 0.457970; 0.711275];
    
    Aircraft.Specs.Aero.BaseArea = 0;  % Base area in m^2
    Aircraft.Specs.Aero.DesignCL = 0.6;  % Design lift coefficient
    Aircraft.Specs.Aero.DesignMach = 0.498;  % Design Mach number;
    Aircraft.Specs.Aero.ExcrescencesDrag = 0; % scale factor for excrescences drag
    Aircraft.Specs.Aero.ScaleCD0 = 1;
    Aircraft.Specs.Aero.ScaleCDI = 1;
    Aircraft.Specs.Aero.ScaleSub = 1.00641971;
    Aircraft.Specs.Aero.ScaleSup = 1;
    
    Aircraft.Specs.Aero.Components.Cf = [0.0028, 0.0029, 0.0026, 0.0020, 0.0026, 0.0026];  % Skin friction coefficient;%SkinFrictionCoeff; % (1-by-ncomp)
    Aircraft.Specs.Aero.Components.Fine = [0.16, 0.11, 0.10, 8.2511, 3.6272, 3.6272];  % Fineness ratios for different components
    Aircraft.Specs.Aero.Components.LamFracUpper = [0, 0, 0, 0, 0, 0];  % Upper surface laminar flow fractions
    Aircraft.Specs.Aero.Components.LamFracLower = [0, 0, 0, 0, 0, 0];  % Lower surface laminar flow fractions
    Aircraft.Specs.Aero.Components.Re = [127e+5, 88e+5, 197e+5, 1249e+5, 200e+5, 200e+5];  % Reynolds number
    Aircraft.Specs.Aero.Components.Swet = [1026.1, 250.21, 355.33, 1634.3, 109.66, 109.66] .* UnitConversionPkg.ConvLength(1, "ft", "m") ^ 2;  % Wetted areas given in ft^2
    
    Aircraft.Specs.Aero.Fuse.Area = 69.3920 .* UnitConversionPkg.ConvLength(1, "ft", "m") ^ 2;  % Fuselage cross section in ft^2
    Aircraft.Specs.Aero.Fuse.Diam_Span = 0.1166;  % Fuselage diameter to wing span ratio;%FuselageDiameterToWingSpan;
    Aircraft.Specs.Aero.Fuse.Len_Diam = 7.9127;  % Fuselage length to diameter ratio
    
    Aircraft.Specs.Aero.Wing.AR = 11.0768;  % Wing aspect ratio
    Aircraft.Specs.Aero.Wing.AirfoilTech = 1;%AirfoilTechnology; % scalar %%%
    Aircraft.Specs.Aero.Wing.e = 0.9892;  % Span efficiency factor
    Aircraft.Specs.Aero.Wing.MaxCamber = 0.0;  % Maximum camber at 70% semispan
    Aircraft.Specs.Aero.Wing.Redux = 0;
    Aircraft.Specs.Aero.Wing.S = 54.5;  % Wing area in m^2;%WingArea; %%%
    Aircraft.Specs.Aero.Wing.Sweep = 2.3;  % Wing sweep in degrees
    Aircraft.Specs.Aero.Wing.TR = 0.4918;  % Wing taper ratio;
    Aircraft.Specs.Aero.Wing.t_c = 0.16;  % Wing thickness to chord ratio
    
end


%% RUN THE TEST %%
%%%%%%%%%%%%%%%%%%

% run the code
Aircraft = AerodynamicsPkg.DragPolar(Aircraft);

% get the drag coefficient and lift-drag ratio
CD  = Aircraft.Mission.History.SI.Aero.CD ;
L_D = Aircraft.Mission.History.SI.Aero.L_D;

% print the results
fprintf(1, "CD from Test %d:\n", itest);
fprintf(1, "    %10.6f\n", CD);
fprintf(1, "\n");

fprintf(1, "L/D from Test %d:\n", itest)
fprintf(1, "    %10.6f\n", L_D)


end