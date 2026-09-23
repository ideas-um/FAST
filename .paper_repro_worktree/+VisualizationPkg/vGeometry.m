function [Aircraft, PlotParts] = vGeometry(Aircraft)
%
% [Aircraft, PlotParts] = vGeometry(Aircraft)
% written by Nawa Khailany, nawakhai@umich.edu
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 mar 2024
%
% Create the geometry for a defined configuration and plot it.
%
% INPUTS:
%     Aircraft  - aircraft structure with a "geometry" sub-structure that
%                 defines the necessary geometric parameters to create a
%                 visualization.
%                 size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft  - aircraft structure with the created geometry components.
%                 size/type/units: 1-by-1 / struct / []
%
%     PlotParts - an array with the plot objects on the canvas.
%                 size/type/units: n-by-1 / line / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% check if the geometry structure exists in the aircraft structure
if ~isfield(Aircraft, 'Geometry')
    error('aircraft structure does not include geometry');
end

% check if the geometry structure is empty
if isempty(Aircraft.Geometry)
    error('geometry struct is empty');
end

% unzip the geometry structure
Geometry = Aircraft.Geometry;

% get the number of components and their names
ComponentName = fieldnames( Geometry);
ComponentNum  = length(ComponentName);


%% CHECK FOR VALID ARGUMENTS AND MAKE THE COMPONENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loop through each component
for i = 1:ComponentNum
    
    % shorthand to access the sub-structure
    component = Geometry.(ComponentName{i});

    % check that the component type is provided
    if ~isfield(component,'type') || isempty(component.type)
        error('Component type cannot be empty and needs to be filled out between either liftingSurface or bluntBody for the %s component',(ComponentName{i}));
    end

    % check that the component type exists
    if (~strcmp(component.type,'liftingSurface')) && (~strcmp(component.type,'bluntBody')) && (~strcmp(component.type,'Engine'))
        error('Component type needs to be specified between liftingSurface or bluntBody or Engine for the %s component',(ComponentName{i}));
    end

    % inspect the component's arguments
    switch (component.type)
        
        % lifting surface (wing/htail/vtail)
        case 'liftingSurface'
            
            % lifting surface checks
            if ~isfield(component,'area') || isempty(component.area)
                warning('The area field needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'taper') || isempty(component.taper)
                warning('The taper field needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'sweep') || isempty(component.sweep)
                warning('The sweep field needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'AR') || isempty(component.AR)
                warning('The aspect ratio field needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'dihedral') || isempty(component.dihedral)
                warning('The dihedral field needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'xShiftWing') || isempty(component.xShiftWing)
                warning('The xShiftWing field needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'yShiftWing') || isempty(component.yShiftWing)
                warning('The yShiftWing field needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'zShiftWing') || isempty(component.zShiftWing)
                warning('The zShiftWing field needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'orientation') || isempty(component.orientation)
                warning('The orientation field needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'symWing') || isempty(component.symWing)
                warning('The symWing field needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component.wingAfoil,'airfoilName') || isempty(component.wingAfoil.airfoilName)
                warning('The airfoilName field needs to be filled out for the %s component',(ComponentName{i}));
            end

            % create the wing/htail/vtail
            Geometry.(ComponentName{i}) = VisualizationPkg.CreateWing(Geometry.(ComponentName{i}));

        % blunt body (fuselage)
        case 'bluntBody' 
            
            % check for bluntbody inputs
            if ~isfield(component,'Length') || isempty(component.Length)
                warning('The Length of the body needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'Style') || isempty(component.Style)
                warning('The Style of the body needs to be filled out for the %s component',(ComponentName{i}));
            end
            
            % create the fuselage
            Geometry.(ComponentName{i}) = VisualizationPkg.CreateFuselage(Geometry.(ComponentName{i}));

            
        % engine
        case 'Engine'
            
            % check for engine inputs
            if ~isfield(component,'Length') || isempty(component.Length)
                warning('The Length of the Engine needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'EngineInletRadii') || isempty(component.EngineInletRadii)
                warning('The EngineInletRadii of the Engine needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'EngineOutletRadii') || isempty(component.EngineOutletRadii)
                warning('The EngineOutletRadii of the Engine needs to be filled out for the %s component',(ComponentName{i}));
            end

            if ~isfield(component,'Filename') || isempty(component.Filename)
                warning('The Filename of the Engine needs to be filled out for the %s component',(ComponentName{i}));
            end
            
            % create the engine
            Geometry.(ComponentName{i}) = VisualizationPkg.CreateEngine(Geometry.(ComponentName{i}),1);

    end
end


%% PLOT AND RETURN THE GEOMETRY %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% plot the geometry
PlotParts = VisualizationPkg.GeoPlot(Geometry, 1);

% place the geometry back in the aircraft structure
Aircraft.Geometry = Geometry;

% ----------------------------------------------------------

end