function [PlotParts] = GeoPlot(Geometry, ReferenceNum)
%
% [PlotParts] = GeoPlot(Geometry, ReferenceNum)
% written by Nawa Khailany, nawakhai@umich.edu
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 mar 2024
%
% Plot an aircraft configuration's geometry.
%
% INPUTS:
%     Geometry     - structure containing all of the geometric components
%                    to be plotted.
%                    size/type/units: 1-by-1 / struct / []
%
%     ReferenceNum - whether the geometry is the reference (initial)
%                    configuration or not.
%                    size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     PlotParts    - array of the plot objects on the canvases.
%                    size/type/units: n-by-1 / line / []
% 


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% set color based on the reference number provided
if (ReferenceNum == 1)
    color = "#0072BD";
else
    color = "#FF0000";
end

% get the names of the components and how many are to be plotted
componentName = fieldnames( Geometry);
componentNum  = length(componentName);

% remember the components plotted
PlotParts = [];

% create a plot
figure(7681);

% maximize the figure
set(gcf, 'Position', get(0, 'Screensize'));


%% PLOT THE GEOMETRY %%
%%%%%%%%%%%%%%%%%%%%%%%

% loop through all the components
for i = 1:componentNum
    
    % check for the proper component type
    switch Geometry.(componentName{i}).type

        % lifting surface: wing, htail, or vtail
        case 'liftingSurface'

            % check for the views
            if ~isfield(Geometry.(componentName{i}),'topView')
                warning('topView doesnt exist for %s',componentName{i});
            end

            if ~isfield(Geometry.(componentName{i}),'isoView')
                warning('Isometric View doesnt exist for %s',componentName{i});
            end

            if ~isfield(Geometry.(componentName{i}),'sideView')
                warning('sideView doesnt exist for %s',componentName{i});
            end

            if ~isfield(Geometry.(componentName{i}),'frontView')
                warning('frontView doesnt exist for %s',componentName{i});
            end

            % subplot for the top view
            subplot(2,2,1)
            hold on
            
            % plot the top view
            p01 = plot(Geometry.(componentName{i}).topView(:,1),Geometry.(componentName{i}).topView(:,2),"Color",color,"LineWidth",1.25);
            p02 = plot([Geometry.(componentName{i}).xyz(25,1);Geometry.(componentName{i}).xyz(75,1)], ...
                [Geometry.(componentName{i}).xyz(25,2);Geometry.(componentName{i}).xyz(75,2)],"Color",color,"LineWidth",1.25);
            
            % format plot
            %axis ([0 156 -78 78])
            axis equal
            grid on
            xlabel('x(ft)')
            ylabel('y(ft)')
            title(sprintf('Top View with S = %.6e ft^2',Geometry.Wing.area))

            % subplot for the isometric view
            subplot(2,2,2)
            hold on
            
            % plot the geometry
            p03 = plot3(Geometry.(componentName{i}).tip1(:,1),Geometry.(componentName{i}).tip1(:,2),Geometry.(componentName{i}).tip1(:,3),"Color",color,"LineWidth",1.25);
            p04 = plot3(Geometry.(componentName{i}).root(:,1),Geometry.(componentName{i}).root(:,2),Geometry.(componentName{i}).root(:,3),"Color",color,"LineWidth",1.25);
            p05 = plot3(Geometry.(componentName{i}).tip2(:,1),Geometry.(componentName{i}).tip2(:,2),Geometry.(componentName{i}).tip2(:,3),"Color",color,"LineWidth",1.25);
            p06 = plot3([Geometry.(componentName{i}).xyz(25,1);Geometry.(componentName{i}).xyz(75,1)], ...
                [Geometry.(componentName{i}).xyz(25,2);Geometry.(componentName{i}).xyz(75,2)], ...
                [Geometry.(componentName{i}).xyz(25,3);Geometry.(componentName{i}).xyz(75,3)],"Color",color,"LineWidth",1.25);
            p07 = plot3([Geometry.(componentName{i}).xyz(1,1);Geometry.(componentName{i}).xyz(51,1)], ...
                [Geometry.(componentName{i}).xyz(1,2);Geometry.(componentName{i}).xyz(51,2)], ...
                [Geometry.(componentName{i}).xyz(1,3);Geometry.(componentName{i}).xyz(51,3)],"Color",color,"LineWidth",1.25);
            
            % check if the wing is symmetric or not
            if Geometry.(componentName{i}).symWing == 1
                
                % plot the other half of the wing
                p08 = plot3([Geometry.(componentName{i}).xyz(125,1);Geometry.(componentName{i}).xyz(75,1)], ...
                    [Geometry.(componentName{i}).xyz(125,2);Geometry.(componentName{i}).xyz(75,2)], ...
                    [Geometry.(componentName{i}).xyz(125,3);Geometry.(componentName{i}).xyz(75,3)],"Color",color,"LineWidth",1.25);
                p09 = plot3([Geometry.(componentName{i}).xyz(101,1);Geometry.(componentName{i}).xyz(51,1)], ...
                    [Geometry.(componentName{i}).xyz(101,2);Geometry.(componentName{i}).xyz(51,2)], ...
                    [Geometry.(componentName{i}).xyz(101,3);Geometry.(componentName{i}).xyz(51,3)],"Color",color,"LineWidth",1.25);
                
            else
                
                % the wing isn't symmetric, ignore extra plotting
                p08 = plot3(NaN, NaN, NaN);
                p09 = plot3(NaN, NaN, NaN);
                
            end
            
            % format plot
            axis equal
            view(3)
            grid on
            xlabel('x(ft)')
            ylabel('y(ft)')
            zlabel('z(ft)')
            title('Isometric View')

            % subplot for the side view
            subplot(2,2,3)
            hold on
            
            % plot the side view
            p10 = plot(Geometry.(componentName{i}).sideView(:,1),Geometry.(componentName{i}).sideView(:,3),"Color",color);
            p11 = plot([Geometry.(componentName{i}).xyz(25,1);Geometry.(componentName{i}).xyz(75,1)], ...
                [Geometry.(componentName{i}).xyz(25,3);Geometry.(componentName{i}).xyz(75,3)],"Color",color);
            
            % format plot
            %axis ([0 156 -78 78])
            axis equal
            grid on
            xlabel('x(ft)')
            ylabel('z(ft)')
            title('Side View')

            % subplot for the front view
            subplot(2,2,4)
            hold on
            
            % plot the front view
            p12 = plot(Geometry.(componentName{i}).frontView(:,2),Geometry.(componentName{i}).frontView(:,3),"Color",color);
            p13 = plot([Geometry.(componentName{i}).xyz(25,2);Geometry.(componentName{i}).xyz(75,2)], ...
                [Geometry.(componentName{i}).xyz(25,3);Geometry.(componentName{i}).xyz(75,3)],"Color",color);
            
            % format plot
            axis equal
            grid on
            xlabel('y(ft)')
            ylabel('z(ft)')
            title('Front View')
            
            % remember what was plotted
            PlotParts = [PlotParts; p01; p02; p03; p04; p05; p06; p07; ...
                                    p08; p09; p10; p11; p12; p13     ] ;

        % fuselage, engine, or propeller
        otherwise
            
            % get the super-ellipses associated with the component
            SuperEllipseNames = fieldnames(Geometry.(componentName{i}).IsometricView.SuperEllipse);
            SuperEllipseNums = length(SuperEllipseNames);

            % subplot for the top View
            subplot(2,2,1)
            
            % plot the top view
            p00 = plot(Geometry.(componentName{i}).TopView(:,1),Geometry.(componentName{i}).TopView(:,2),"Color",color);
            
            % format plot
            title(sprintf('Top View with S = %.6e ft^2',Geometry.Wing.area))
            xlabel('x (ft)')
            ylabel('y (ft)')
            %axis ([0 156 -78 78])
            grid on
            
            % append the plotted component to the output
            PlotParts = [PlotParts; p00];

            %subplot for the isometric View
            subplot(2,2,2)
            hold on
                
            % plot each super-ellipse
            for j = 1:SuperEllipseNums

                % check for a blunt body (fuselage)
                if strcmp(Geometry.(componentName{i}).type, 'bluntBody')
                    
                    % check if the last super-ellipse is being plotted
                    if j < SuperEllipseNums
                        
                        % plot the super-ellipse
                        p01 = plot3(Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(:,1), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(:,2), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(:,3),"Color",color,"LineWidth",2.5);
                        
                        % plot the stringers
                        p02 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(17,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(17,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(17,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(17,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(17,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(17,3)],"Color","#D95319");	
                        p03 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(34,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(34,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(34,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(34,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(34,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(34,3)],"Color","#D95319");
                        p04 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(51,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(51,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(51,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(51,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(51,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(51,3)],"Color","#D95319");
                        p05 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(68,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(68,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(68,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(68,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(68,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(68,3)],"Color","#D95319");
                        p06 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(85,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(85,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(85,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(85,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(85,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(85,3)],"Color","#D95319");
                        p07 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(101,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(101,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(101,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(101,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(101,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(101,3)],"Color","#D95319");
                        p08 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(119,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(119,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(119,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(119,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(119,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(119,3)],"Color","#D95319");
                        p09 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(136,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(136,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(136,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(136,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(136,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(136,3)],"Color","#D95319");
                        p10 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(151,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(151,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(151,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(151,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(151,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(151,3)],"Color","#D95319");
                        p11 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(170,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(170,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(170,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(170,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(170,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(170,3)],"Color","#D95319");
                        p12 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(187,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(187,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(187,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(187,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(187,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(187,3)],"Color","#D95319");
                        p13 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(200,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(200,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(200,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(200,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(200,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j + 1}).xyzInitial(200,3)],"Color","#D95319");
    
                        % append to the output
                        PlotParts = [PlotParts; p01; p02; p03; p04; p05; ...
                                     p06;  p07; p08; p09; p10; p11; p12; p13];
                                 
                    else
                        
                        % plot the super-ellipse, but no stringers
                        p01 = plot3(Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(:,1), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(:,2), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).xyzInitial(:,3),"Color",color,"LineWidth",2.5);
                        
                        % append to the output
                        PlotParts = [PlotParts; p01];

                    end
                             
                else
                    
                    % check for a turbofan or turboprop engine
                    if strcmp(Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).EngineType,'TURBOFAN')
                        
                        % plot the inlet
                        p01 = plot3(Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(:,1), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(:,2), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(:,3),"Color",color,"LineWidth",2.5);
                        
                        % plot the lines connecting the inlet and outlet
                        p02 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(1,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(1,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(1,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(1,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(1,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(1,3)],"Color","#D95319");
                        p03 =  plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(51,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(51,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(51,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(51,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(51,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(51,3)],"Color","#D95319");
                        p04 =  plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(101,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(101,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(101,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(101,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(101,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(101,3)],"Color","#D95319");
                        p05 =  plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(151,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(151,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(151,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(151,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(151,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(151,3)],"Color","#D95319");
                        
                        % plot the outlet
                        p06 = plot3(Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(:,1), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(:,2), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(:,3),"Color",color,"LineWidth",2.5);

                        % append to the output
                        PlotParts = [PlotParts; p01; p02; p03; p04; p05; ...
                                     p06];
                        
                    else
                        
                        % plot the propeller
                        p01 = plot3(Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(:,1), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(:,2), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Inlet.xyzInitial(:,3),"Color",color,"LineWidth",2.5);
                        
                        % plot the lines between propeller and shaft
                        p02 = plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(1,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(1,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(1,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(1,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(1,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(1,3)],"Color","#D95319");
                        p03 =  plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(51,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(51,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(51,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(51,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(51,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(51,3)],"Color","#D95319");
                        p04 =  plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(101,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(101,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(101,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(101,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(101,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(101,3)],"Color","#D95319");
                        p05 =  plot3([Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(151,1);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(151,1)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(151,2);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(151,2)], ...
                            [Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(151,3);Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(151,3)],"Color","#D95319");
                        
                        % plot the end of the shaft
                        p06 = plot3(Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(:,1), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(:,2), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Outlet.xyzInitial(:,3),"Color",color,"LineWidth",2.5);
                        
                        % plot the shaft that connects to the propeller
                        p07 = plot3(Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(:,1), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(:,2), ...
                            Geometry.(componentName{i}).IsometricView.SuperEllipse.(SuperEllipseNames{j}).Shaft.xyzInitial(:,3),"Color",color,"LineWidth",2.5);
                        
                        % append to the output
                        PlotParts = [PlotParts; p01; p02; p03; p04; p05; ...
                                     p06; p07];

                    end                    
                end                
            end

            % format plot
            title('Isometric View')
            xlabel('x (ft)')
            ylabel('y (ft)')
            zlabel('z (ft)')
            axis equal
            view(3)
            grid on
            
            %subplot for the side view
            subplot(2,2,3)
            
            % plot the side view
            p00 = plot(Geometry.(componentName{i}).SideView(:,1),Geometry.(componentName{i}).SideView(:,2),"Color",color);
            
            % format plot
            title('Side View')
            xlabel('x (ft)')
            ylabel('z (ft)')
            %axis ([0 156 -78 78])
            axis equal
            grid on
            
            % append to the output
            PlotParts = [PlotParts; p00];

            % get the super-ellipses for the front View
            SuperEllipseNamesFrontView = fieldnames(Geometry.(componentName{i}).FrontView);
            SuperEllipseNumsFrontView = length(SuperEllipseNamesFrontView);
           
            % subplot for the front view
            subplot(2,2,4)
            hold on
            
            % loop through the super-ellipses to be plotted
            for k = 1:SuperEllipseNumsFrontView
                
                % plot the superellipse
                p00 = plot(Geometry.(componentName{i}).FrontView.(SuperEllipseNamesFrontView{k}).xyzInitial(:,2), ...
                    Geometry.(componentName{i}).FrontView.(SuperEllipseNamesFrontView{k}).xyzInitial(:,3),"Color",color);
                
                % add plot to the output
                PlotParts = [PlotParts; p00];
                
            end
            
            % format plot
            title('Front View')
            xlabel('y (ft)')
            ylabel('z (ft)')
            axis equal
            grid on

    end
end

% ----------------------------------------------------------

end