function [Aircraft] = PropAnalysis(Aircraft, ielem)
%
% [Aircraft] = PropAnalysis(Aircraft, ielem)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 mar 2024
%
% Analyze the propulsion system for a given set of flight conditions.
% Remember how the propulsion system performs in the mission history. Note
% that this function is currently deprecated and is only used in
% MissionSegsPkg/EvalCruiseBRE, which is also deprecated.
%
% INPUTS:
%     Aircraft - structure with information about the aircraft and the
%                mission segment it just flew.
%                size/type/units: 1-by-1 / struct / []
%
%     ielem    - index of mission history where the segment begins.
%                size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     Aircraft - updated structure with propulsion performance data and
%                energy expenditures.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aircraft specifications    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the propulsion architecture
Arch = Aircraft.Specs.Propulsion.Arch;

% propulsive efficiency
EtaProp = Aircraft.Specs.Propulsion.Eta.Prop;

% electric motor efficiency
EtaEM = Aircraft.Specs.Power.Eta.EM;

% thrust-specific fuel consumption
TSFC = Aircraft.Specs.Propulsion.TSFC;

% specific energy of fuel
efuel = Aircraft.Specs.Power.SpecEnergy.Fuel;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% mission history            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% power split
Phi  = Aircraft.Mission.History.SI.Power.Phi(ielem:end);

% power output
Pout = Aircraft.Mission.History.SI.Power.Out(ielem:end);

% aircraft weight
Mass = Aircraft.Mission.History.SI.Weight.CurWeight(ielem:end);

% performance history
Time = Aircraft.Mission.History.SI.Performance.Time(ielem:end);
TAS  = Aircraft.Mission.History.SI.Performance.TAS( ielem:end);

% compute the time to travel between control points
dt = diff(Time);

% get the number of control points in the segment
npoint = length(Time);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup cumulative fuel and  %
% energy quantities          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% fuel burn
Fburn = zeros(npoint, 1);
Efuel = zeros(npoint, 1);
Ebatt = zeros(npoint, 1);

% fill first element if there is a mission history
if (ielem > 1)
    
    % get the fuel burn
    Fburn(1) = Aircraft.Mission.History.SI.Weight.Fburn(ielem);
    
    % get the energy expended by fuel and batteries
    Efuel(1) = Aircraft.Mission.History.SI.Energy.Fuel( ielem);
    Ebatt(1) = Aircraft.Mission.History.SI.Energy.Batt( ielem);
    
end


%% PROPULSION SYSTEM ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% power analysis for conventional, parallel hybrid, and electric
if ((strcmpi(Arch, "AC" ) == 1) || ...
    (strcmpi(Arch, "PHE") == 1) || ...
    (strcmpi(Arch, "E"  ) == 1) )
    
    % if conventional aircraft, only fuel is used
    if (strcmpi(Arch, "AC") == 1)
        Phi = zeros(npoint, 1);
    end
    
    % if electric aircraft, only battery is used
    if (strcmpi(Arch, "E") == 1)
        Phi = ones(npoint, 1);
    end
    
    % compute the propulsive power required (ncases)
    Pprop = Pout ./ EtaProp;
    
    % compute the electric motor power (ncases)
    Pem = Pprop .* Phi;
    
    % battery power is the same as the electric motor power (ncases)
    Pbatt = Pem ./ EtaEM;
    
    % compute the energy required (ncases-1)
    dEbatt = Pbatt(1:end-1) .* dt;
    
    % compute the fuel burn (ncases-1)
    dFburn = Pout(1:end-1) .* (1 - Phi(1:end-1)) .* TSFC .* dt ./ TAS(1:end-1);
    
    % update the aircraft's mass (ncases-1)
    Mass(2:end) = Mass(1) - cumsum(dFburn);
    
    % computed the energy stored in the fuel (ncases-1)
    dEfuel = dFburn .* efuel;
    
    % compute the overall efficiency (ncases-1)
    eta = [Pout(1:end-1) .* (1 - Phi(1:end-1)) .* dt ./ dEfuel; 0];
    
    % compute the power stored in the fuel (ncases-1)
    Pfuel = [Pout(1:end-1) .* (1 - Phi(1:end-1)) ./ eta(1:end-1); 0];
    
    % no electric generator (ncases)
    Peg = zeros(npoint, 1);
    
end

% power analysis for series hybrid
if (strcmpi(Arch, "SHE") == 1)
    
    % compute the propulsive power (ncases)
    Pprop = Pout ./ EtaProp;
    
    % compute the electric motor power (ncases)
    Pem = Pprop;
    
    % compute the battery power (ncases)
    Pbatt = Pem .* Phi ./ EtaEM;
    
    % compute the electric generator power (ncases)
    Peg = Pem .* (1 - Phi) ./ EtaEM;
    
    % compute the energy in the battery (ncases-1)
    dEbatt = Pbatt(1:end-1) .* dt;
    
    % compute the fuel burn (ncases-1)
    dFburn = Pout(1:end-1) .* (1 - Phi(1:end-1)) .* TSFC .* dt ./ TAS(1:end-1);
    
    % update the aircraft's mass (ncases-1)
    Mass(2:end) = Mass(1) - cumsum(dFburn);
    
    % compute the energy stored in the fuel (ncases-1)
    dEfuel = dFburn .* efuel;
    
    % compute the overall efficiency (ncases-1)
    eta = [Pout(1:end-1) .* (1 - Phi(1:end-1)) .* dt ./ efuel; 0];
    
    % power stored in the fuel (ncases-1)
    Pfuel = [Pout(1:end-1) .* (1 - Phi(1:end-1)) ./ eta(1:end-1); 0];
    
end

% power analysis for fully turboelectric
if (strcmpi(Arch, "TE") == 1)
    
    % compute the propulsive power (ncases)
    Pprop = Pout ./ EtaProp;
    
    % compute the electric motor power (ncases)
    Pem = Pprop;
    
    % compute the electric generator power (ncases)
    Peg = Pem ./ EtaEM;
    
    % there is no battery (ncases-1)
    dEbatt = zeros(npoint-1, 1);
    
    % compute the fuel burn (ncases-1)
    dFburn = Pout(1:end-1) .* TSFC .* dt ./ TAS(1:end-1);
    
    % update the aircraft's mass (ncases-1)
    Mass(2:end) = Mass(1) - cumsum(dFburn);
    
    % compute the energy stored in the fuel (ncases-1)
    dEfuel = dFburn .* efuel;
    
    % compute the overall efficiency (ncases-1)
    eta = [Pout(1:end-1) .* dt ./ dEfuel; 0];
    
    % compute the power stored in the fuel (ncases-1)
    Pfuel = [Pout(1:end-1) ./ eta; 0];
    
    % no battery (ncases)
    Pbatt = zeros(npoint, 1);
    
end

% partially turboelectric
if (strcmpi(Arch, "PE") == 1)
    
    % compute the propulsive power (ncases)
    Pprop = Pout ./ EtaProp;
    
    % compute the electric motor power (ncases)
    Pem = Pprop .* Phi;
    
    % compute the electric generator power (ncases)
    Peg = Pem ./ EtaEM;
    
    % no battery (ncases-1)
    dEbatt = zeros(npoint-1, 1);
    
    % compute the fuel burn (ncases-1)
    dFburn = Pout(1:end-1) .* TSFC .* dt ./ TAS(1:end-1);
    
    % update the aircraft's mass (ncases-1)
    Mass(2:end) = Mass(1) - cumsum(dFburn);
    
    % compute the energy stored in the fuel (ncases-1)
    dEfuel = dFburn .* efuel;
    
    % compute the overall efficiency (ncases-1)
    eta = [Pout(1:end-1) .* dt ./ dEfuel; 0];
    
    % compute the power stored in the fuel (ncases-1)
    Pfuel = [Pout(1:end-1) ./ eta; 0];
    
    % no battery (ncases)
    Pbatt = zeros(npoint, 1);
    
end
    

%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% compute accumulating       %
% quantities                 %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% fuel burned
Fburn(2:end) = Fburn(1) + cumsum(dFburn);

% energy taken from fuel and battery
Efuel(2:end) = Efuel(1) + cumsum(dEfuel);
Ebatt(2:end) = Ebatt(1) + cumsum(dEbatt);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% store information in the   %
% mission history            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% weights
Aircraft.Mission.History.SI.Weight.CurWeight(ielem:end) = Mass ;
Aircraft.Mission.History.SI.Weight.Fburn(    ielem:end) = Fburn;

% propulsion system quantities
Aircraft.Mission.History.SI.Propulsion.Eta(ielem:end) = eta ;

% power quantities
Aircraft.Mission.History.SI.Power.Fuel(ielem:end) = Pfuel;
Aircraft.Mission.History.SI.Power.Batt(ielem:end) = Pbatt;
Aircraft.Mission.History.SI.Power.Prop(ielem:end) = Pprop;
Aircraft.Mission.History.SI.Power.EM(  ielem:end) = Pem  ;
Aircraft.Mission.History.SI.Power.EG(  ielem:end) = Peg  ;

% energy quantities
Aircraft.Mission.History.SI.Energy.Fuel(ielem:end) = Efuel;
Aircraft.Mission.History.SI.Energy.Batt(ielem:end) = Ebatt;

% ----------------------------------------------------------

end