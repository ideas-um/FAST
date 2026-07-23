function [Aircraft] = StandardTurbofanProfile(Aircraft)
%
% [Aircraft] = StandardTurbofanProfile(Aircraft)
% original version written for the A320 by Max Arnson, marnson@umich.edu
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 30 apr 2025
%
% define a standard design mission for any turbofan aircraft.
%
% mission 1: climb to 4,000 ft less than service ceiling, cruise for 1/3 of the design range
% mission 2: climb to 2,000 ft less than service ceiling, cruise for 1/3 of the design range
% mission 3: climb to the service ceiling, cruise for 1/3 of the design range
% mission 4: descent and FAA-required diversion
% mission 5: FAA-required loiter, descent and landing
%
%             |          |                   |              |
%             |          | _________         |              |
%             | _________|/         \        |              |
%        _____|/         |           \       |              |
%       /     |          |            \      |              |
%      /      |          |             \     |  __________  |
%     /       |          |              \    | /          \ |  
%    /        |          |               \___|/            \|______
% __/         |          |                   |              |      \__
%      1            2                3               4            5
%
% INPUTS:
%     Aircraft - aircraft structure (without a mission profile).
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft structure (with    a mission profile).
%                size/type/units: 1-by-1 / struct / []
%


%% RETRIEVE AIRCRAFT PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the service ceiling
ServCeil = Aircraft.Specs.Performance.Alts.Crs;

% get the design range
DesRange = Aircraft.Specs.Performance.Range;

% get the cruise speed (mach number)
CrsMach = Aircraft.Specs.Performance.Vels.Crs;


%% ADDITIONAL CALCULATIONS AND UNIT CONVERSIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the other altitudes
IntAlt1 = ServCeil - UnitConversionPkg.ConvLength(10000, "ft", "m");
IntAlt2 = ServCeil - UnitConversionPkg.ConvLength( 8000, "ft", "m");
CrsAlt  = ServCeil - UnitConversionPkg.ConvLength( 6000, "ft", "m");

% compute the diversion distance
DivDist = UnitConversionPkg.ConvLength(200, "naut mi", "m");

% intermediate climb altitude
IntClbAlt = UnitConversionPkg.ConvLength(10000, "ft", "m");

% diversion altitude
DivAlt = UnitConversionPkg.ConvLength(15000, "ft", "m");

% approach altitude
AppAlt = UnitConversionPkg.ConvLength(1500, "ft", "m");

% get the intermediate climb velocity
IntClbVel = UnitConversionPkg.ConvVel(250, "kts", "m/s");


%% DEFINE THE MISSION TARGETS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the targets (in m or min)
Mission.Target.Valu = [ ...
    repmat(DesRange / 3, 3, 1); ... % design range, split into thirds
    DivDist;                    ... % diversion
    30                          ... % loiter
    ];

% define the target types ("Dist" or "Time")
Mission.Target.Type = ["Dist"; "Dist"; "Dist"; "Dist"; "Time"];


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"  ; "Climb"  ; "Cruise"; ...
                "Climb"  ; "Cruise" ;                      ...
                "Climb"  ; "Cruise" ; "Descent";           ...
                "Climb"  ; "Cruise" ; "Descent";           ...
                "Cruise" ; "Descent"; "Landing"            ] ;

% define the mission id (segments in same mission must be consecutive)
Mission.ID = [1; 1; 1; 1; ...
              2; 2;       ...
              3; 3; 3;    ...
              4; 4; 4;    ...
              5; 5; 5     ] ;

% define the starting/ending altitudes (in m)
Mission.AltBeg = [0      ; 0      ; IntClbAlt; IntAlt1; ...
                  IntAlt1; IntAlt2;                     ...
                  IntAlt2; CrsAlt ; CrsAlt   ;          ...
                  AppAlt ; DivAlt ; DivAlt   ;          ...
                  AppAlt ; AppAlt ; 0                   ] ;

Mission.AltEnd = [0      ; IntClbAlt; IntAlt1; IntAlt1; ...
                  IntAlt2; IntAlt2  ;                   ...
                  CrsAlt ; CrsAlt   ; AppAlt ;          ...
                  DivAlt ; DivAlt   ; AppAlt ;          ...
                  AppAlt ; 0        ; 0                 ] ;

% define the climb rate (in m/s)
Mission.ClbRate = [NaN; NaN; NaN; NaN; ...
                   NaN; NaN;           ...
                   NaN; NaN; NaN;      ...
                   NaN; NaN; NaN;      ...
                   NaN; NaN; NaN       ] ;

% define the starting/ending speeds
Mission.VelBeg = [0      ; 0.3    ; IntClbVel; CrsMach; ...
                  CrsMach; CrsMach;                     ...
                  CrsMach; CrsMach; CrsMach  ;          ...
                  0.3    ; 0.3    ; 0.3      ;          ...
                  0.3    ; 0.3    ; 0.3                 ] ;

Mission.VelEnd = [0.3    ; IntClbVel; CrsMach; CrsMach; ...
                  CrsMach; CrsMach  ;                   ...
                  CrsMach; CrsMach  ; 0.3    ;          ...
                  0.3    ; 0.3      ; 0.3    ;          ...
                  0.3    ; 0.3      ; 0                 ] ;

% define the speed types
Mission.TypeBeg = ["Mach"; "Mach"; "TAS" ; "Mach"; ...
                   "Mach"; "Mach";                 ...
                   "Mach"; "Mach"; "Mach";         ...
                   "Mach"; "Mach"; "Mach";         ...
                   "Mach"; "Mach"; "Mach"          ] ;

Mission.TypeEnd = ["Mach"; "TAS" ; "Mach"; "Mach"; ...
                   "Mach"; "Mach";                 ...
                   "Mach"; "Mach"; "Mach";         ...
                   "Mach"; "Mach"; "Mach";         ...
                   "Mach"; "Mach"; "Mach"          ] ;


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end