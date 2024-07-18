function [Aircraft] = TakeoffTestProfile(Aircraft)
%
% TakeoffTestProfile.m
% written by Nawa Khailany, nawakhai@umich.edu
% last updated: 12 Jun 2024
%
% define a mostly takeoff flight profile for testing
%
% mission 1: 1.7 nmi range                
%                                           
%                                           
%                                           
%        ___________________________________
%       /
%      /
%     /
%    /
% __/
%
% inputs : Aircraft - aircraft structure (without a mission profile)
% outputs: Aircraft - aircraft structure (with    a mission profile)
%

% ----------------------------------------------------------

%% DEFINE THE MISSION RANGES (TARGETS) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the targets (in m or min)
Mission.Target.Valu = convlength(1.7, "naut mi", "m");

% list the target types ("Dist" or "Time")
Mission.Target.Type = "Dist";


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["DetailedTakeoff"; "Climb"; "Cruise"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [        1;       1;        1];

% define the starting/ending altitudes (in m)
Mission.AltBeg = convlength([0;     0; 50], "ft", "m");
Mission.AltEnd = convlength([0; 50; 50], "ft", "m");

% define the climb rate (in m/s)
Mission.ClbRate = [  NaN;   NaN;   NaN];

% define the starting/ending speeds (in m/s)
Mission.VelBeg = convvel([  0; 140; 140], "kts", "m/s");
Mission.VelEnd = convvel([140; 140; 140], "kts", "m/s");

% define the speed types ("TAS", "EAS", or "Mach")
Mission.TypeBeg = ["TAS"; "TAS"; "TAS"];
Mission.TypeEnd = ["TAS"; "TAS"; "TAS"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end