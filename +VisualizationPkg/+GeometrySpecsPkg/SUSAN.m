function [Aircraft] = SUSAN(Aircraft)
%
% SUSAN.m
% written by Nawa Khailany, nawakhai@umich.edu
% last updated: 13 may 2024
%
% geometric parameters for a transport-like aircraft.
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
Wing.AR         =    9.44   ;
Wing.area       = 1470   ;
Wing.taper      =    0.28;
Wing.sweep      =   21   ;
Wing.dihedral   =    2   ;
Wing.xShiftWing =   100  ;
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
Htail.AR         =   3;
Htail.area       = 409;
Htail.taper      =   0.25;
Htail.sweep      =  28;
Htail.dihedral   =  0    ;
Htail.xShiftWing = 161   ;
Htail.yShiftWing =   0   ;
Htail.zShiftWing =   32  ;
Htail.symWing    =   1   ;

% parameters with characters
Htail.orientation           = 'xz'            ;
Htail.wingAfoil.airfoilName = '0008'          ;
Htail.type                  = 'liftingSurface';


%% DEFINE THE VTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Vtail.AR         =   1.80;
Vtail.area       = 280;
Vtail.taper      =   0.8;
Vtail.sweep      =  36;
Vtail.dihedral   =   0   ;
Vtail.xShiftWing = 150   ;
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
Fuselage.Length = 150;

% parameters with characters
Fuselage.type  = 'bluntBody';
Fuselage.Style = fullfile("+VisualizationPkg","+GeometrySpecsPkg","SUSANFuselage.dat");


%% DEFINE THE ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Engine.Length            = 8.5/2  ;
Engine.EngineInletRadii  =  6.25  ;
Engine.EngineOutletRadii =  5.75;

% parameters with characters
Engine.type     = 'Engine';
Engine.Filename = fullfile("+VisualizationPkg","+GeometrySpecsPkg","SUSANEngines.dat");

% %% DEFINE THE RIGHT CASING %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % parameters with numerical values 
% CasingR.Length = 200;
% 
% % parameters with characters 
% CasingR.type = 'bluntBody';
% CasingR.Style = fullfile("+VisualizationPkg","+GeometrySpecsPkg","SUSANCasingR.dat");
% 
% %% DEFINE THE LEFT CASING  %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% % parameters with numerical values 
% CasingL.Length = 200;
% 
% % parameters with characters 
% CasingL.type = 'bluntBody';
% CasingL.Style = fullfile("+VisualizationPkg","+GeometrySpecsPkg","SUSANCasingL.dat");
% 

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

% %remember the right casing
% Aircraft.Geometry.CasingR = CasingR;
% 
% %remember the left casing 
% Aircraft.Geometry.CasingL = CasingL;

% ----------------------------------------------------------

end