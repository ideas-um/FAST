function [Aircraft] = SimpleGeometry()
%
% [Aircraft] = SimpleGeometry()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 mar 2024
%
% Create a simple wing/htail/vtail geometry to test the
% visualization code. Warning: this example is old and is not realistic for
% an actual aircraft geometry. It is just a test.
%
% INPUTS:
%     none
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
Wing.taper      =    0.36;
Wing.sweep      =   35   ;
Wing.xShiftWing =   54   ;
Wing.yShiftWing =    0   ;
Wing.zShiftWing =  -10   ;
Wing.dihedral   =    7   ;
Wing.symWing    =    1   ;

% parameters with characters
Wing.orientation           = 'xz'  ;
Wing.wingAfoil.airfoilName = '8410';
Wing.type       = 'liftingSurface';


%% DEFINE THE HTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
HTail.AR         =   2.15;
HTail.area       = 637   ;
HTail.taper      =   0.33;
HTail.sweep      =  40   ;
HTail.xShiftWing = 147   ;
HTail.yShiftWing =   0   ;
HTail.zShiftWing =  13   ;
HTail.dihedral   =  12   ;
HTail.symWing    =   1   ;

% parameters with characters
HTail.orientation           = 'xz'  ;
HTail.wingAfoil.airfoilName = '0008';
HTail.type        = 'liftingSurface';

%% DEFINE THE VTAIL %%
%%%%%%%%%%%%%%%%%%%%%%

% parameters with numerical values
VTail.AR         =   1.80;
VTail.area       = 473   ;
VTail.taper      =   0.28;
VTail.sweep      =  45   ;
VTail.xShiftWing = 152   ;
VTail.yShiftWing =   0   ;
VTail.zShiftWing =   9   ;
VTail.dihedral   =   0   ;
VTail.symWing    =   0   ;

% parameters with characters
VTail.orientation           = 'xy'  ;
VTail.wingAfoil.airfoilName = '0008';
VTail.type = 'liftingSurface';



%% DEFINE THE FUSELAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

%parameters with numerical values
Fuselage.Length = 182.75;

%parameters with characters
Fuselage.type = 'bluntBody';
Fuselage.Style = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", "LM100J.dat");


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
Aircraft.Geometry.HTail = HTail;

% remember the vtail
Aircraft.Geometry.VTail = VTail;

%remember the fuselage
Aircraft.Geometry.Fuselage = Fuselage;

% ----------------------------------------------------------

end