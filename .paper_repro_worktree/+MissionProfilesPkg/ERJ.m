function [Aircraft] = ERJ(Aircraft)
%
% [Aircraft] = ERJ(Aircraft)
% written by Emma Smith, emmasmit@umich.edu
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Parametric mission for the ERJ175LR (but can be accommodated for any
% regional jet)           
% 
% part 1: fly at design range                    | part 2: 100  | part 3: 
%                                                | nmi diversion| 45 min 
%                                                | at 10,000 ft | loiter
%                                                |              |
%                                                |              |
%           _____________________________        |              |   
%          /                             \       |              |
%      ___/                               \___   |    __________|___
%     /                                       \  |  _/          |   \_
%    /                                         \_|_/            |     \
% __/                                            |              |      \__
%
%
% INPUTS:
%     Aircraft - aircraft structure (without a mission profile).
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft structure (with    a mission profile).
%                size/type/units: 1-by-1 / struct / []
%


%% IMPORT THE PERFORMANCE PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% mission range
Range = Aircraft.Specs.Performance.Range;

% takeoff and cruise altitudes
AltTko = Aircraft.Specs.Performance.Alts.Tko;
AltCrs = Aircraft.Specs.Performance.Alts.Crs;

% start/end of constant EAS climb alt
AltClb     =          UnitConversionPkg.ConvLength(3000, "ft", "m");
AltClb2Crs = AltCrs - UnitConversionPkg.ConvLength(1000, "ft", "m");

% reserve mission altitudes - assume descent follows same path as climb
ResAltBeg     =             UnitConversionPkg.ConvLength( 1500, "ft", "m");
ResAltClb     =             UnitConversionPkg.ConvLength( 3000, "ft", "m");
ResAltCrs     =             UnitConversionPkg.ConvLength(10000, "ft", "m");
ResAltClb2Crs = ResAltCrs - UnitConversionPkg.ConvLength( 1000, "ft", "m");

% takeoff and cruise speeds
VelTko = Aircraft.Specs.Performance.Vels.Tko; % TAS
VelCrs = Aircraft.Specs.Performance.Vels.Crs; % Mach

% approach for landing speed
VelApr = 1.2 * VelTko; % TAS

% climb & descent is constant EAS
VelClb = UnitConversionPkg.ConvVel(200, "kts", "m/s"); % EAS
VelDes = UnitConversionPkg.ConvVel(200, "kts", "m/s"); % EAS

% reserve speeds
ResVelClb = UnitConversionPkg.ConvVel(200, "kts", "m/s"); % EAS
ResVelDes = UnitConversionPkg.ConvVel(200, "kts", "m/s"); % EAS
ResVelCrs = UnitConversionPkg.ConvVel(250, "kts", "m/s"); % TAS

% speed type
TAS  = "TAS" ;
EAS  = "EAS" ;
Mach = "Mach";


%% DEFINE THE MISSION TARGETS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the targets (in m or min)
Mission.Target.Valu = [Range; UnitConversionPkg.ConvLength(100, "naut mi", "m"); 45];

% define the target types ("Dist" or "Time")
Mission.Target.Type = ["Dist"; "Dist"; "Time"];


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb";   "Climb";   "Climb"; "Cruise";  "Descent";  "Descent";  "Descent";  "Climb";       "Climb";       "Climb"; "Cruise";   "Cruise";     "Descent";    "Descent";"Descent";"Landing";];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [       1;      1;          1;          1;       1;          1;          1;         1;         2;             2;            2;         2;         3;             3;            3;         3;      3;];

% define the starting/ending altitudes (in m)
Mission.AltBeg = [AltTko; AltTko;     AltClb; AltClb2Crs;  AltCrs;     AltCrs; AltClb2Crs;    AltClb; ResAltBeg;     ResAltClb; ResAltClb2Crs; ResAltCrs; ResAltCrs;     ResAltCrs; ResAltClb2Crs; ResAltClb; AltTko;];
Mission.AltEnd = [AltTko; AltClb; AltClb2Crs;     AltCrs;  AltCrs; AltClb2Crs;     AltClb; ResAltBeg; ResAltClb; ResAltClb2Crs;     ResAltCrs; ResAltCrs; ResAltCrs; ResAltClb2Crs;     ResAltClb;    AltTko; AltTko;];

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg = [     0; VelTko;     VelClb;     VelClb;  VelCrs;     VelCrs;     VelDes;    VelDes;    VelApr;     ResVelClb;     ResVelClb; ResVelCrs; ResVelCrs;    ResVelCrs;     ResVelDes; ResVelDes; VelApr;];
Mission.VelEnd = [VelTko; VelClb;     VelClb;     VelCrs;  VelCrs;     VelDes;     VelDes;    VelApr; ResVelClb;     ResVelClb;     ResVelCrs; ResVelCrs; ResVelCrs;    ResVelDes;     ResVelDes;    VelApr;      0;];

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg = [ TAS;     TAS;        EAS;        EAS;    Mach;       Mach;        EAS;       EAS;      TAS;           EAS;           EAS;      TAS;      TAS;         TAS;           EAS;       EAS;   TAS;];
Mission.TypeEnd = [ TAS;     EAS;        EAS;       Mach;    Mach;        EAS;        EAS;       TAS;      EAS;           EAS;           TAS;      TAS;      TAS;         EAS;           EAS;       TAS;   TAS;];

% no climb rate defined now (if there was one, it would be in m/s)
Mission.ClbRate = NaN(length(Mission.ID), 1);


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end