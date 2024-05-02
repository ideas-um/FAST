function [Aircraft] = SmallTurboprop(Aircraft)
%
% [Aircraft] = SmallTurboprop(Aircraft)
% written by Nawa Khailany, nawakhai@umich.edu
% last updated: 10 mar 2024
%
% Define the geometric parameters for a small turboprop based on the
% Beechcraft Model 99.
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% list geometric parameters  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Wing.AR         =  10.1 ;
Wing.area       = 280  ;
Wing.taper      =   0.36;
Wing.sweep      =   1  ; %was 1 degree
Wing.dihedral   =   5  ;
Wing.xShiftWing =   25  ;
Wing.yShiftWing =    0  ;
Wing.zShiftWing =   1  ;
Wing.symWing    =    1  ;

% parameters with characters
Wing.orientation           = 'xz'            ;
Wing.wingAfoil.airfoilName = '2412'          ;
Wing.type                  = 'liftingSurface';

%% DEFINE THE HTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Htail.AR         =   5.05;
Htail.area       = 90   ;
Htail.taper      =   0.36;
Htail.sweep      =   8   ; %was 7
Htail.dihedral   =   3   ;
Htail.xShiftWing = 42   ;
Htail.yShiftWing =   0   ;
Htail.zShiftWing =  5   ;
Htail.symWing    =   1   ;

% parameters with characters
Htail.orientation           = 'xz'            ;
Htail.wingAfoil.airfoilName = '0012'          ;
Htail.type                  = 'liftingSurface';


%% DEFINE THE VTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Vtail.AR         =   5.05;
Vtail.area       = 40   ; %was 700
Vtail.taper      =   0.28;
Vtail.sweep      =  8    ; %was 15
Vtail.dihedral   =   0   ;
Vtail.xShiftWing =  42   ;
Vtail.yShiftWing =   0   ;
Vtail.zShiftWing =  5   ;
Vtail.symWing    =   0   ;

% parameters with characters
Vtail.orientation           = 'xy'            ;
Vtail.wingAfoil.airfoilName = '0008'          ;
Vtail.type                  = 'liftingSurface';


%% DEFINE THE FUSELAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Fuselage.Length = 44.5;

% parameters with characters
Fuselage.type  = 'bluntBody';
Fuselage.Style = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "Beech99Fuselage.dat");


%% DEFINE THE ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Engine.Length            = 4  ;
Engine.EngineInletRadii  =  3  ;
Engine.EngineOutletRadii =  2.5;

% parameters with characters
Engine.type     = 'Engine';
Engine.Filename = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "Beech99_Engines.dat");


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

% remember the vtail
Aircraft.Geometry.Vtail = Vtail;

%remember the fuselage
Aircraft.Geometry.Fuselage = Fuselage;

%remember the engines
Aircraft.Geometry.Engine = Engine;

% ----------------------------------------------------------

end