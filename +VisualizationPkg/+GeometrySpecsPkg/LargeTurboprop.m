function [Aircraft] = LargeTurboprop(Aircraft)
%
% [Aircraft] = LargeTurboprop(Aircraft)
% written by Nawa Khailany, nawakhai@umich.edu
% last updated: 22 mar 2024
%
% Define the geometric parameters for a small turboprop based on an ATR 72.
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
Wing.AR         =   13  ;
Wing.area       =  657  ;
Wing.taper      =   0.7 ; 
Wing.sweep      =   0   ; 
Wing.dihedral   =   -1  ;
Wing.xShiftWing =    50 ;
Wing.yShiftWing =    0  ;
Wing.zShiftWing =   5  ;
Wing.symWing    =    1  ;

% parameters with characters
Wing.orientation           = 'xz'            ;
Wing.wingAfoil.airfoilName = '2412'          ;
Wing.type                  = 'liftingSurface';


%% DEFINE THE HTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Htail.AR         =   5.05;
Htail.area       = 165   ;
Htail.taper      =  0.8  ;
Htail.sweep      =   0   ; %was 7
Htail.dihedral   =   0   ;
Htail.xShiftWing = 88   ;
Htail.yShiftWing =   0   ;
Htail.zShiftWing =  20   ;
Htail.symWing    =   1   ;

% parameters with characters
Htail.orientation           = 'xz'            ;
Htail.wingAfoil.airfoilName = '0012'          ;
Htail.type                  = 'liftingSurface';


%% DEFINE THE VTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Vtail.AR         =   3.05;
Vtail.area       = 100   ; 
Vtail.taper      =   0.28;
Vtail.sweep      =  7    ; 
Vtail.dihedral   =   0   ;
Vtail.xShiftWing =  85   ;
Vtail.yShiftWing =   0   ;
Vtail.zShiftWing =  4   ;
Vtail.symWing    =   0   ;

% parameters with characters
Vtail.orientation           = 'xy'            ;
Vtail.wingAfoil.airfoilName = '0008'          ;
Vtail.type                  = 'liftingSurface';


%% DEFINE THE FUSELAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Fuselage.Length = 89.2;

% parameters with characters
Fuselage.type  = 'bluntBody';
Fuselage.Style = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "ATR72Fuselage.dat");


%% DEFINE THE ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Engine.Length            = 9  ;
Engine.EngineInletRadii  =  6.5  ;
Engine.EngineOutletRadii =  6;

% parameters with characters
Engine.type     = 'Engine';
Engine.Filename = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "ATR72_Engines.dat");


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