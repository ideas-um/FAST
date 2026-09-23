function [Airfoil] = CreateAirfoil(Airfoil)
%
% [Airfoil] = CreateAirfoil(Airfoil)
% written by Nawa Khailany
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 mar 2024
%
% Create a NACA 4-digit airfoil for a geometric component.
%
% INPUTS:
%     Airfoil - structure with the airfoil name.
%               size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Airfoil - updated structure with the coordinates of a unit airfoil
%               in the xy-plane.
%               size/type/units: 1-by-1 / struct / []
%


%% PROCESS INPUTS %%
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get the airfoil and check  %
% the string length          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the specified NACA airfoil (as a string)
afoil = Airfoil.airfoilName;

% get the number of digits specified in the string
ndigit = strlength(afoil);

% check that a 4-digit airfoil was specified
if (ndigit ~= 4)
    error('The airfoil name must follow the 4-digit NACA airfoil naming convention and should not have %d elements', ndigit);
end

% extract the parameters from the specified airfoil
m = str2double(afoil(1  )) / 100; % converting to percent
p = str2double(afoil(2  )) /  10; 
t = str2double(afoil(3:4)) / 100;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check if the airfoil       %
% information entered is     %
% valid                      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check the camber
if (isnan(m))
    error('The airfoil name must follow the 4-digit NACA airfoil naming convention, the first digit must be a number specifying the maximum camber');
end

% check the location of maximum camber
if (isnan(p))
    error('The airfoil name must follow the 4-digit NACA airfoil naming convention, the second digit must be a number specifying the location of maximum camber');
end

% check the thickness
if (isnan(t))
    error('The airfoil name must follow the 4-digit NACA airfoil naming convention, the third and fourth digits must be a number specifying the thickness of the airfoil');
end

% allow the thickness to be 0 for a "thin airfoil"
if (t == 0)
    warning('The airfoil thickness is set to 0, a thin airfoil will be generated for this component');
end

% the thickness can't be negative
if (t < 0)
    error('The airfoil name must follow the 4-digit NACA airfoil naming convention, invalid third and fourth digits, they must be a number');
end


%% CREATE THE AIRFOIL %%
%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% airfoil creation setup     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% number of points on the airfoil (might make it an input)
npnt = 50;

% divide by 2 to get the number of points on each surface
npnt = npnt / 2;

% points on the surface (leading edge to trailing edge, clockwise)
zeta = linspace(0, pi, npnt)';

% instead of a linear spacing, apply a cosine spacing
xc = 0.5 .* (1 - cos(zeta));

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% make the airfoil           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the airfoil's thickness
yt = 5 .* t .* ( (0.2969 .* sqrt(xc)     ) - ...
                 (0.1260 .*      xc      ) - (0.3516 .* (xc .^ 2)) + ...
                 (0.2843 .* (    xc .^ 3)) - (0.1036 .* (xc .^ 4)) );

% allocate memory for y-position and its derivative on the camber line 
 yc = zeros(npnt, 1);
dyc = zeros(npnt, 1);

% compute the y-position along the previously mentioned points
for ipnt = 1:npnt

    % check the position of x relative to the location of max. camber
    if (xc(ipnt) < p)
        
        % before the position of max. camber
         yc(ipnt) = (m / p ^ 2) * (2 * p * xc(ipnt) -      xc(ipnt) ^ 2);
        dyc(ipnt) = (m / p ^ 2) * (2 * p            -  2 * xc(ipnt)    );
        
    else
        
        % after  the position of max. camber
         yc(ipnt) = (m / ((1 - p) ^ 2)) * ...
                    ( (1 - 2 * p) + 2 * p * xc(ipnt) -     xc(ipnt) ^ 2);
        dyc(ipnt) = (m / ((1 - p) ^ 2)) * ...
                    (               2 * p            - 2 * xc(ipnt)    );
        
    end

end

% compute the slope of the derivative
theta = atan(dyc);

% compute the upper surface coordinates
xu = xc - yt .* sin(theta);
yu = yc + yt .* cos(theta);

% compute the lower surface coordinates
xl = xc + yt .* sin(theta);
yl = yc - yt .* cos(theta);

% flip the lower surface to connect it to the upper surface
xl = flip(xl);
yl = flip(yl);

% connect the upper and lower surfaces (clockwise)
x = [xu; xl];
y = [yu; yl];


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

% find the highest/lowest airfoil points (used for later computations)
[~, iMax] = max(y);
[~, iMin] = min(y);

% return the computed values into the structure
Airfoil.xUnit = x   ;
Airfoil.yUnit = y   ;
Airfoil.iMax  = iMax;
Airfoil.iMin  = iMin;

% ----------------------------------------------------------

end