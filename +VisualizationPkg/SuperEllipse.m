function [Supell] = SuperEllipse(Supell)
%
% [Supell] = SuperEllipse(Supell)
% originally written by Nawa Khailany
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 mar 2024
%
% Generate the coordinates for a superellipse.
%
% INPUTS:
%     Supell - superellipse with parameters, but no coordinates.
%              size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Supell - superellipse with parameters and the coordinates.
%              size/type/units: 1-by-1 / struct / []
%


%% EXTRACT PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%

% get the radii
r_n = Supell.r_n;
r_e = Supell.r_e;
r_s = Supell.r_s;
r_w = Supell.r_w;

% get the powers
n_ne = Supell.n_ne;
n_nw = Supell.n_nw;
n_sw = Supell.n_sw;
n_se = Supell.n_se;

% get the initial cross-section coordinates
x = Supell.x;
y = Supell.y;
z = Supell.z;


%% GENERATE THE SUPERELLIPSE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the number of points in a superellipse quadrant
npnt = 50;

% get the total points in the superellipse
tpnt = 4 * npnt;

% define a running parameter around the superellipse
t = linspace(0, 2 * pi, tpnt);

% allocate memory for the arrays
xEllipse = repmat(x, tpnt, 1);
yEllipse = zeros(    tpnt, 1);
zEllipse = zeros(    tpnt, 1);

% compute the coordinates for each t
for i = 1:tpnt

    % check the quadrant that needs to be computed
    if     (i <=     tpnt / 4)
        
        % first quadrant
        yEllipse(i) = +r_e * cos(t(i)             ) ^ (2 / n_ne);
        zEllipse(i) = +r_n * sin(t(i)             ) ^ (2 / n_ne);

    elseif (i <=     tpnt / 2)
        
        % second quadrant
        yEllipse(i) = -r_w * sin(t(i) -     pi / 2) ^ (2 / n_nw);
        zEllipse(i) = +r_n * cos(t(i) -     pi / 2) ^ (2 / n_nw);

    elseif (i <= 3 * tpnt / 4)
        
        % third quadrant
        yEllipse(i) = -r_w * cos(t(i) -     pi    ) ^ (2 / n_sw);
        zEllipse(i) = -r_s * sin(t(i) -     pi    ) ^ (2 / n_sw);

    else
        
        % fourth quadrant
        yEllipse(i) = +r_e * sin(t(i) - 3 * pi / 2) ^ (2 / n_se);
        zEllipse(i) = -r_s * cos(t(i) - 3 * pi / 2) ^ (2 / n_se);

    end

end

% move the y and z coordinates based on the prescribed superellipse center
yEllipse = yEllipse + y;
zEllipse = zEllipse + z;

% combine the x, y, and z coordinates into an array
xyzInitial = [xEllipse, yEllipse, zEllipse];

% repeat the first point to create a closed loop
xyzInitial = [xyzInitial; xyzInitial(1,:)];


%% FILL THE SUPERELLIPSE STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% fill with the newly computed coordinates
Supell.xyzInitial = xyzInitial;

end