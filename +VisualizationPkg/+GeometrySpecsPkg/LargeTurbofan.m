function [Aircraft] = LargeTurbofan(Aircraft)
%
% LargeTurbofan.m
% written by Nawa Khailany, nawakhai@umich.edu
% 
% last updated: 3/24/2024
%
% geometric parameters for a double decker transport aircraft modeled after
% the airbus a380
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
Wing.AR         =  7.8 ;
Wing.area       = 9100  ;
Wing.taper      =   0.25;
Wing.sweep      =   33  ; 
Wing.dihedral   =   5  ;
Wing.xShiftWing =   105 ;
Wing.yShiftWing =    0  ;
Wing.zShiftWing =    -17  ;
Wing.symWing    =    1  ;

% parameters with characters
Wing.orientation           = 'xz'            ;
Wing.wingAfoil.airfoilName = '2412'          ;
Wing.type                  = 'liftingSurface';


%% DEFINE THE Htail %%
%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Htail.AR         =   4;
Htail.area       = 1350   ;
Htail.taper      =   0.3 ;
Htail.sweep      =   36  ; 
Htail.dihedral   =   4   ;
Htail.xShiftWing =  220   ;
Htail.yShiftWing =   0   ;
Htail.zShiftWing =  15   ;
Htail.symWing    =   1   ;

% parameters with characters
Htail.orientation           = 'xz'            ;
Htail.wingAfoil.airfoilName = '0012'          ;
Htail.type                  = 'liftingSurface';


%% DEFINE THE VTAIL %%

% parameters with numerical values
Vtail.AR          = 2.5;
Vtail.area        = 1000;
Vtail.taper       = 0.2  ;
Vtail.sweep       = 40  ;
Vtail.dihedral    =  0;
Vtail.xShiftWing  = 210 ;
Vtail.yShiftWing  = 0  ; 
Vtail.zShiftWing  = 17  ;
Vtail.symWing     = 0 ;

% parameters with characters
Vtail.orientation           = 'xy'            ;
Vtail.wingAfoil.airfoilName = '0012'          ;
Vtail.type                  = 'liftingSurface';

%% DEFINE THE FUSELAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Fuselage.Length = 232;

% parameters with characters
Fuselage.type  = 'bluntBody';
Fuselage.Style = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "DoubleDeckFuselage.dat");

%% DEFINE THE ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Engine.Length            = 39  ;
Engine.EngineInletRadii  =  9  ;
Engine.EngineOutletRadii =  8.5;

% parameters with characters
Engine.type     = 'Engine';
Engine.Filename = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "DoubleDeck_Engines.dat");


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