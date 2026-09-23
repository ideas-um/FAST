function [Component] = CreateWing(Component)
%
% [Component] = CreateWing(Component)
% written by Nawa Khailany
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 mar 2024
%
% Define all of the points and views needed to visualize a wing.
%
% INPUTS:
%     Component - wing component with its design parameters.
%                 size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Component - updated component with the 3D coordinates and views.
%                 size/type/units: 1-by-1 / struct / []
%


%% PROCESS INPUTS %%
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get the wing's parameters  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% extract parameters from the component
area        = Component.area;
qSweep      = Component.sweep;
taper       = Component.taper;
AR          = Component.AR;
dihedral    = Component.dihedral;
xShiftWing  = Component.xShiftWing;
yShiftWing  = Component.yShiftWing;
zShiftWing  = Component.zShiftWing;
orientation = Component.orientation;
symWing     = Component.symWing;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check for valid inputs     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check the wing area
if (~isnumeric(area))
    error('The wing area must be a number, not %s',class(area));
end

if (area <= 0)
    error('The wing area must be positive and greater than 0');
end

% check the taper ratio
if (~isnumeric(taper))
    error('The taper must be a number, not %s',class(taper));
end

if (taper < 0)
    error('Taper must be non negative');
end

% check the quarter-chord sweep
if (~isnumeric(qSweep))
    error('Sweep must be a number, not %s',class(qSweep));
end

if (abs(qSweep) > 90)
    error('Sweep must be between -90 and 90 degrees');
end

% check the aspect ratio
if (~isnumeric(AR))
    error('The Aspect ratio must be a number, not %s',class(AR));
end

if (AR <= 0)
    error('Aspect ratio must be positive and greater than 0');
end

% check the dihedral
if (~isnumeric(dihedral))
    error('Dihedral must be a number, not %s',class(dihedral));
end

if (abs(dihedral) > 90)
    error('Dihedral angle must be between -90 and 90 degrees');
end

% check the leading edge position of the root
if (~isnumeric(xShiftWing))
    error('The wing translation in the x direction must be a number, not %s',class(xShiftWing));
end

if (~isnumeric(yShiftWing))
    error('The wing translation in the y direction must be a number, not %s',class(yShiftWing));
end

if (~isnumeric(zShiftWing))
    error('The wing translation in the z direction must be a number, not %s',class(zShiftWing));
end

% check the wing's orientation
if (~ischar(orientation))
    error('The orientation must be a string of either xy, xz, or yz, not a %s',class(orientation));
end

if ((~strcmpi(orientation,'xy')) && (~strcmpi(orientation,'xz')) && (~strcmpi(orientation,'yz')))
    error('The orientation must be a string of either xy, xz, or yz');
end

% check the symmetric wing flag
if (~isnumeric(symWing))
    error('The wing symmetry boolean must be specified as either a 1 for a symmetric wing or 0 for an asymmetric wing, not %s',class(xShiftWing));
end

if ((symWing ~= 1) && (symWing ~= 0))
    error('The wing symmetry boolean must be specified as either a 1 for a symmetric wing or 0 for an asymmetric wing');
end


%% CREATE THE AIRFOIL %%
%%%%%%%%%%%%%%%%%%%%%%%%

% make the airfoil
Component.wingAfoil = VisualizationPkg.CreateAirfoil(Component.wingAfoil);

% extract airfoil outputs
xUnit = Component.wingAfoil.xUnit;
yUnit = Component.wingAfoil.yUnit;
iMax  = Component.wingAfoil.iMax;
iMin  = Component.wingAfoil.iMin;


%% CREATE THE WING %%
%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% compute geometric          %
% parameters for a           %
% trapezoidal wing           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the wingspan
span = sqrt(AR * area);

% compute the root chord
cRoot = (2 * area) / (span * (1 + taper));

% compute the tip chord
cTip = cRoot * taper;

% compute the leading-edge sweep angle
lSweep = atand(tand(qSweep) + ((1 - taper) / (1 + taper)) / AR);

% compute the position of the tip's leading edge
xShiftTip = span / 2 * tand(lSweep  );
zShiftTip = span / 2 * tand(dihedral);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get the 3D points of the   %
% root and tip airfoils      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of points in the airfoil
npnt = length(xUnit);

% scale the root chord (default in the xz-plane)
xRoot = cRoot .* xUnit;
zRoot = cRoot .* yUnit;

% the root chord remains in the xz-plane
yRoot = zeros(npnt, 1); 

% check if the wing is symmetric
if (symWing == 1)
    
    % compute the rite wingtip position (relative to the root)
    xTip1 = cTip .* xUnit + xShiftTip + cRoot / 2;
    zTip1 = cTip .* yUnit + zShiftTip;

    % offset from the xz-plane
    yTip1 = repmat(+span / 2, npnt, 1);
    
    % compute the left wingtip position (relative to the root)
    xTip2 = (cTip.*xUnit) + xShiftTip + cRoot / 2;
    zTip2 = (cTip.*yUnit) + zShiftTip;
    
    % offset from the xz-plane
    yTip2 = repmat(-span / 2, npnt, 1);

else
    
    % compute the rite wingtip position (relative to the root)
    xTip1 = cTip .* xUnit + xShiftTip + cRoot / 2;
    zTip1 = cTip .* yUnit + zShiftTip;
    
    % offset from the xz-plane
    yTip1 = repmat(+span, npnt, 1);

    % the left wingtip doesn't exist (positioned 0 relative to the root)
    xTip2 = zeros(npnt, 1);
    yTip2 = zeros(npnt, 1);
    zTip2 = zeros(npnt, 1);
    
end


%% GENERATE THE VIEWS %%
%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of points on only the upper/lower surface
npnt = npnt / 2;

% check the orientation (xy --> vertical tail-like, xz --> wing-like)
if     (strcmpi(orientation, "XY") == 1)
    
    % translate the root airfoil
    xRoot = xRoot + xShiftWing - cRoot/2;
    zRoot = zRoot + yShiftWing;
    yRoot = yRoot + zShiftWing;
    
    % translate the rite wingtip
    xTip1 = xTip1 + xShiftWing - cRoot/2 - cTip/2;
    zTip1 = zTip1 + yShiftWing;
    yTip1 = yTip1 + zShiftWing;
    
    % translate the left wingtip
    xTip2 = xTip2 + xShiftWing - cRoot/2 - cTip/2;
    zTip2 = zTip2 + yShiftWing;
    yTip2 = yTip2 + zShiftWing;
    
    % remember the individual airfoil coordinates at each station
    root = [xRoot, zRoot, yRoot];
    tip1 = [xTip1, zTip1, yTip1];
    tip2 = [xTip2, zTip2, yTip2];
    
    % store the points from +y to -y
    xyz = [tip1; root; tip2];
    
    % get the top view (will see whole airfoil top-down)
    topView = xyz;
    
    % get the side view (planform view)
    sideView = [xyz(           1, :); xyz(    npnt    , :); ...
                xyz(3 * npnt    , :); xyz(5 * npnt    , :); ...
                xyz(4 * npnt + 1, :); xyz(2 * npnt + 1, :); ...
                xyz(           1, :)                      ] ;
     
    % get the front view (see dihedral)
    frontView = [xyz(           iMax, :); xyz(2 * npnt + iMax, :); ...
                 xyz(4 * npnt + iMax, :); xyz(4 * npnt + iMin, :); ...
                 xyz(2 * npnt + iMin, :); xyz(           iMin, :); ...
                 xyz(              1, :); xyz(2 * npnt +    1, :); ...
                 xyz(4 * npnt +    1, :); xyz(2 * npnt +    1, :); ...
                 xyz(              1, :); xyz(           iMax, :)] ;
    
elseif (strcmpi(orientation, "XZ") == 1)
    
    % translate the root airfoil
    xRoot = xRoot + xShiftWing - cRoot/2;
    yRoot = yRoot + yShiftWing;
    zRoot = zRoot + zShiftWing;
    
    % translate the rite wingtip
    xTip1 = xTip1 + xShiftWing - cRoot/2 - cTip/2;
    yTip1 = yTip1 + yShiftWing;
    zTip1 = zTip1 + zShiftWing;
    
    % translate the left wingtip
    xTip2 = xTip2 + xShiftWing - cRoot/2 - cTip/2;
    yTip2 = yTip2 + yShiftWing;
    zTip2 = zTip2 + zShiftWing;
    
    % remember the individual airfoil coordinates at each station
    root = [xRoot,yRoot,zRoot];
    tip1 = [xTip1,yTip1,zTip1];
    tip2 = [xTip2,yTip2,zTip2];
    
    % store the points from +y to -y
    xyz = [tip1; root; tip2];
    
    % get the top view (planform view)
    topView = [xyz(           1, :); xyz(    npnt    , :); ...
               xyz(3 * npnt    , :); xyz(5 * npnt    , :); ...
               xyz(4 * npnt + 1, :); xyz(2 * npnt + 1, :); ...
               xyz(           1, :)                      ] ;
    
    % get the side view (airfoil view)
    sideView = xyz;
    
    % get the front view (to see dihedral)
    frontView = [xyz(           iMax, :); xyz(2 * npnt + iMax, :); ...
                 xyz(4 * npnt + iMax, :); xyz(4 * npnt + iMin, :); ...
                 xyz(2 * npnt + iMin, :); xyz(           iMin, :); ...
                 xyz(              1, :); xyz(2 * npnt +    1, :); ...
                 xyz(4 * npnt +    1, :); xyz(2 * npnt +    1, :); ...
                 xyz(              1, :); xyz(           iMax, :)] ;
    
else
    
    % translate the rite wingtip
    yTip1 = yTip1 + xShiftWing - cRoot/2;
    xTip1 = xTip1 + yShiftWing;
    zTip1 = zTip1 + zShiftWing;
    
    % translate the root airfoil
    yRoot = yRoot + xShiftWing - cRoot/2;
    xRoot = xRoot + yShiftWing;
    zRoot = zRoot + zShiftWing;    
    
    % translate the left wingtip
    yTip2 = yTip2 + xShiftWing - cRoot/2;
    xTip2 = xTip2 + yShiftWing;
    zTip2 = zTip2 + zShiftWing;
    
    % remember the individual airfoil coordinates at each station
    root = [yRoot,xRoot,zRoot];
    tip1 = [yTip1,xTip1,zTip1];
    tip2 = [yTip2,xTip2,zTip2];
    
    % store the points from +y to -y
    xyz = [tip1; root; tip2];

    % get the top view (planform view)
    topView = [xyz(           1, :); xyz(    npnt    , :); ...
               xyz(3 * npnt    , :); xyz(5 * npnt    , :); ...
               xyz(4 * npnt + 1, :); xyz(2 * npnt + 1, :); ...
               xyz(           1, :)                      ] ;
           
    % get the side view (to see dihedral)
    sideView = [xyz(           iMax, :); xyz(2 * npnt + iMax, :); ...
                xyz(4 * npnt + iMax, :); xyz(4 * npnt + iMin, :); ...
                xyz(2 * npnt + iMin, :); xyz(           iMin, :); ...
                xyz(              1, :); xyz(2 * npnt +    1, :); ...
                xyz(4 * npnt +    1, :); xyz(2 * npnt +    1, :); ...
                xyz(              1, :); xyz(           iMax, :)] ;
            
    % get the front view (airfoil view)
    frontView = xyz;

end

% get the isometric view (all points)
isoView = xyz;


%% FILL THE COMPONENT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% return the geometric parameters
Component.span      = span     ;
Component.cRoot     = cRoot    ;
Component.cTip      = cTip     ;
Component.xShiftTip = xShiftTip;
Component.xyz       = xyz      ;

% return the views
Component.topView   = topView  ;
Component.sideView  = sideView ;
Component.frontView = frontView;
Component.isoView   = isoView  ;

% return the individual airfoil coordinates
Component.tip1 = tip1;
Component.root = root;
Component.tip2 = tip2;

% ----------------------------------------------------------

end