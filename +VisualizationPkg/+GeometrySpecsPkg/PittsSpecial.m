function [Aircraft] = PittsSpecial(Aircraft)
%
% [Aircraft] = PittsSpecial(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 08 apr 2024
%
% Define the geometric parameters for a small turboprop based on the
% Pitts Special aerobatic aircraft.
%
% INPUTS:
%     Aircraft - aircraft structure with no  geometry components
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft structure with the geometry components
%                size/type/units: 1-by-1 / struct / []
%


%% DEFINE THE UPPER WING %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% list geometric parameters  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
UpperWing.AR         =  4.3;
UpperWing.area       = 31.3;
UpperWing.taper      =  1.0;
UpperWing.sweep      =  0.0;
UpperWing.dihedral   =  0.0;
UpperWing.xShiftWing =  3.0;
UpperWing.yShiftWing =  0.0;
UpperWing.zShiftWing =  2.5;
UpperWing.symWing    =  1  ;

% parameters with characters
UpperWing.orientation           = 'xz'            ;
UpperWing.wingAfoil.airfoilName = '0012'          ;
UpperWing.type                  = 'liftingSurface';


%% DEFINE THE LOWER WING %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% list geometric parameters  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
LowerWing.AR         =  4.3;
LowerWing.area       = 31.3;
LowerWing.taper      =  1.0;
LowerWing.sweep      =  0.0;
LowerWing.dihedral   =  2.0;
LowerWing.xShiftWing =  4.5;
LowerWing.yShiftWing = -0.2;
LowerWing.zShiftWing =  2.5;
LowerWing.symWing    =  1  ;

% parameters with characters
LowerWing.orientation           = 'xz'            ;
LowerWing.wingAfoil.airfoilName = '0012'          ;
LowerWing.type                  = 'liftingSurface';


%% DEFINE THE HTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Htail.AR         =  4.3;
Htail.area       =  7.8;
Htail.taper      =  0.3;
Htail.sweep      = 65.0;
Htail.dihedral   =  0.0;
Htail.xShiftWing =  8.0;
Htail.yShiftWing =  0.0;
Htail.zShiftWing =  1.0;
Htail.symWing    =  1  ;

% parameters with characters
Htail.orientation           = 'xz'            ;
Htail.wingAfoil.airfoilName = '0008'          ;
Htail.type                  = 'liftingSurface';


%% DEFINE THE VTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Vtail.AR         =  1.3;
Vtail.area       =  4.2;
Vtail.taper      =  0.1;
Vtail.sweep      = 20.0; %was 15
Vtail.dihedral   =  0.0;
Vtail.xShiftWing =  9.3;
Vtail.yShiftWing =  0.0;
Vtail.zShiftWing =  9.3;
Vtail.symWing    =  0  ;

% parameters with characters
Vtail.orientation           = 'xy'            ;
Vtail.wingAfoil.airfoilName = '0008'          ;
Vtail.type                  = 'liftingSurface';


%% DEFINE THE FUSELAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Fuselage.Length = 11;

% parameters with characters
Fuselage.type  = 'bluntBody';
Fuselage.Style = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "PittsSpecialFuselage.dat");


%% DEFINE THE ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Engine.Length            = 0.5;
Engine.EngineInletRadii  = 3.0;
Engine.EngineOutletRadii = 0.1;

% parameters with characters
Engine.type     = 'Engine';
Engine.Filename = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "PittsSpecialEngines.dat");


%% REMEMBER THE GEOMETRY PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% save as one structure      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the wings
Aircraft.Geometry.LowerWing = LowerWing;
Aircraft.Geometry.UpperWing = UpperWing;

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