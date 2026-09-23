function [Aircraft] = SmallDoubleAisleTurbofan(Aircraft)
%
% SmallDoubleAisleTurbofan.m
% written by Nawa Khailany, nawakhai@umich.edu
% 
% last updated: 3/24/2024
%
% geometric parameters for a widebody turbofan jet modeled off the Boeing
% 777
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
Wing.AR         =  9.2 ;
Wing.area       = 4700  ;
Wing.taper      =   0.27;
Wing.sweep      =   30  ; 
Wing.dihedral   =   6  ;
Wing.xShiftWing =   90 ;
Wing.yShiftWing =    0  ;
Wing.zShiftWing =    -10  ;
Wing.symWing    =    1  ;

% parameters with characters
Wing.orientation           = 'xz'            ;
Wing.wingAfoil.airfoilName = '1204'          ;
Wing.type                  = 'liftingSurface';


%% DEFINE THE Htail %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Htail.AR         =   4;
Htail.area       = 750   ;
Htail.taper      =   0.3 ;
Htail.sweep      =   33  ; 
Htail.dihedral   =   4   ;
Htail.xShiftWing =  200   ;
Htail.yShiftWing =   0   ;
Htail.zShiftWing =  9.5   ;
Htail.symWing    =   1   ;

% parameters with characters
Htail.orientation           = 'xz'            ;
Htail.wingAfoil.airfoilName = '0012'          ;
Htail.type                  = 'liftingSurface';


%% DEFINE THE VTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Vtail.AR          = 2;
Vtail.area        = 700;
Vtail.taper       = 0.25  ;
Vtail.sweep       = 38  ;
Vtail.dihedral    =  0;
Vtail.xShiftWing  = 195 ;
Vtail.yShiftWing  = 0  ; 
Vtail.zShiftWing  = 11  ;
Vtail.symWing     = 0 ;

% parameters with characters
Vtail.orientation           = 'xy'            ;
Vtail.wingAfoil.airfoilName = '0012'          ;
Vtail.type                  = 'liftingSurface';

%% DEFINE THE FUSELAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Fuselage.Length = 217;

% parameters with characters
Fuselage.type  = 'bluntBody';
Fuselage.Style = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "WideBodyFuselage.dat");

%% DEFINE THE ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Engine.Length            = 30  ;
Engine.EngineInletRadii  =  8  ;
Engine.EngineOutletRadii =  7.5;

% parameters with characters
Engine.type     = 'Engine';
Engine.Filename = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "WideBody_Engines.dat");


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
Aircraft.Geometry.Htail = Htail;

% remember the right vtail
Aircraft.Geometry.Vtail = Vtail;

% remember the fuselage
Aircraft.Geometry.Fuselage = Fuselage;

% remember the engines
Aircraft.Geometry.Engine = Engine;

% ----------------------------------------------------------

end