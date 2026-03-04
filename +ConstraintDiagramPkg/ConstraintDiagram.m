function [] = ConstraintDiagram(Aircraft)
%
% ConstraintDiagram.m
% written by Paul Mokotoff, prmoko@umich.edu
% adapted from code used in AEROSP 481 as a GSI
% last updated: 04 dec 2025
%
% create a constraint diagram according to 14 CFR 23/25. for turbofans, a
% T/W-W/S diagram is created using 14 CFR 25. for turboprops/piston, either
% a W/P-W/S diagram is created using 14 CFR 25 or a P/W-W/S diagram is
% created using 14 CFR 23.
%
% INPUTS:
%     Aircraft - data structure of the aircraft to be analyzed.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     none
%


%% GET INFO ABOUT THE AIRCRAFT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the aircraft class
aclass = Aircraft.Specs.TLAR.Class;

% get the certification basis
CFRPart = Aircraft.Specs.TLAR.CFRPart;

% assume a wing-loading and thrust/power-loading to start
if      (strcmpi(aclass, "Turbofan" ) == 1)
    
    % get a thrust-loading to center the vertical axis about
    VertCent = Aircraft.Specs.Propulsion.T_W.SLS;
    
    % create a vertical range
    Vrange = linspace(max(0.10, VertCent - 0.20), min(0.80, VertCent + 0.20), 500);
    
    % axis label should be t/w
    VertLabel = "Thrust-Weight Ratio (N/N)";
    
elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
        (strcmpi(aclass, "Piston"   ) == 1) )
        
    % get the power-weight ratio and convert to W/kg from kW/kg
    VertCent = Aircraft.Specs.Power.P_W.SLS .* 1000;
    
    % check which requirements are being used
    if (CFRPart == 25)
        
        % convert from W/kg to W/N
        VertCent = VertCent / 9.81;
        
        % convert from W/N to N/W
        VertCent = 1 / VertCent;
                
        % create a vertical range
        Vrange = linspace(max(0, VertCent - 0.25), min(0.2, VertCent + 0.15), 500);
        
        % define the axis label
        VertLabel = "Power Loading (N/W)";
                        
    elseif (CFRPart == 23)
                
        % create a vertical range
        Vrange = linspace(max( 10, VertCent - 150), min(1000, VertCent + 150), 500);
        
        % axis label should be p/w
        VertLabel = "Power-Weight Ratio (W/kg)";
        
    else
        
        % throw an error
        error("ERROR - ConstraintDiagram: only 14 CFR Part 23 or 25 allowed, indicated by 23 or 25, respectively.");
        
    end
            
else
    
    % throw error
    error("ERROR - ConstraintDiagram: invalid aircraft class.");
    
end

% get the wing-loading to center the horizontal axis
HoriCent = Aircraft.Specs.Aero.W_S.SLS;

% label the horizontal axis
HoriLabel = "Wing Loading (kg/m^2)";

% center the grids (+/- 100 for horizontal, +/- 150 for vertical)
Hrange = linspace(max( 0, HoriCent - 1000), max(1000, HoriCent + 1000), 500);

% create a grid of values
[Hgrid, Vgrid] = meshgrid(Hrange, Vrange);

% get the grid size
[nrow, ncol] = size(Hgrid);


%% ESTABLISH CONSTRAINTS WITH FARS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the constraints
Cons = Aircraft.Specs.Performance.ConstraintFuns;
Labs = Aircraft.Specs.Performance.ConstraintLabs;

% get the number of constraints
ncon = length(Cons);

% memory for constraints
g = zeros(nrow, ncol, ncon);

% evaluate the constraints
for icon = 1:ncon
    
    % get the function name
    ConFun = sprintf("ConstraintDiagramPkg.%s", Cons(icon));
    
    % evaluate the constraint
    g(:, :, icon) = feval(ConFun, Hgrid, Vgrid, Aircraft);
    
end

% check for turboprop or piston aircraft using 14 CFR 25
if (strcmpi(aclass, "Turboprop") || strcmpi(aclass, "Piston")) && (CFRPart == 25)
    
    % convert the horizontal grid and range to kN/m^2
    Hgrid  = Hgrid  .* 9.81 ./ 1000;
    Hrange = Hrange .* 9.81 ./ 1000;
    
    % update the label
    HoriLabel = "Wing Loading (kN/m^2)";
    
end


%% PLOT THE CONSTRAINTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% create figure
figure;
hold on

% assume all points are feasible
set(gca, "Color", [0.475, 0.855, 0.624]);

% shade the infeasible region white using a colormap (0-1, not 0-256)
colormap([1.0, 1.0, 1.0]);

% memory for text positions
TextPos = zeros(ncon, 2);

% eliminate infinite values
g(isinf(g)) = NaN;

% shade the infeasible region
for icon = 1:ncon
    
    % shade the infeasible region for the given constraint
    FilledContour = contourf(Hgrid, Vgrid, g(:, :, icon), [0, Inf]);
    
    % get a position on the plot to leave text
    TextPos(icon, 1) = FilledContour(1, 40 * icon);
    TextPos(icon, 2) = FilledContour(2, 40 * icon);
   
end

% plot the constraint contours
for icon = 1:ncon
        
    % plot constraint contour
    contour(Hgrid, Vgrid, g(:, :, icon), [0, 0], 'k-', "LineWidth", 1.5);
    
end

% add labels
for icon = 1:ncon
    
    % place the text
    text(TextPos(icon, 1), TextPos(icon, 2), Labs(icon), "FontSize", 14);
    
end

% add axis labels
xlabel(HoriLabel);
ylabel(VertLabel);

% add axis limits
xlim([Hrange(1), Hrange(end)]);
ylim([Vrange(1), Vrange(end)]);

% get the axis
A = gca;

% increase font size
A.FontSize = 24;

% add minor grid lines
A.XMinorGrid = "on";
A.YMinorGrid = "on";

% add the grid on the top
A.Layer = "top";

% make the grid partially transparent
A.GridAlpha = 0.5;

% ----------------------------------------------------------

end