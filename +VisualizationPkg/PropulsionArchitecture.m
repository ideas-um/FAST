function [Architecture] = PropulsionArchitecture(B_PSES, B_PSPS, B_TSPS)
%
% PropulsionArchitecture.m
% written by Nawa Khailany, nawakhai@umich.edu
% last modified by Nawa Khailany, nawakhai@umich.edu
% last updated: 22 Jun 2024
%
% given a propulsion archictecture, identify the unique thrust/power/energy
% sources and their connections. then, use these sources and connections to
% create an architecture that can be plotted graphically.
%
% For the matrix inputs below, nes, nps, and nts are the number of energy
% sources, number of power sources, and number of thrust sources,
% respectively. To learn about the matrix-based propulsion architectures,
% please refer to the following paper:
%
%     Cinar, G., Garcia, E., & Mavris, D. N. (2020). A framework for
%     electrified propulsion architecture and operation analysis. Aircraft
%     Engineering and Aerospace Technology, 92(5), 675-684.
%
% INPUTS:
%     B_PSES       - matrix showing connections between power sources
%                    and energy sources.
%                    size/type/units: nps-by-nes / int / []
%
%     B_PSPS       - matrix showing connections between driving power
%                    sources and driven power sources.
%                    size/type/units: nps-by-nps / int / []
%
%     B_TSPS       - matrix showing connections between power sources
%                    and thrust sources.
%                    size/type/units: nts-by-nps / int / []
%
% OUTPUTS:
%     Architecture - structure with the unique thrust/power/energy
%                    sources and their connections.
%                    size/type/units: 1-by-1 / struct / []


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the number of thrust/power/energy sources in the architecture
[NumPSources, NumESources] = size(B_PSES);
[NumTSources,           ~] = size(B_TSPS);

% compute the total number of sources in the architecture
NumComponents = NumESources + NumPSources + NumTSources;

% create structures to stor information about the architecture
Architecture       = struct();
Architecture.Index = struct();


%% IDENTIFY CONNECTIONS BETWEEN COMPONENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loop through all of the components
for i = 1:NumComponents

    % convert the index into a valid name
    IdxName = matlab.lang.makeValidName(num2str(i));

    % check for the connection type
    if i <= NumESources % energy-power source
        
        % create structure for the component
        Architecture.Index.(IdxName) = struct();

        % name the component
        Architecture.Index.(IdxName).Name = ['EnergySource_', num2str(i)];

        % allocate memory for its connections
        ToLeave = [];
        ToEnter = [];

        % loop through the power sources to find its connections
        for j = 1:NumPSources
            
            % check for a 1 in the matrix
            if B_PSES(j, i) == 1
                
                % add connection (leave energy source, enter power source)
                ToLeave = [ToLeave; j + NumESources];

                % print statement
                fprintf('%s connects to %s\n',['PowerSource_' , num2str(j)], ...
                                              ['EnergySource_', num2str(i)])   ;
 
            else
                
                % print statement
                fprintf('%s does not connect to %s\n',['PowerSource_' , num2str(j)], ...
                                                      ['EnergySource_', num2str(i)])   ;
                                                  
            end
        end

        % insert back into the struct
        Architecture.Index.(IdxName).Leaving  = ToLeave;
        Architecture.Index.(IdxName).Entering = ToEnter;

    elseif i > NumESources && i <= NumESources + NumPSources % (power-power source)

        % create structure for the component
        Architecture.Index.(IdxName) = struct();

        % name the component
        Architecture.Index.(IdxName).Name = ['PowerSource_', num2str(i - NumESources)];

        % allocate memory for the connections
        ToLeave = [];
        ToEnter = [];

        % loop through all power sources
        for j = 1:NumPSources
            
            % check for connections to energy sources
            if B_PSPS(j, i - NumESources) == 1
                
                % add connection (leave energy source, enter power source)
                ToLeave = [ToLeave; j + NumESources];

                % print statement
                fprintf('%s connects to %s\n',['PowerSource_', num2str(j)]              , ...
                                              ['PowerSource_', num2str(i - NumESources)])   ;

            else
                
                % print statement
                fprintf('%s does not connect to %s\n',['PowerSource_', num2str(j)]              , ...
                                                      ['PowerSource_', num2str(i - NumESources)])   ;

            end
        end

        % loop through the power sources again
        for j = 1:NumPSources
            
            % check for power-power source connections
            if B_PSPS(i - NumESources, j) == 1
                
                % add the connection
                ToEnter = [ToEnter; j + NumESources];

            end
        end

        % remember the connections 
        Architecture.Index.(IdxName).Leaving  = ToLeave;
        Architecture.Index.(IdxName).Entering = ToEnter;

    else % power-thrust source connections
        
        % create structure for the component
        Architecture.Index.(IdxName) = struct();

        % name the component
        Architecture.Index.(IdxName).Name = ['ThrustSource_', num2str(i - NumESources - NumPSources)];

        % allocate memory for the connections
        ToLeave = [];
        ToEnter = [];

        % loop through all thrust sources
        for j = 1:NumTSources

            if NumTSources == 1
            
                for k = 1:NumPSources
                    % check for a connections
                    if B_TSPS(j, i - NumESources - NumPSources + k - 1)
                        
                        % add the connection (from power source to thrust source)
                        ToEnter = [ToEnter; i - NumPSources + k - 1];
        
                        % add the connection
                        Architecture.Index.(['x', num2str(i - NumPSources + k - 1)]).Leaving = [Architecture.Index.(['x', num2str(i - NumPSources + k - 1)]).Leaving; i];
        
                        % print statement
                        fprintf('%s is driven by %s\n',['ThrustSource_',num2str(j)]                           , ...
                                                       ['PowerSource_',num2str(i - NumESources - NumPSources + k - 1)])   ;
                      
                    else
                        
                        % print statement
                        fprintf('%s is not driven by %s\n',['ThrustSource_',num2str(j)]                           , ...
                                                           ['PowerSource_',num2str(i - NumESources - NumPSources + k - 1)])   ;
        
                    end
                end
            else 
                % check for a connections
                    if B_TSPS(j, i - NumESources - NumPSources)
                        
                        % add the connection (from power source to thrust source)
                        ToEnter = [ToEnter; i - NumPSources];
        
                        % add the connection
                        Architecture.Index.(['x', num2str(i - NumPSources)]).Leaving = [Architecture.Index.(['x', num2str(i - NumPSources)]).Leaving; i];
        
                        % print statement
                        fprintf('%s is driven by %s\n',['ThrustSource_',num2str(j)]                           , ...
                                                       ['PowerSource_',num2str(i - NumESources - NumPSources)])   ;
                      
                    else
                        
                        % print statement
                        fprintf('%s is not driven by %s\n',['ThrustSource_',num2str(j)]                           , ...
                                                           ['PowerSource_',num2str(i - NumESources - NumPSources)])   ;
        
                    end
            end
        end

        % remember the connnections
        Architecture.Index.(IdxName).Leaving = ToLeave;
        Architecture.Index.(IdxName).Enterting = ToEnter;

    end
end


%% MAKE GRAPHING OBJECTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% pre-determined spacing parameters
ySpacing = 10;
xSpacing = 10;

% initial vertical position (horizontal position not needed)
yInit = 50;

% counter for the power sources plotted in the driving/driven columns
NumPSourcesCol2ctr = 1;
NumPSourcesCol3ctr = 1;

% loop through the components
for i = 1:NumComponents

    % check for the component type
    if i <= NumESources % energy source
        
        % rectangle creation
        Architecture.Index.(['x', num2str(i)]).rect = rectangle('Position', [xSpacing, -ySpacing * i + yInit, 5, 5]);

        % text bubble creation
        Architecture.Index.(['x', num2str(i)]).text = text(xSpacing + 0.5, -ySpacing * i + yInit + 2.5, Architecture.Index.(['x',num2str(i)]).Name);

    elseif i > NumESources && i <= NumESources + NumPSources % power source
        
        % determine if power source driven by another power source
        [NumExiting, ~] = size(Architecture.Index.(['x',num2str(i)]).Entering);

        % check if the power source
        if NumExiting > 1

            % rectangle creation
            Architecture.Index.(['x',num2str(i)]).rect = rectangle('Position', [3 * xSpacing, -ySpacing * NumPSourcesCol3ctr + yInit, 5, 5]);

            % text bubble creation
            Architecture.Index.(['x',num2str(i)]).text = text(3 * xSpacing + 0.5, -ySpacing * NumPSourcesCol3ctr + yInit + 2.5, Architecture.Index.(['x',num2str(i)]).Name);

            % increment counter
            NumPSourcesCol3ctr = NumPSourcesCol3ctr + 1;

        else

            % rectangle creation
            Architecture.Index.(['x',num2str(i)]).rect = rectangle('Position', [2 * xSpacing, -ySpacing * NumPSourcesCol2ctr + yInit, 5, 5]);

            % text bubble creation
            Architecture.Index.(['x',num2str(i)]).text = text(2 * xSpacing + 0.5, -ySpacing * NumPSourcesCol2ctr +yInit + 2.5, Architecture.Index.(['x',num2str(i)]).Name);

            % increment counter
            NumPSourcesCol2ctr = NumPSourcesCol2ctr + 1;

        end

    else % thrust sources

        %rectangle creation
        Architecture.Index.(['x',num2str(i)]).rect = rectangle('Position', [4 * xSpacing, -ySpacing * (i - NumESources - NumPSources) + yInit, 5, 5]);

        %text bubble creation
        Architecture.Index.(['x',num2str(i)]).text = text(4 * xSpacing + 0.5, -ySpacing * (i - NumESources - NumPSources) + yInit + 2.5, Architecture.Index.(['x',num2str(i)]).Name);

    end

end


%% CREATE CONNECTION LINES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% line counter for connection structure
linectr = 1;

% make a structure for all of the connections
Architecture.Connection = struct();

% loop through the components to create the lines
for i = 1:NumComponents
    
    % check for the source type
    if i <= NumESources % energy source

        % count number of connections
        [NumConnects, ~] = size(Architecture.Index.(['x',num2str(i)]).Leaving);

        % get y-spacing for lines
        ySpace = 5 / (NumConnects + 1);

        % get x-spacing 
        xSpace = 5 / (NumConnects + 1);

        % create line connection
        Architecture.Connection.(['line_',num2str(linectr)]) = struct();

        % loop through each connection
        for j = 1:NumConnects

            % get component that is connected to it
            ConnectTo = Architecture.Index.(['x',num2str(i)]).Leaving(j);

            % get the coordinates and put them into the connection
            Architecture.Connection.(['line_',num2str(linectr)]) = [Architecture.Index.(['x',num2str(i)]).rect.Position(1)+...
                                                                    Architecture.Index.(['x',num2str(i)]).rect.Position(3),...
                                                                    Architecture.Index.(['x',num2str(i)]).rect.Position(1)+...
                                                                    Architecture.Index.(['x',num2str(i)]).rect.Position(3)+...
                                                                    (5 - j*xSpace)                                        ,...
                                                                    Architecture.Index.(['x',num2str(i)]).rect.Position(1)+...
                                                                    Architecture.Index.(['x',num2str(i)]).rect.Position(3)+...
                                                                    (5 - j*xSpace)                                        ,...
                                                                    Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(1);
                                                                    Architecture.Index.(['x',num2str(i)]).rect.Position(2)+...
                                                                    Architecture.Index.(['x',num2str(i)]).rect.Position(4)+...
                                                                    (0 - j*ySpace)                                        ,...
                                                                    Architecture.Index.(['x',num2str(i)]).rect.Position(2)+...
                                                                    Architecture.Index.(['x',num2str(i)]).rect.Position(4)+...
                                                                    (0 - j*ySpace)                                        ,...
                                                                    Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(2)+...
                                                                    (Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(4)/2),...
                                                                    Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(2)+...
                                                                    (Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(4)/2)];                                      

            % increment the counter
            linectr = linectr + 1;

        end


    elseif i > NumESources && i <= NumESources + NumPSources % power sources
        
        % count number of connections
        [NumConnects,~] = size(Architecture.Index.(['x',num2str(i)]).Leaving);

        % get y-spacing for lines
        ySpace = 5 / (NumConnects + 1);

        % get x-spacing 
        xSpace = 5 / (NumConnects + 1);

        % create line connection
        Architecture.Connection.(['line_',num2str(linectr)]) = struct();

        % loop through the connections
        for j = 1:NumConnects

            % get component that is connected to it
            ConnectTo = Architecture.Index.(['x',num2str(i)]).Leaving(j);

            % check that it doesn't connect to itself
            if ConnectTo ~= i

                % create line based on number of connections
                if NumConnects == 2

                    %get the coordinates and put them into the connection
                    Architecture.Connection.(['line_',num2str(linectr)]) = [Architecture.Index.(['x',num2str(i)]).rect.Position(1)+...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(3),...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(1)+...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(3)+...
                                                                            (5 - j*xSpace)                                       ,...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(1)+...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(3)+...
                                                                            (5 - j*xSpace)                                       ,...
                                                                            Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(1);
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(2)+...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(4)+...
                                                                            (0 - 2.5)                                             ,...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(2)+...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(4)+...
                                                                            (0 - 2.5)                                        ,...
                                                                            Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(2)+...
                                                                            (Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(4)/2),...
                                                                            Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(2)+...
                                                                            (Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(4)/2)];                                      
    
                    % increment the counter
                    linectr = linectr + 1;

                else

                    %get the coordinates and put them into the connection
                    Architecture.Connection.(['line_',num2str(linectr)]) = [Architecture.Index.(['x',num2str(i)]).rect.Position(1)+...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(3),...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(1)+...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(3)+...
                                                                            (5 - j*xSpace)                                       ,...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(1)+...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(3)+...
                                                                            (5 - j*xSpace)                                       ,...
                                                                            Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(1);
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(2)+...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(4)+...
                                                                            (0 - 2.5)                                        ,...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(2)+...
                                                                            Architecture.Index.(['x',num2str(i)]).rect.Position(4)+...
                                                                            (0 - 2.5)                                        ,...
                                                                            Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(2)+...
                                                                            (Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(4)/2),...
                                                                            Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(2)+...
                                                                            (Architecture.Index.(['x',num2str(ConnectTo)]).rect.Position(4)/2)];                                      
    
                    %increment the counter
                    linectr = linectr + 1;

                end
            end
        end
    end
end

% ----------------------------------------------------------

end