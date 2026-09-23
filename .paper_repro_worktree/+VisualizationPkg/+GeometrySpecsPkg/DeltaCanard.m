function [Aircraft] = DeltaCanard(Aircraft)
%
% DeltaCanard.m
% written by Nawa Khailany, nawakhai@umich.edu
% 
% last updated: 3/24/2024
%
% geometric parameters for a delta canard configuration to showcase
% abilities of VisualizationPkg
%
% inputs : Aircraft - aircraft structure with no  geometry components
% outputs: Aircraft - aircraft structure with the geometry components
%

% ----------------------------------------------------------

%% DEFINE THE WING %%
%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% list geometric parameters  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Wing.AR         =  0.8 ;
Wing.area       = 5700  ;
Wing.taper      =   0.05;
Wing.sweep      =   55  ; %was 1 degree
Wing.dihedral   =   -2  ;
Wing.xShiftWing =   125 ;
Wing.yShiftWing =    0  ;
Wing.zShiftWing =    0  ;
Wing.symWing    =    1  ;

% parameters with characters
Wing.orientation           = 'xz'            ;
Wing.wingAfoil.airfoilName = '1204'          ;
Wing.type                  = 'liftingSurface';


%% DEFINE THE CANARD %%
%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Canard.AR         =   5.05;
Canard.area       = 350   ;
Canard.taper      =   0.6 ;
Canard.sweep      =   0  ; %was 7
Canard.dihedral   =   -2   ;
Canard.xShiftWing =  35   ;
Canard.yShiftWing =   0   ;
Canard.zShiftWing =  9.5   ;
Canard.symWing    =   1   ;

% parameters with characters
Canard.orientation           = 'xz'            ;
Canard.wingAfoil.airfoilName = '0004'          ;
Canard.type                  = 'liftingSurface';


%% DEFINE THE RIGHT VTAIL %%

% parameters with numerical values
VtailR.AR          = 2;
VtailR.area        = 130;
VtailR.taper       = 0.25  ;
VtailR.sweep       = 40  ;
VtailR.dihedral    =  30;
VtailR.xShiftWing  = 198 ;
VtailR.yShiftWing  = 8  ; 
VtailR.zShiftWing  = 0  ;
VtailR.symWing     = 0 ;

% parameters with characters
VtailR.orientation           = 'xy'            ;
VtailR.wingAfoil.airfoilName = '0004'          ;
VtailR.type                  = 'liftingSurface';

%% DEFINE THE LEFT VTAIL %%

% parameters with numerical values
VtailL.AR          = 2;
VtailL.area        = 130;
VtailL.taper       = 0.25  ;
VtailL.sweep       = 40  ;
VtailL.dihedral    =  -30;
VtailL.xShiftWing  = 198 ;
VtailL.yShiftWing  = -8  ; 
VtailL.zShiftWing  = 0  ;
VtailL.symWing     = 0 ;

% parameters with characters
VtailL.orientation           = 'xy'            ;
VtailL.wingAfoil.airfoilName = '0004'          ;
VtailL.type                  = 'liftingSurface';

%% DEFINE THE FUSELAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Fuselage.Length = 185;

% parameters with characters
Fuselage.type  = 'bluntBody';
Fuselage.Style = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "DeltaCanardFuselage.dat");

%% DEFINE THE ENGINE CASING %%

% parameters with numerical values
Casing.Length = 185;

% parameters with characters
Casing.type = 'bluntBody';
Casing.Style = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "DeltaCanardCasing.dat");


%% DEFINE THE ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Engine.Length            = 30  ;
Engine.EngineInletRadii  =  3  ;
Engine.EngineOutletRadii =  3;

% parameters with characters
Engine.type     = 'Engine';
Engine.Filename = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "DeltaCanard_Engines.dat");


%% REMEMBER THE GEOMETRY PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% save as one structure      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the top wing
Aircraft.Geometry.Wing  =  Wing;

% remember the htail
Aircraft.Geometry.Htail = Canard;

% remember the right vtail
Aircraft.Geometry.VtailR = VtailR;

% remember the left vtail
Aircraft.Geometry.VtailL = VtailL;

% remember the fuselage
Aircraft.Geometry.Fuselage = Fuselage;

% remember the engine casing
Aircraft.Geometry.Casing = Casing;

% remember the engines
Aircraft.Geometry.Engine = Engine;

% ----------------------------------------------------------

end