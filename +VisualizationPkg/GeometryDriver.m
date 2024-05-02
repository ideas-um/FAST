function [Aircraft] = GeometryDriver(Aircraft, ReferenceNum, ScaleFactor, LengthSet)

% [Aircraft] = GeometryDriver(Aircraft, ReferenceNum, ScaleFactor, LengthSet)
% written by Nawa Khailany
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 mar 2024
%
% Given an aircraft configuration, generate the geometry to visualize the
% provided components and plot them in a three-view and isometric view.
%
% INPUTS:
%     Aircraft     - aircraft structure with a "Geometry" sub-structure.
%                    size/type/units: 1-by-1 / struct / []
%
%     ReferenceNum - an integer to indicate whether the inputted geometry
%                    is the reference configuration (1) or not (0).
%                    size/type/units: 1-by-1 / int / []
%
%     ScaleFactor  - a scale factor that updates the size of any wing,
%                    htail, vtail, and engine in the configuration, which
%                    is typically used during aircraft sizing.
%                    size/type/units: 1-by-1 / double / []
%
%     LengthSet    - the prescribed fuselage length.
%                    size/type/units: 1-by-1 / double / [m]
%
% OUTPUTS:
%     Aircraft     - updated "Geometry" sub-structure with the 3D
%                    coordinates and views that will be plotted.
%                    size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get information from the   %
% aircraft structure and     %
% check for valid inputs     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if the user provided a desired geometry, and assign TempPreset
% if isa(Aircraft.Geometry.Preset, 'function_handle')
% 
    TempPreset = Aircraft.Geometry.Preset;

    % desired geometry provided, use the configuration prescribed
    Aircraft = TempPreset(Aircraft);

    Aircraft.Geometry = rmfield(Aircraft.Geometry,"Preset");
% 
% else
% 
%     % no geometry was provided, default to a narrow-body transport
%     Aircraft = VisualizationPkg.GeometrySpecsPkg.Transport(Aircraft);
% 
% end

%check if geometry struct is empty
if ~isfield(Aircraft,'Geometry')
    error('Aircraft structure does not include Geometry');
end

% get the wing area from the aerodynamic specification (and convert to ft)
area = Aircraft.Specs.Aero.S * UnitConversionPkg.ConvLength(1, 'm', 'ft') ^ 2;

% update the area in the geometry substructure
% (for this to work, there must be a **Wing** component)
Aircraft.Geometry.Wing.area = area;

% find fuselage length scale factor
SFFuseLength = LengthSet / Aircraft.Geometry.Fuselage.Length;

%remove LengthSet and assign it temporarily
TempLength = Aircraft.Geometry.LengthSet;

Aircraft.Geometry = rmfield(Aircraft.Geometry,"LengthSet");


% unzip the geometry structure
Geometry = Aircraft.Geometry;

% find out how many components there are and their names
componentName = fieldnames( Geometry);
componentNum  = length(componentName);


%% CHECK FOR VALID COMPONENT INPUTS AND MAKE GEOMETRY %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check for valid components and that all necessary parameters exist
for i = 1:componentNum
    
    % get the sub-structure
    component = Geometry.(componentName{i});

    % check that the user prescribed a component type
    if ~isfield(component,'type') || isempty(component.type)
        error('Component type cant be empty and needs to be filled out between either liftingSurface or bluntBody for the %s component',(componentName{i}));
    end

    % check if the prescribed component type exists
    if (~strcmp(component.type,'liftingSurface')) && (~strcmp(component.type,'bluntBody')) && (~strcmp(component.type,'Engine'))
        error('Component type needs to be specified between liftingSurface or bluntBody or Engine for the %s component',(componentName{i}));
    end

    % check the the component parameters all exist
    switch component.type
        
        case 'liftingSurface'
            
            % lifting Surface checks
            if ~isfield(component,'area') || isempty(component.area)
                warning('The area field needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'taper') || isempty(component.taper)
                warning('The taper field needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'sweep') || isempty(component.sweep)
                warning('The sweep field needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'AR') || isempty(component.AR)
                warning('The aspect ratio field needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'dihedral') || isempty(component.dihedral)
                warning('The dihedral field needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'xShiftWing') || isempty(component.xShiftWing)
                warning('The xShiftWing field needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'yShiftWing') || isempty(component.yShiftWing)
                warning('The yShiftWing field needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'zShiftWing') || isempty(component.zShiftWing)
                warning('The zShiftWing field needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'orientation') || isempty(component.orientation)
                warning('The orientation field needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'symWing') || isempty(component.symWing)
                warning('The symWing field needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component.wingAfoil,'airfoilName') || isempty(component.wingAfoil.airfoilName)
                warning('The airfoilName field needs to be filled out for the %s component',(componentName{i}));
            end

            % check if the component name matches for auto-scaling
            if strcmp(componentName{i}, "Wing")

                % scale the x-location for component
                Geometry.(componentName{i}).xShiftWing = SFFuseLength * Geometry.(componentName{i}).xShiftWing;

            else

                % scale area for component
                Geometry.(componentName{i}).area = ScaleFactor * Geometry.(componentName{i}).area;
    
                % scale the x-location for component
                Geometry.(componentName{i}).xShiftWing = SFFuseLength * Geometry.(componentName{i}).xShiftWing;

            end

            % create the wing
            Geometry.(componentName{i}) = VisualizationPkg.CreateWing(Geometry.(componentName{i}));

        case 'bluntBody' 
            
            % check for bluntbody inputs
            if ~isfield(component,'Length') || isempty(component.Length)
                warning('The Length of the body needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'Style') || isempty(component.Style)
                warning('The Style of the body needs to be filled out for the %s component',(componentName{i}));
            end

            % scale length for component
            Geometry.(componentName{i}).Length =  SFFuseLength * Geometry.(componentName{i}).Length;
            
            % create the fuselage
            Geometry.(componentName{i}) = VisualizationPkg.CreateFuselage(Geometry.(componentName{i}));

        case 'Engine'
            
            % check for engine inputs
            if ~isfield(component,'Length') || isempty(component.Length)
                warning('The Length of the Engine needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'EngineInletRadii') || isempty(component.EngineInletRadii)
                warning('The EngineInletRadii of the Engine needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'EngineOutletRadii') || isempty(component.EngineOutletRadii)
                warning('The EngineOutletRadii of the Engine needs to be filled out for the %s component',(componentName{i}));
            end

            if ~isfield(component,'Filename') || isempty(component.Filename)
                warning('The Filename of the Engine needs to be filled out for the %s component',(componentName{i}));
            end

            % scale Length for component
            Geometry.(componentName{i}).Length = ScaleFactor * Geometry.(componentName{i}).Length;

            % scale inlet and outlet radii for component
            Geometry.(componentName{i}).EngineInletRadii  = ScaleFactor * Geometry.(componentName{i}).EngineInletRadii ;
            Geometry.(componentName{i}).EngineOutletRadii = ScaleFactor * Geometry.(componentName{i}).EngineOutletRadii;

            % create the Engine
            Geometry.(componentName{i}) = VisualizationPkg.CreateEngine(Geometry.(componentName{i}),SFFuseLength);

    end
end


%% PLOT THE GEOMETRY %%
%%%%%%%%%%%%%%%%%%%%%%%

% plotting
PlotParts = VisualizationPkg.GeoPlot(Geometry, ReferenceNum);

% delete temporary parts if they exist
if isfield(Aircraft,'TempParts')
    delete(Aircraft.TempParts);
end

% store the correct parts
if ReferenceNum == 1
    
    % store reference configuration (initial configuration)
    RefParts = PlotParts;
    
    % no temporary parts exist yet
    TempParts = [];

else
    
    % store temporary configuration that will be deleted later
    TempParts = PlotParts;

end

% return the geometry structure
Aircraft.Geometry = Geometry;

% return the necessary configurations
if ReferenceNum == 1
    
    % return the reference and temporary configruation
    Aircraft.RefParts  =  RefParts;
    Aircraft.TempParts = TempParts;
    
else
    
    % return the temporary configuration only
    Aircraft.TempParts = TempParts;
    
end

% Add back to preset
Aircraft.Geometry.Preset = TempPreset;

% Add back to lengthset
Aircraft.Geometry.LengthSet = TempLength;

% ----------------------------------------------------------

end