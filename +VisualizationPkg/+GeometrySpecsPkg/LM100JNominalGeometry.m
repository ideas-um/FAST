function [Aircraft] = LM100JNominalGeometry(Aircraft)
%
% [Aircraft] = LM100JNominalGeometry(Aircraft)
% written by Nawa Khailany, nawakhai@umich.edu
% updated by Paul Mokotoff,   prmoko@umich.edu
% last updated: 22 mar 2024
%
% Define the geometric parameters for the LM100J.
%
% INPUTS:
%     Aircraft - aircraft structure with no  geometry components
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft structure with the geometry components
%                size/type/units: 1-by-1 / struct / []
%


%% DEFINE THE WING %%
%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% list geometric parameters  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Wing.AR         =  10.1 ;
Wing.area       = 1900  ;
Wing.taper      =   0.36;
Wing.sweep      =   -5  ; %was 1 degree
Wing.dihedral   =   -1  ;
Wing.xShiftWing =   59  ;
Wing.yShiftWing =    0  ;
Wing.zShiftWing =   25  ;
Wing.symWing    =    1  ;

% parameters with characters
Wing.orientation           = 'xz'            ;
Wing.wingAfoil.airfoilName = '2412'          ;
Wing.type                  = 'liftingSurface';


%% DEFINE THE HTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Htail.AR         =   5.05;
Htail.area       = 800   ;
Htail.taper      =   0.33;
Htail.sweep      =   -7   ; %was 7
Htail.dihedral   =   0   ;
Htail.xShiftWing = 100   ;
Htail.yShiftWing =   0   ;
Htail.zShiftWing =  25   ;
Htail.symWing    =   1   ;

% parameters with characters
Htail.orientation           = 'xz'            ;
Htail.wingAfoil.airfoilName = '0012'          ;
Htail.type                  = 'liftingSurface';


%% DEFINE THE VTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Vtail.AR         =   5.05;
Vtail.area       = 350   ; %was 700
Vtail.taper      =   0.28;
Vtail.sweep      =  0    ; %was 15
Vtail.dihedral   =   0   ;
Vtail.xShiftWing =  95   ;
Vtail.yShiftWing =   0   ;
Vtail.zShiftWing =  25   ;
Vtail.symWing    =   0   ;

% parameters with characters
Vtail.orientation           = 'xy'            ;
Vtail.wingAfoil.airfoilName = '0008'          ;
Vtail.type                  = 'liftingSurface';


%% DEFINE THE FUSELAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Fuselage.Length = 112.75;

% parameters with characters
Fuselage.type  = 'bluntBody';
Fuselage.Style = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "LM100J.dat");


%% DEFINE THE ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Engine.Length            = 15  ;
Engine.EngineInletRadii  =  5  ;
Engine.EngineOutletRadii =  4.5;

% parameters with characters
Engine.type     = 'Engine';
Engine.Filename = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "LM100J_Engines.dat");


%% REMEMBER THE GEOMETRY PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% save as one structure      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the wing
Aircraft.Geometry.Wing  =  Wing;

% remember the htail
Aircraft.Geometry.Htail = Htail;

% remember the vtail
Aircraft.Geometry.Vtail = Vtail;

%remember the fuselage
Aircraft.Geometry.Fuselage = Fuselage;

%remember the engines
Aircraft.Geometry.Engine = Engine;

% ----------------------------------------------------------

end