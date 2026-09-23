function [Aircraft] = Transport(Aircraft)
%
% [Aircraft] = Transport(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 mar 2024
%
% Define the geometric parameters for a transport-like aircraft.
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
Wing.AR         =    9   ;
Wing.area       = 4240   ;
Wing.taper      =    0.35;
Wing.sweep      =   26;
Wing.dihedral   =    7   ;
Wing.xShiftWing =   77.60;
Wing.yShiftWing =    0  ;
Wing.zShiftWing =  -10  ;
Wing.symWing    =    1  ;

% parameters with characters
Wing.orientation           = 'xz'            ;
Wing.wingAfoil.airfoilName = '2412'          ;
Wing.type                  = 'liftingSurface';


%% DEFINE THE HTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Htail.AR         =   2.15;
Htail.area       = 637.13;
Htail.taper      =   0.33;
Htail.sweep      =  31.17;
Htail.dihedral   =  12   ;
Htail.xShiftWing = 160.17;
Htail.yShiftWing =   0   ;
Htail.zShiftWing =   5   ;
Htail.symWing    =   1   ;

% parameters with characters
Htail.orientation           = 'xz'            ;
Htail.wingAfoil.airfoilName = '0008'          ;
Htail.type                  = 'liftingSurface';


%% DEFINE THE VTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Vtail.AR         =   1.80;
Vtail.area       = 473.30;
Vtail.taper      =   0.28;
Vtail.sweep      =  34.51;
Vtail.dihedral   =   0   ;
Vtail.xShiftWing = 155.07;
Vtail.yShiftWing =   0   ;
Vtail.zShiftWing =   9   ;
Vtail.symWing    =   0   ;

% parameters with characters
Vtail.orientation           = 'xy'            ;
Vtail.wingAfoil.airfoilName = '0008'          ;
Vtail.type                  = 'liftingSurface';


%% DEFINE THE FUSELAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Fuselage.Length = 182.73;

% parameters with characters
Fuselage.type  = 'bluntBody';
Fuselage.Style = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "TransportFuselage.dat");


%% DEFINE THE ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Engine.Length            = 30  ;
Engine.EngineInletRadii  =  4  ;
Engine.EngineOutletRadii =  3.5;

% parameters with characters
Engine.type     = 'Engine';
Engine.Filename = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "TransportEngines.dat");


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