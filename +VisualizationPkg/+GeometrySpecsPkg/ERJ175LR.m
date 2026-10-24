function [Aircraft] = ERJ175LR(Aircraft)
%
% [Aircraft] = ERJ175LR(Aircraft)
%
% Define an Embraer 175 LR geometry with the enhanced wingtip. Dimensions
% come from Embraer 175 Airport Planning Manual APM 2259, Section 02,
% Revision 22 (29 Nov 2024). Engine dimensions come from GE's CF34-8E
% propulsion-system data sheet. Locations not dimensioned by those public
% sources are estimated from the manual's three-view drawing.
%


%% WING %%
%%%%%%%%%%

% The enhanced wingtip increases the reference area and span relative to
% the original 26 m winglet configuration.
Wing.AR         = 10.2825;
Wing.area       = 859.369;
Wing.taper      = 0.2441;
Wing.sweep      = 26.44;
Wing.dihedral   = 5.0;
Wing.xShiftWing = 49.0;
Wing.yShiftWing = 0;
Wing.zShiftWing = -1.8;
Wing.symWing    = 1;

Wing.orientation           = 'xz';
Wing.wingAfoil.airfoilName = '2412';
Wing.type                  = 'liftingSurface';


%% HORIZONTAL TAIL %%
%%%%%%%%%%%%%%%%%%%%%

% Embraer specifies a 10.00 m span and 23.25 m^2 reference area.
Htail.AR         = 4.3011;
Htail.area       = 250.260;
Htail.taper      = 0.35;
Htail.sweep      = 32.0;
Htail.dihedral   = 6.0;
Htail.xShiftWing = 91.0;
Htail.yShiftWing = 0;
Htail.zShiftWing = 2.7;
Htail.symWing    = 1;

Htail.orientation           = 'xz';
Htail.wingAfoil.airfoilName = '0008';
Htail.type                  = 'liftingSurface';


%% VERTICAL TAIL %%
%%%%%%%%%%%%%%%%%%%

% Embraer specifies a 16.20 m^2 vertical-tail reference area.
Vtail.AR         = 1.90;
Vtail.area       = 174.375;
Vtail.taper      = 0.30;
Vtail.sweep      = 35.0;
Vtail.dihedral   = 0;
Vtail.xShiftWing = 88.5;
Vtail.yShiftWing = 0;
Vtail.zShiftWing = 3.8;
Vtail.symWing    = 0;

Vtail.orientation           = 'xy';
Vtail.wingAfoil.airfoilName = '0008';
Vtail.type                  = 'liftingSurface';


%% FUSELAGE %%
%%%%%%%%%%%%%%

% Overall length is 31.68 m. The cross-sections preserve the E-Jet's
% rounded cabin, tapered flight deck, and elevated aft tail cone.
Fuselage.Length = 103.937;
Fuselage.type = 'bluntBody';
Fuselage.Style = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", ...
    "ERJ175LRFuselage.dat");


%% ENGINES %%
%%%%%%%%%%%%

% The CF34-8E is 121 in long with a 46.2 in fan and 53 in maximum
% diameter. The visualization radii account for CreateEngine's vertical
% inlet shaping, keeping the displayed nacelle near the published size.
Engine.Length = 10.083;
Engine.EngineInletRadii = 1.50;
Engine.EngineOutletRadii = 1.05;
Engine.type = 'Engine';
Engine.Filename = fullfile("+VisualizationPkg", "+GeometrySpecsPkg", ...
    "ERJ175LREngines.dat");


%% ASSEMBLE GEOMETRY %%
%%%%%%%%%%%%%%%%%%%%%%%

Aircraft.Geometry.Wing = Wing;
Aircraft.Geometry.Htail = Htail;
Aircraft.Geometry.Vtail = Vtail;
Aircraft.Geometry.Fuselage = Fuselage;
Aircraft.Geometry.Engine = Engine;

end
