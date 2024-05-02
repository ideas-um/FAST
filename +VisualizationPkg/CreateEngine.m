function [Component] = CreateEngine(Component, ScaleFactorGlobal)
%
% [Component] = CreateEngine(Component, ScaleFactorGlobal)
% written by Nawa Khailany, nawakhai@umich.edu
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 mar 2024
%
% Function to create an engine.
%
% INPUTS:
%     Component         - engine geometry component to be created.
%                         size/type/units: 1-by-1 / struct / []
%
%     ScaleFactorGlobal - a scale factor used to modify the engine's
%                         position in the configuration.
%                         size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     Component         - engine geometry component after its shape/size is
%                         determined.
%                         size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% extract parameters from    %
% the component              %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% total engine length
Length = Component.Length;

% inlet/outlet radii
EngineInletRadii  = Component.EngineInletRadii ;
EngineOutletRadii = Component.EngineOutletRadii;

% filename with super-ellipses dictating the engine's shape
filename = Component.Filename; 

% open the file
EngFile = fopen(filename);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check for valid inputs     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if file is empty
if EngFile == -1
    error('Failed to open Engine file');
end

%check for length inputs
if Length <= 0 
    error('Length input for the Engine must be over 0');
end

if EngineInletRadii <= 0
    error('Inlet Radii for the Engine must be over 0');
end

if EngineOutletRadii <= 0
    error('Outlet Radii for the Engine must be over 0');
end


%% FILE PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

% find the number of fuselage superellipses specified in header file
NumOfEngines = fscanf(EngFile, 'NumberOfEngines=%d\n\n', 1);

% counter to help identify the different sub structures for superellipses
CounterEng = 1;

% loop through all engines and extract information about them
for i = 1:NumOfEngines

    % convert the counter to a string for variable naming
    str = num2str(CounterEng);

    % initialize an empty structure
    SuperEllipse.(['engine_',str]) = struct();

    % extract x, y, z position of engines
    SuperEllipse.(['engine_',str]).x = fscanf(EngFile,'%*s\n%f',1);
    SuperEllipse.(['engine_',str]).y = fscanf(EngFile,'%f',1);
    SuperEllipse.(['engine_',str]).z = fscanf(EngFile,'%f',1);

    % extract the scale factors for the engine
    SuperEllipse.(['engine_',str]).SFLength = fscanf(EngFile,'%f',1);
    SuperEllipse.(['engine_',str]).SFRadii = fscanf(EngFile,'%f',1);

    %extract the type of the engine (turbofan or turboprop)
    SuperEllipse.(['engine_',str]).EngineType = fscanf(EngFile,'%s',1);

    % increment the counter
    CounterEng = CounterEng + 1;

end

% close the file
fclose(EngFile);


%% SUPERELLIPSE CREATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% grab fieldnames for the engine super-ellipses
EngineEllipseName = fieldnames(SuperEllipse);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get the engine's shape and %
% scale its size based on    %
% the user-specified scale   %
% factors                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loop through all engines
for i = 1:NumOfEngines

    % shorthands to access scale factors
    SFRadii  = SuperEllipse.(EngineEllipseName{i}).SFRadii ;
    SFLength = SuperEllipse.(EngineEllipseName{i}).SFLength;
    
    % shorthands to access the superellipse position
    Xposition = SuperEllipse.(EngineEllipseName{i}).x * ScaleFactorGlobal;
    Yposition = SuperEllipse.(EngineEllipseName{i}).y ;
    Zposition = SuperEllipse.(EngineEllipseName{i}).z ;

    % based on the type of engine, dynamically change its shape and size
    switch SuperEllipse.(EngineEllipseName{i}).EngineType
        
        % turbofan engine
        case 'TURBOFAN'

            % set the inlet  radii
            SuperEllipse.(EngineEllipseName{i}).Inlet.r_n  = 1.5 * SFRadii * EngineInletRadii ;
            SuperEllipse.(EngineEllipseName{i}).Inlet.r_w  = 1.0 * SFRadii * EngineInletRadii ;
            SuperEllipse.(EngineEllipseName{i}).Inlet.r_s  = 1.0 * SFRadii * EngineInletRadii ;
            SuperEllipse.(EngineEllipseName{i}).Inlet.r_e  = 1.0 * SFRadii * EngineInletRadii ;

            % set the outlet radii
            SuperEllipse.(EngineEllipseName{i}).Outlet.r_n = 1.5 * SFRadii * EngineOutletRadii;
            SuperEllipse.(EngineEllipseName{i}).Outlet.r_w = 1.0 * SFRadii * EngineOutletRadii;
            SuperEllipse.(EngineEllipseName{i}).Outlet.r_s = 1.0 * SFRadii * EngineOutletRadii;
            SuperEllipse.(EngineEllipseName{i}).Outlet.r_e = 1.0 * SFRadii * EngineOutletRadii;

            % set the super-ellipse powers on the inlet
            SuperEllipse.(EngineEllipseName{i}).Inlet.n_ne = 2.0;
            SuperEllipse.(EngineEllipseName{i}).Inlet.n_nw = 2.0;
            SuperEllipse.(EngineEllipseName{i}).Inlet.n_se = 2.5;
            SuperEllipse.(EngineEllipseName{i}).Inlet.n_sw = 2.5;

            % set the super-ellipse powers on the outlet
            SuperEllipse.(EngineEllipseName{i}).Outlet.n_ne = 2.0;
            SuperEllipse.(EngineEllipseName{i}).Outlet.n_nw = 2.0;
            SuperEllipse.(EngineEllipseName{i}).Outlet.n_se = 2.5;
            SuperEllipse.(EngineEllipseName{i}).Outlet.n_sw = 2.5;

            % set the inlet  position
            SuperEllipse.(EngineEllipseName{i}).Inlet.x = Xposition;
            SuperEllipse.(EngineEllipseName{i}).Inlet.y = Yposition;
            SuperEllipse.(EngineEllipseName{i}).Inlet.z = Zposition;

            % set the outlet position
            SuperEllipse.(EngineEllipseName{i}).Outlet.x = Xposition + (SFLength * Length);
            SuperEllipse.(EngineEllipseName{i}).Outlet.y = Yposition ;
            SuperEllipse.(EngineEllipseName{i}).Outlet.z = Zposition ;
            
        % turboprop engine
        case 'TURBOPROP'

            % set the inlet  radii
            SuperEllipse.(EngineEllipseName{i}).Inlet.r_n = 1 * SFRadii * EngineInletRadii;
            SuperEllipse.(EngineEllipseName{i}).Inlet.r_w = 1 * SFRadii * EngineInletRadii;
            SuperEllipse.(EngineEllipseName{i}).Inlet.r_s = 1 * SFRadii * EngineInletRadii;
            SuperEllipse.(EngineEllipseName{i}).Inlet.r_e = 1 * SFRadii * EngineInletRadii;

            % set the outlet radii
            SuperEllipse.(EngineEllipseName{i}).Outlet.r_n = 1 * SFRadii * EngineOutletRadii / 5;
            SuperEllipse.(EngineEllipseName{i}).Outlet.r_w = 1 * SFRadii * EngineOutletRadii / 5;
            SuperEllipse.(EngineEllipseName{i}).Outlet.r_s = 1 * SFRadii * EngineOutletRadii / 5;
            SuperEllipse.(EngineEllipseName{i}).Outlet.r_e = 1 * SFRadii * EngineOutletRadii / 5;

            % set the shaft  radii
            SuperEllipse.(EngineEllipseName{i}).Shaft.r_n = 1 * SFRadii * EngineOutletRadii / 5;
            SuperEllipse.(EngineEllipseName{i}).Shaft.r_w = 1 * SFRadii * EngineOutletRadii / 5;
            SuperEllipse.(EngineEllipseName{i}).Shaft.r_s = 1 * SFRadii * EngineOutletRadii / 5;
            SuperEllipse.(EngineEllipseName{i}).Shaft.r_e = 1 * SFRadii * EngineOutletRadii / 5;

            % set the inlet  super-ellipse powers
            SuperEllipse.(EngineEllipseName{i}).Inlet.n_ne = 2;
            SuperEllipse.(EngineEllipseName{i}).Inlet.n_nw = 2;
            SuperEllipse.(EngineEllipseName{i}).Inlet.n_se = 2;
            SuperEllipse.(EngineEllipseName{i}).Inlet.n_sw = 2;

            % set the outlet super-ellipse powers
            SuperEllipse.(EngineEllipseName{i}).Outlet.n_ne = 2;
            SuperEllipse.(EngineEllipseName{i}).Outlet.n_nw = 2;
            SuperEllipse.(EngineEllipseName{i}).Outlet.n_se = 2;
            SuperEllipse.(EngineEllipseName{i}).Outlet.n_sw = 2;

            % set the shaft  super-ellipse powers
            SuperEllipse.(EngineEllipseName{i}).Shaft.n_ne = 2;
            SuperEllipse.(EngineEllipseName{i}).Shaft.n_nw = 2;
            SuperEllipse.(EngineEllipseName{i}).Shaft.n_se = 2;
            SuperEllipse.(EngineEllipseName{i}).Shaft.n_sw = 2;

            % set the inlet  position
            SuperEllipse.(EngineEllipseName{i}).Inlet.x = Xposition;
            SuperEllipse.(EngineEllipseName{i}).Inlet.y = Yposition;
            SuperEllipse.(EngineEllipseName{i}).Inlet.z = Zposition;

            % set the outlet position
            SuperEllipse.(EngineEllipseName{i}).Outlet.x = Xposition + 0.5;
            SuperEllipse.(EngineEllipseName{i}).Outlet.y = Yposition ;
            SuperEllipse.(EngineEllipseName{i}).Outlet.z = Zposition ;

            % set the shaft  position
            SuperEllipse.(EngineEllipseName{i}).Shaft.x = Xposition + Length;
            SuperEllipse.(EngineEllipseName{i}).Shaft.y = Yposition ;
            SuperEllipse.(EngineEllipseName{i}).Shaft.z = Zposition ;

    end
end

% create the super-ellipses
for i = 1:NumOfEngines
    
    % create the super-ellipses needed based on the engine type
    switch SuperEllipse.(EngineEllipseName{i}).EngineType
        
        % turbofan
        case 'TURBOFAN'
            SuperEllipse.(EngineEllipseName{i}).Inlet  = VisualizationPkg.SuperEllipse(SuperEllipse.(EngineEllipseName{i}).Inlet );
            SuperEllipse.(EngineEllipseName{i}).Outlet = VisualizationPkg.SuperEllipse(SuperEllipse.(EngineEllipseName{i}).Outlet);
            
        % turboprop
        case 'TURBOPROP'
            SuperEllipse.(EngineEllipseName{i}).Inlet  = VisualizationPkg.SuperEllipse(SuperEllipse.(EngineEllipseName{i}).Inlet );
            SuperEllipse.(EngineEllipseName{i}).Outlet = VisualizationPkg.SuperEllipse(SuperEllipse.(EngineEllipseName{i}).Outlet);
            SuperEllipse.(EngineEllipseName{i}).Shaft  = VisualizationPkg.SuperEllipse(SuperEllipse.(EngineEllipseName{i}).Shaft );
    
    end
end


%% TOP VIEW %%
%%%%%%%%%%%%%%

%(issues: Not preallocating array sizes)

% TopView points are extracted in a clockwise order starting from the first
% superellipse and moving along the eastern most point + y-shift
% until it reaches the last superellipse. Once it reaches this last one it
% will now go to the western most point of the last superellipse and
% connect the rest of the points from this last superellipse to the intial
% superellipse

% initialize an empty array
TopView = [];

% loop through the engines
for i = 1:NumOfEngines
    
    % setup the views depending on the engine type
    switch SuperEllipse.(EngineEllipseName{i}).EngineType
        
        % turbofan engine
        case 'TURBOFAN'
            
            % rite side of the inlet
            topViewX(i, 1) =  SuperEllipse.(EngineEllipseName{i}).Inlet.x    ;
            topViewY(i, 1) =  SuperEllipse.(EngineEllipseName{i}).Inlet.r_e  + ...
                              SuperEllipse.(EngineEllipseName{i}).Inlet.y    ;
            
            % rite side of the outlet
            topViewX(i, 2) =  SuperEllipse.(EngineEllipseName{i}).Outlet.x   ;
            topViewY(i, 2) =  SuperEllipse.(EngineEllipseName{i}).Outlet.r_e + ...
                              SuperEllipse.(EngineEllipseName{i}).Outlet.y   ;
            
            % left side of the outlet
            topViewX(i, 3) =  SuperEllipse.(EngineEllipseName{i}).Outlet.x   ;
            topViewY(i, 3) = -SuperEllipse.(EngineEllipseName{i}).Outlet.r_w + ...
                              SuperEllipse.(EngineEllipseName{i}).Outlet.y   ;
            
            % left side of the inlet
            topViewX(i, 4) =  SuperEllipse.(EngineEllipseName{i}).Inlet.x    ;
            topViewY(i, 4) = -SuperEllipse.(EngineEllipseName{i}).Inlet.r_w  + ...
                              SuperEllipse.(EngineEllipseName{i}).Inlet.y    ;
            
            % connect to the initial point drawn here
            topViewX(i, 5) =  SuperEllipse.(EngineEllipseName{i}).Inlet.x    ;
            topViewY(i, 5) =  SuperEllipse.(EngineEllipseName{i}).Inlet.r_e  + ...
                              SuperEllipse.(EngineEllipseName{i}).Inlet.y    ;
                                
        % turboprop engine
        case 'TURBOPROP'
            
            % rite side of the inlet
            topViewX(i, 1) =  SuperEllipse.(EngineEllipseName{i}).Inlet.x    ;
            topViewY(i, 1) =  SuperEllipse.(EngineEllipseName{i}).Inlet.r_e  + ...
                              SuperEllipse.(EngineEllipseName{i}).Inlet.y    ;
            
            % rite side of the outlet
            topViewX(i, 2) =  SuperEllipse.(EngineEllipseName{i}).Outlet.x   ;
            topViewY(i, 2) =  SuperEllipse.(EngineEllipseName{i}).Outlet.r_e + ...
                              SuperEllipse.(EngineEllipseName{i}).Outlet.y   ;
            
            % rite side of the shaft
            topViewX(i, 3) =  SuperEllipse.(EngineEllipseName{i}).Shaft.x    ;
            topViewY(i, 3) =  SuperEllipse.(EngineEllipseName{i}).Shaft.r_e  + ...
                              SuperEllipse.(EngineEllipseName{i}).Shaft.y    ;
            
            % left side of the shaft
            topViewX(i, 4) =  SuperEllipse.(EngineEllipseName{i}).Shaft.x    ;
            topViewY(i, 4) = -SuperEllipse.(EngineEllipseName{i}).Shaft.r_w  + ...
                              SuperEllipse.(EngineEllipseName{i}).Shaft.y    ;
            
            % left side of the outlet
            topViewX(i, 5) =  SuperEllipse.(EngineEllipseName{i}).Outlet.x   ;
            topViewY(i, 5) = -SuperEllipse.(EngineEllipseName{i}).Outlet.r_w + ...
                              SuperEllipse.(EngineEllipseName{i}).Outlet.y   ;
            
            % left side of the inlet
            topViewX(i, 6) =  SuperEllipse.(EngineEllipseName{i}).Inlet.x    ;
            topViewY(i, 6) = -SuperEllipse.(EngineEllipseName{i}).Inlet.r_w  + ...
                              SuperEllipse.(EngineEllipseName{i}).Inlet.y    ;
            
            % connect to the initial point drawn here
            topViewX(i, 7) =  SuperEllipse.(EngineEllipseName{i}).Inlet.x    ;
            topViewY(i, 7) =  SuperEllipse.(EngineEllipseName{i}).Inlet.r_e  + ...
                              SuperEllipse.(EngineEllipseName{i}).Inlet.y    ;
            
    end
    
    % reshape the arrays to be column vectors
    topViewXAlter = topViewX(i,:);
    topViewXAlter = reshape(topViewXAlter,[],1);
    
    topViewYAlter = topViewY(i,:);
    topViewYAlter = reshape(topViewYAlter,[],1);
    
    % append engine visual (include NaN so separate engines don't connect)
    TopView = [TopView; NaN , NaN; topViewXAlter, topViewYAlter];
    
end


%% SIDE VIEW %%
%%%%%%%%%%%%%%%

%SideView points are created in a similar manner to TopView points. It once
%again starts by extracting the first superellipse x and z coordinates,
%goes all the way to the last superellispe, and then back around to the
%first superellipse. It first starts by extracting the northern radii + the
%z shift, then on its way back around it will use the southern radii of the
%superellipses

% initialize an empty array
SideView = [];

% loop through the engines
for i = 1:NumOfEngines

    % setup the views depending on the engine type
    switch SuperEllipse.(EngineEllipseName{i}).EngineType
        
        % turbofan engine
        case 'TURBOFAN'

            % coordinates for upper half of the inlet
            sideViewX(i, 1) =  SuperEllipse.(EngineEllipseName{i}).Inlet.x    ;
            sideViewZ(i, 1) =  SuperEllipse.(EngineEllipseName{i}).Inlet.r_n  + ...
                               SuperEllipse.(EngineEllipseName{i}).Inlet.z    ;
            
            % coordinates for upper half of the outlet
            sideViewX(i, 2) =  SuperEllipse.(EngineEllipseName{i}).Outlet.x   ;
            sideViewZ(i, 2) =  SuperEllipse.(EngineEllipseName{i}).Outlet.r_n + ...
                               SuperEllipse.(EngineEllipseName{i}).Outlet.z   ;
            
            % coordinates for lower half of the outlet
            sideViewX(i, 3) =  SuperEllipse.(EngineEllipseName{i}).Outlet.x   ;
            sideViewZ(i, 3) = -SuperEllipse.(EngineEllipseName{i}).Outlet.r_s + ...
                              SuperEllipse.(EngineEllipseName{i}).Outlet.z   ;
            
            % coordinates for lower half of the inlet
            sideViewX(i, 4) =  SuperEllipse.(EngineEllipseName{i}).Inlet.x    ;
            sideViewZ(i, 4) = -SuperEllipse.(EngineEllipseName{i}).Inlet.r_s  + ...
                               SuperEllipse.(EngineEllipseName{i}).Inlet.z    ;
            
            % connect to the initial point drawn here
            sideViewX(i, 5) =  SuperEllipse.(EngineEllipseName{i}).Inlet.x    ;
            sideViewZ(i, 5) =  SuperEllipse.(EngineEllipseName{i}).Inlet.r_n  + ...
                               SuperEllipse.(EngineEllipseName{i}).Inlet.z    ;

        % turboprop engine
        case 'TURBOPROP'

            % coordinates for the upper half of the propeller
            sideViewX(i, 1) =  SuperEllipse.(EngineEllipseName{i}).Inlet.x    ;
            sideViewZ(i, 1) =  SuperEllipse.(EngineEllipseName{i}).Inlet.r_n  + ...
                               SuperEllipse.(EngineEllipseName{i}).Inlet.z    ;
            
            % coordinates for the upper half of the left shaft
            sideViewX(i, 2) =  SuperEllipse.(EngineEllipseName{i}).Outlet.x   ;
            sideViewZ(i, 2) =  SuperEllipse.(EngineEllipseName{i}).Outlet.r_n + ...
                               SuperEllipse.(EngineEllipseName{i}).Outlet.z   ;
            
            % coordinates for the upper half of the rite shaft
            sideViewX(i, 3) =  SuperEllipse.(EngineEllipseName{i}).Shaft.x    ;
            sideViewZ(i, 3) =  SuperEllipse.(EngineEllipseName{i}).Shaft.r_n  + ...
                               SuperEllipse.(EngineEllipseName{i}).Shaft.z    ;
            
            % coordinates for the lower half of the rite shaft
            sideViewX(i, 4) =  SuperEllipse.(EngineEllipseName{i}).Shaft.x    ;
            sideViewZ(i, 4) = -SuperEllipse.(EngineEllipseName{i}).Shaft.r_s  + ...
                               SuperEllipse.(EngineEllipseName{i}).Shaft.z    ;
            
            % coordinates for the lower half of the left shaft
            sideViewX(i, 5) =  SuperEllipse.(EngineEllipseName{i}).Outlet.x   ;
            sideViewZ(i, 5) = -SuperEllipse.(EngineEllipseName{i}).Outlet.r_s + ...
                               SuperEllipse.(EngineEllipseName{i}).Outlet.z   ;
            
            % coordinates for the lower half of the propeller
            sideViewX(i, 6) =  SuperEllipse.(EngineEllipseName{i}).Inlet.x    ;
            sideViewZ(i, 6) = -SuperEllipse.(EngineEllipseName{i}).Inlet.r_s  + ...
                               SuperEllipse.(EngineEllipseName{i}).Inlet.z    ;
            
            % connect to the initial point drawn here
            sideViewX(i, 7) =  SuperEllipse.(EngineEllipseName{i}).Inlet.x    ;
            sideViewZ(i, 7) =  SuperEllipse.(EngineEllipseName{i}).Inlet.r_n  + ...
                               SuperEllipse.(EngineEllipseName{i}).Inlet.z    ;
            
    end

    % reshape the arrays to be column vectors
    sideViewXAlter = sideViewX(i,:);
    sideViewXAlter = reshape(sideViewXAlter,[],1);

    sideViewZAlter = sideViewZ(i,:);
    sideViewZAlter = reshape(sideViewZAlter,[],1);

    % append engine visual (include NaN so separate engines don't connect)
    SideView = [SideView; NaN, NaN; sideViewXAlter, sideViewZAlter];

end

%% FRONT VIEW %%
%%%%%%%%%%%%%%%%

% only show the inlets on the front view
for i = 1:NumOfEngines
    FrontView.(EngineEllipseName{i}) = SuperEllipse.(EngineEllipseName{i}).Inlet;
end


%% TRANSFER VIEWS OUT %%
%%%%%%%%%%%%%%%%%%%%%%%%

% return the three views
Component.FrontView = FrontView;
Component.SideView  = SideView;
Component.TopView   = TopView;

% return an isometric view
Component.IsometricView.SuperEllipse = SuperEllipse;

end