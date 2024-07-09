function [Tableau] = SimplexSetup(Aircraft, ielem)
%
% [Tableau] = SimplexSetup(Aircraft, ielem)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Setup the tableau required for the Simplex Method. In the inputs/outputs
% below, nx and ng represent the number of design variables and
% constraints, respectively.
%
% INPUTS:
%     Aircraft - structure containing information about the aircraft.
%                size/type/units: 1-by-1 / struct / []
%
%     ielem    - array with control point indices to be hybridized.
%                size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     Tableau  - a 2D array to input into the simplex method solver.
%                size/type/units: ng+1-by-nx+1 / double / []
%


%% GET AIRCRAFT SPECIFICATIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% shortcut to the aircraft specifications
Specs = Aircraft.Specs;

% fuel and battery specific energy
efuel = Specs.Power.SpecEnergy.Fuel;
ebatt = Specs.Power.SpecEnergy.Batt;

% propulsive efficiency
EtaProp = Specs.Propulsion.Eta.Prop;

% electric motor efficiency
EtaEM = Specs.Power.Eta.EM;

% design power split
PhiDesign = Specs.Power.Phi.SLS;

% electric motor power-weight ratio
P_Wem = Specs.Power.P_W.EM;

% electric motor weight
Wem = Specs.Weight.EM;

% battery weight
Wbatt = Specs.Weight.Batt;

% propulsion architecture type
Arch = Specs.Propulsion.Arch.Type;

% propulsion class
Class = Specs.TLAR.Class;


%% GET MISSION HISTORY %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% shortcut to the mission history
History = Aircraft.Mission.History.SI;

% power output/available
Pout = sum(History.Power.Pout_TS(ielem,:), 2);
Pav  = sum(History.Power.Pav_TS( ielem, :), 2);

% thrust-specific fuel consumption
TSFC = History.Propulsion.TSFC(ielem);

% get alititude
Alt = History.Performance.Alt(ielem);

% time elapsed
Time = History.Performance.Time(ielem);

% true airspeed
TAS = History.Performance.TAS(ielem);

% compute the time to fly between control points
dt = diff(Time);


%% PERFORM NECESSARY COMPUTATIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the coefficient to obtain the energy consumed by the battery
EbattCoeff = Pout(1:end-1) .* dt ./ EtaProp ./ EtaEM;

% compute the coefficient to obtain the gas turbine power
if     (strcmp(Arch, "PHE") == 1)
    PgtCoeff = Pout ./ EtaProp         ;
    
elseif (strcmp(Arch, "SHE") == 1)
    PgtCoeff = Pout ./ EtaProp ./ EtaEM;
    
else
    
    % throw error
    error("ERROR - SimplexSetup: can only optimize for a parallel-hybrid or series-hybrid configuration.");
    
end

% compute the coefficient to obtain electric motor power
PemCoeff = Pout ./ EtaProp ./ EtaEM;

% get the maximum electric motor power
PemMax = P_Wem * Wem;

% get the maximum battery energy
EbattMax = ebatt * Wbatt;


%% CREATE THE TABLEAU %%
%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the tableau          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the objective function requested
ObjFun = Aircraft.PowerOpt.ObjFun;

% get the segments being hybridized
Segments = Aircraft.PowerOpt.Segments;

% get the number of control points being optimized
nphi = length(dt);

% if takeoff is being optimized, ignore the first point (0 TAS)
if (any(contains(Segments, "Takeoff")))
    
    % assume a small takeoff velocity at the first point (avoids Inf error)
    TAS(1) = 1;
        
end

% number of total constraints and design variables (per power split)
ncon = 4;
nvar = 5;

% number of total constraints using all power splits
acon = 2;
avar = 2;

% allocate memory for the tableau
Tableau = zeros(ncon * nphi + acon + 1, nvar * nphi + avar + 1);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% constrain the minimum and  %
% maximum power split        %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% bound the power split
for iphi = 1:nphi
    
    % row/col for the slack variable (lower power split limit)
    irow = ncon * (iphi - 1) +        1;
    icol = ncon * (iphi - 1) + nphi + 1;
    
    % constrain the minimum power split
    Tableau(irow, iphi) = -1;
    Tableau(irow, icol) = +1;
    
    % update row/col for the next slack variable (upper power split limit)
    irow = irow + 1;
    icol = icol + 1;
    
    % constrain the maximum power split
    Tableau(irow, iphi) = 1              ;
    Tableau(irow, icol) = 1              ;
    Tableau(irow,  end) = 0.9 * PhiDesign;
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% constrain the electric     %
% motor power used per point %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loop through the power splits
for iphi = 1:nphi
    
    % row/col for the slack variable (lower power split limit)
    irow = ncon * (iphi - 1) +        3;
    icol = ncon * (iphi - 1) + nphi + 3;
    
    % constrain the minimum electric motor power (keep as 0 for now)
    Tableau(irow, iphi) = -PemCoeff(iphi);
    Tableau(irow, icol) =               1;
    
    % update row/col for the next slack variable (upper power split limit)
    irow = irow + 1;
    icol = icol + 1;
    
    % constrain the maximum power split
    Tableau(irow, iphi) = PemCoeff(iphi);
    Tableau(irow, icol) =              1;
    Tableau(irow,  end) = PemMax        ;
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% constrain the gas turbine  %
% operating limits           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loop through the power splits
% for iphi = 1:nphi
%     
%     % row/col for the slack variable (lower gas turbine limit)
%     irow = ncon * (iphi - 1) +        5;
%     icol = ncon * (iphi - 1) + nphi + 5;
%     
%     % constrain the minimum gas-turbine power
%     Tableau(irow, iphi) = 1;
%     Tableau(irow, icol) = 1;
%     Tableau(irow,  end) = 1;
%     
%     % update row/col for the next slack variable (upper gas turbine limit)
%     irow = irow + 1;
%     icol = icol + 1;
%     
%     % constrain the maximum power split
%     Tableau(irow, iphi) =  1                             ;
%     Tableau(irow, icol) = -1                             ;
%     Tableau(irow,  end) =  1 - Pav(iphi) / PgtCoeff(iphi);
%     
%     % check that right-hand side isn't NaN
%     if (isnan(Tableau(irow, end)))
%         
%         % correct it to 0
%         Tableau(irow, end) = 0;
%         
%     end        
% end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% constrain the total energy %
% used from the battery      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% row/col for the slack variable (minimum battery energy)
irow = ncon * nphi + 1;
icol = nvar * nphi + 1;

% input the coefficients (RHS remains 0)
Tableau(irow, 1:nphi) = -EbattCoeff(1:nphi);
Tableau(irow,   icol) =             1      ;

% row/col for the slack variable (maximum battery energy)
irow = irow + 1;
icol = icol + 1;

% input the coefficients and RHS
Tableau(irow, 1:nphi) = EbattCoeff(1:nphi);
Tableau(irow,   icol) =            1      ;
Tableau(irow,    end) = EbattMax          ;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% initialize the objective   %
% function                   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% find the appropriate objective function
if     (strcmp(ObjFun, "FuelBurn") == 1)
    
    % compute the fuel burn coefficients
    C = -Pout(1:end-1) .* TSFC(1:end-1) .* dt ./ TAS(1:end-1);
    
elseif (strcmp(ObjFun, "Energy"  ) == 1)
    
    % compute the total energy consumed coefficients
    C = Pout(1:end-1) .* dt .* (1 / EtaProp / EtaEM - TSFC(1:end-1) .* efuel ./ TAS(1:end-1));
    
else
    
    % throw error
    error("ERROR - SimplexSetup: invalid objective function, must be 'FuelBurn' or 'Energy'.");
    
end

% if any are NaN, there is a divide by 0 error
ic = isnan(C);

% update any NaN with 0
if (any(ic))
    C(ic) = 0;
end

% fill the tableau
Tableau(end, 1:nphi) = C';

% ----------------------------------------------------------

end