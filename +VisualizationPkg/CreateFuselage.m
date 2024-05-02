function [Component] = CreateFuselage(Component)
%
% [Component] = CreateFuselage(Component)
% written by Nawa Khailany
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 mar 2024
%
% Create a fuselage component, which consists of multiple superellipses.
%
% INPUTS:
%     Component - fuselage component to be created.
%                 size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Component - fuselage component with the computed coordinates.
%                 size/type/units: 1-by-1 / struct / []
%


%% SETUP %%
%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get fuselage parameters    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% input fuselage length
TotLen = Component.Length;

% filename to get the fuselage cross-sections
FileName = Component.Style; 

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% process the file to get    %
% the fuselage's length      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% open the specified file (can have the string being Style)
FuseFile = fopen(FileName); 

% check if the file exists
if (FuseFile == -1)
    error('Failed to open fuselage file');
end

% get the x-coordinates of the pressure bulkheads
x1 = fscanf(FuseFile, 'x1=%f\n', 1);
x2 = fscanf(FuseFile, 'x2=%f\n', 1);

% get the initial configuration's fuselage length
NomLength = fscanf(FuseFile, 'TLength=%f\n',1);

% get the notional length between the pressure bulkheads
L0 = x2 - x1;

% compute the minimum length (i.e., no cabin, just nose/tail)
MinLength = NomLength - L0;

% check if the minimum length is breached
if (TotLen < MinLength)
    error('Length input for the fuselage is not large enough');
end

% calculate length difference between notional length and input length
DelLength = TotLen - NomLength;

% calculate the length between the pressure bulkheads
L = TotLen - NomLength + L0;

% find the scale factor (to stretch the fuselage in x)
SF = L / L0;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% process the fuselage       %
% cross-sections             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% find the number of fuselage superellipses specified in header file
SuperEllipseNum = fscanf(FuseFile, 'SuperEllipseNum=%d\n\n', 1);

%extract data out
for i = 1:SuperEllipseNum

    % name this superellipse
    SupellName = sprintf("supell_%d", i);
    
    % create a structure for the superellipse
    SuperEllipse.(SupellName) = struct();

    % extract radii
    SuperEllipse.(SupellName).r_n = fscanf(FuseFile, '%*s\n%f', 1);
    SuperEllipse.(SupellName).r_w = fscanf(FuseFile, '%f', 1);
    SuperEllipse.(SupellName).r_s = fscanf(FuseFile, '%f', 1);
    SuperEllipse.(SupellName).r_e = fscanf(FuseFile, '%f', 1);

    % extract powers
    SuperEllipse.(SupellName).n_ne = fscanf(FuseFile, '%f', 1);
    SuperEllipse.(SupellName).n_nw = fscanf(FuseFile, '%f', 1);
    SuperEllipse.(SupellName).n_sw = fscanf(FuseFile, '%f', 1);
    SuperEllipse.(SupellName).n_se = fscanf(FuseFile, '%f', 1);

    % extract position
    SuperEllipse.(SupellName).x = fscanf(FuseFile, '%f', 1);
    SuperEllipse.(SupellName).y = fscanf(FuseFile, '%f', 1);
    SuperEllipse.(SupellName).z = fscanf(FuseFile, '%f', 1);

    % check if it belongs in the front view
    SuperEllipse.(SupellName).Fview = fscanf(FuseFile, '%s', 1);

end

% close the fuselage cross-section specification file
fclose(FuseFile);


%% SUPERELLIPSE CREATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the superellipse fieldnames
SuperEllipseName = fieldnames(SuperEllipse);

% Create the location information of the Superellipses and scale them 
% according to the inputs of length:
% Start by finding the ellipses in section (I), (II), and (III). Then scale
% the ellipses in section (II) by first moving them to the origin and then
% applying the scale factor. After that move (II) back to where it was 
% For section (III) just need to translate it by the difference in length

% loop through superellipses and scale the appropriate cross-sections
for i = 1:SuperEllipseNum

    % check if the cross-section is in-between sections I and II
    if ((SuperEllipse.(SuperEllipseName{i}).x >  x1) && ...
        (SuperEllipse.(SuperEllipseName{i}).x <= x2) )
    
        % translate to the origin
        SuperEllipse.(SuperEllipseName{i}).x = SuperEllipse.(SuperEllipseName{i}).x - x1;
        
        % scale the fuselage
        SuperEllipse.(SuperEllipseName{i}).x = SuperEllipse.(SuperEllipseName{i}).x * SF;
        
        % translate to its new position
        SuperEllipse.(SuperEllipseName{i}).x = SuperEllipse.(SuperEllipseName{i}).x + x1;

    elseif (SuperEllipse.(SuperEllipseName{i}).x > x2)
        
        % translate section III cross-sections
        SuperEllipse.(SuperEllipseName{i}).x = SuperEllipse.(SuperEllipseName{i}).x + DelLength;

    end
end

% create the superellipses
for i = 1:SuperEllipseNum
    SuperEllipse.(SuperEllipseName{i}) = VisualizationPkg.SuperEllipse(SuperEllipse.(SuperEllipseName{i}));
end


%% CREATE THE TOP VIEW %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% allocate space for the top view coordinates
TopViewX = zeros(2 * SuperEllipseNum, 1);
TopViewY = zeros(2 * SuperEllipseNum, 1);

% TopView points are extracted in a clockwise order starting from the first
% superellipse and moving along the eastern most point + y-shift
% until it reaches the last superellipse. Once it reaches this last one it
% will now go to the western most point of the last superellipse and connect
% the rest of the points from this last superellipse to the intial
% superellipse

% loop through the superellipses
for i = 1:(2 * SuperEllipseNum)

    % check which cross-section we're at
    if (i <= SuperEllipseNum)
        
        % currently moving from nose to tail (rite surface)
        TopViewX(i) = SuperEllipse.(SuperEllipseName{i}).x  ;
        TopViewY(i) = SuperEllipse.(SuperEllipseName{i}).y  + ...
                      SuperEllipse.(SuperEllipseName{i}).r_w;
        
    elseif i == SuperEllipseNum + 1
        
        % the tail cross-section has been passed (turn back to the nose)
        TopViewX(i) = SuperEllipse.(SuperEllipseName{SuperEllipseNum}).x  ;
        TopViewY(i) = SuperEllipse.(SuperEllipseName{SuperEllipseNum}).y  - ...
                      SuperEllipse.(SuperEllipseName{SuperEllipseNum}).r_e;
        
    else
        
        % traverse from the tail to the nose
        TopViewX(i) = SuperEllipse.(SuperEllipseName{i - 2 * (i - SuperEllipseNum) + 1}).x  ;
        TopViewY(i) = SuperEllipse.(SuperEllipseName{i - 2 * (i - SuperEllipseNum) + 1}).y  - ...
                      SuperEllipse.(SuperEllipseName{i - 2 * (i - SuperEllipseNum) + 1}).r_e; 
        
    end
end

% arrange the points such that the loop is closed
TopView = [TopViewX, TopViewY; TopViewX(1), TopViewY(1)];


%% CREATE THE SIDE VIEW %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% allocate memory for the side view
SideViewX = zeros(2 * SuperEllipseNum - 1, 1);
SideViewZ = zeros(2 * SuperEllipseNum - 1, 1);

% SideView points are created in a similar manner to TopView points. It once
% again starts by extracting the first superellipse x and z coordinates,
% goes all the way to the last superellispe, and then back around to the
% first superellipse. It first starts by extracting the northern radii + the
% z shift, then on its way back around it will use the southern radii of the
% superellipses

% loop through the superellipses
for i = 1:(2 * SuperEllipseNum - 1)

    % check which cross-section we're at
    if (i <= SuperEllipseNum)
        
        % traversing from nose to tail (upper surface)
        SideViewX(i) = SuperEllipse.(SuperEllipseName{i}).x  ;
        SideViewZ(i) = SuperEllipse.(SuperEllipseName{i}).z  + ...
                       SuperEllipse.(SuperEllipseName{i}).r_n;
        
    else 
        
        % traversing from tail to nose (lower surface)
        SideViewX(i) = SuperEllipse.(SuperEllipseName{i - 2 * (i - SuperEllipseNum)}).x  ;
        SideViewZ(i) = SuperEllipse.(SuperEllipseName{i - 2 * (i - SuperEllipseNum)}).z  - ...
                       SuperEllipse.(SuperEllipseName{i - 2 * (i - SuperEllipseNum)}).r_s; 
        
    end
end

% arrange the points such that the loop is closed
SideView = [SideViewX, SideViewZ; SideViewX(1), SideViewZ(1)];


%% CREATE THE FRONT VIEW %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loop through all superellipses
for i = 1:SuperEllipseNum

    % check if the superellipse cross-section is in the front view
    if strcmp(SuperEllipse.(SuperEllipseName{i}).Fview, "FVIEW")
        
        % add the supelleipse component to the structure
        FrontView.(SuperEllipseName{i}) = SuperEllipse.(SuperEllipseName{i});
        
    end
end


%% FILL THE COMPONENT %%
%%%%%%%%%%%%%%%%%%%%%%%%

% place the three-views in the component
Component.FrontView = FrontView;
Component.SideView  =  SideView;
Component.TopView   =   TopView;

% place the isometric views in the component
Component.IsometricView.SuperEllipse = SuperEllipse;

end