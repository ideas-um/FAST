function [Aircraft] = BWB(Aircraft)

%
% BWB.m
% written by Nawa Khailany, nawakhai@umich.edu
% last updated: 19 may 2024
%
% geometric parameters for a Blended Wing Body aircraft.
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

Wing.AR         = 11 ;
Wing.area       = 3000  ;
Wing.taper      =   0.3;
Wing.sweep      =   18  ; %was 1 degree
Wing.dihedral   =   0  ;
Wing.xShiftWing =   84 ;
Wing.yShiftWing =    0  ;
Wing.zShiftWing =   10  ;
Wing.symWing    =    1  ;

% parameters with characters
Wing.orientation           = 'xz'            ;
Wing.wingAfoil.airfoilName = '0012'          ;
Wing.type                  = 'liftingSurface';

%% DEFINE THE RIGHT WingTip %%

% parameters with numerical values
WingTipR.AR          = 2;
WingTipR.area        = 60;
WingTipR.taper       = 0.25  ;
WingTipR.sweep       = 40  ;
WingTipR.dihedral    =  8;
WingTipR.xShiftWing  = 118 ;
WingTipR.yShiftWing  = 90.5  ; 
WingTipR.zShiftWing  = 10  ;
WingTipR.symWing     = 0 ;

% parameters with characters
WingTipR.orientation           = 'xy'            ;
WingTipR.wingAfoil.airfoilName = '0004'          ;
WingTipR.type                  = 'liftingSurface';

%% DEFINE THE LEFT WingTip %%

% parameters with numerical values
WingTipL.AR          = 2;
WingTipL.area        = 60;
WingTipL.taper       = 0.25  ;
WingTipL.sweep       = 40  ;
WingTipL.dihedral    =  -8;
WingTipL.xShiftWing  = 118 ;
WingTipL.yShiftWing  = -90.5  ; 
WingTipL.zShiftWing  = 10  ;
WingTipL.symWing     = 0 ;

% parameters with characters
WingTipL.orientation           = 'xy'            ;
WingTipL.wingAfoil.airfoilName = '0004'          ;
WingTipL.type                  = 'liftingSurface';

%% DEFINE THE FUSELAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
Fuselage.Length = 130;

% parameters with characters
Fuselage.type  = 'bluntBody';
Fuselage.Style = fullfile("+VisualizationPkg","+GeometrySpecsPkg","BWBFuselage.dat");

%% REMEMBER THE GEOMETRY PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% save as one structure      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Aircraft.Geometry.Wing = Wing;

Aircraft.Geometry.WingTipR = WingTipR;

Aircraft.Geometry.WingTipL = WingTipL;

Aircraft.Geometry.Fuselage = Fuselage;

end