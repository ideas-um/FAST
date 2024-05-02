function [Aircraft] = EvalCruiseBRE(Aircraft)
%
% [Aircraft] = EvalCruiseBRE(Aircraft)
% originally written by Janki Patel
% overhauled by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 mar 2024
%
% The Breguet-range equation cruise segment that can solve for either the
% final aircraft weight (for a known mission range) or the mission range
% (for a known landing weight -- currently deprecated). Modified Breguet 
% range equations for hybrid-electric aircraft are used to find the outputs
% depending on the aircraft's propulsion architecture.
%
% This function is currently deprecated and may not work with the current
% version of FAST.
%
% INPUTS:
%     Aircraft - aircraft being flown.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft flown after cruise with the mission history
%                updated in "Aircraft.Mission.History.SI".
%                size/type/units: 1-by-1 / struct / []
%


%% SETUP %%
%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get necesary values from   %
% the aircraft structure     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% specific energy of fuel and battery
efuel = Aircraft.Specs.Power.SpecEnergy.Fuel;
ebatt = Aircraft.Specs.Power.SpecEnergy.Batt;

% lift-drag ratio
L_D = Aircraft.Specs.Aero.L_D.Crs;

% propulsive efficiency
EtaProp = Aircraft.Specs.Propulsion.Eta.Prop ;

% electric motor and generator efficiencies
EtaEM = Aircraft.Specs.Power.Eta.EM;
EtaEG = Aircraft.Specs.Power.Eta.EG;

% final aircraft weight --- UPDATE WHEN IMPROVEMENTS ARE MADE
%{
Wf = aircraft.weight.land;
%}

% aircraft configuration
arch = Aircraft.Specs.Propulsion.Arch;

% power split ratio
phi = Aircraft.Specs.Power.Phi.Crs;

% % aircraft design range
% R = Aircraft.Specs.Performance.Range;

% % cruise altitude
% z_cr = Aircraft.Specs.Performance.Alts.Crs;
% 
% % cruise velocity
% [~, V_cr, ~, ~, ~, ~, ~] = MissionSegsPkg.ComputeFltCon(z_cr, 0, ...
%     Aircraft.Specs.Performance.Vels.Type, Aircraft.Specs.Performance.Vels.Crs);

% number of points in the segment
npoint = Aircraft.Settings.CrsPoints;

% battery weight --- UPDATE WHEN IMPROVEMENTS ARE MADE
%{
Wbatt = aircraft.weight.batt;
%}

% thrust-specific fuel consumption
TSFC = Aircraft.Specs.Propulsion.TSFC;

% convert the power split into a vector
Phi = repmat(phi, npoint, 1);

% battery: get battery cell arrangement
SerCells = Aircraft.Specs.Power.Battery.SerCells;
ParCells = Aircraft.Specs.Power.Battery.ParCells;

% assume basic battery model (constant voltage discharge) will be used
DetailedBatt = 0;

% check if the detailed (time-dependent) battery model should be used
if (isnan(SerCells) && isnan(ParCells))
    
    % use the detailed battery model instead
    DetailedBatt = 1;
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% information from the       %
% mission profile            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the mission/segment ids
MissID = Aircraft.Mission.Profile.MissID;
SegsID = Aircraft.Mission.Profile.SegsID;

% beginning/ending cruise altitude
AltBeg = Aircraft.Mission.Profile.AltBeg(SegsID);
AltEnd = Aircraft.Mission.Profile.AltEnd(SegsID);

% beginning/ending cruise velocity
VelBeg = Aircraft.Mission.Profile.VelBeg(SegsID);
VelEnd = Aircraft.Mission.Profile.VelEnd(SegsID);

% beginning and ending speed types
TypeBeg = Aircraft.Mission.Profile.TypeBeg(SegsID);
TypeEnd = Aircraft.Mission.Profile.TypeEnd(SegsID);

% get the target
R = Aircraft.Mission.Profile.CrsTarget;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% process mission profile    %
% inputs                     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define a tolerance
EPS06 = 1.0e-06;

% check that the airspeeds are the same
if (abs(VelBeg - VelEnd) > EPS06)
    error("ERROR - EvalCruiseBRE: the initial and final airspeeds must be the same for a Breguet-based cruise.");
end

% check that the airspeed types are the same
if (strcmp(TypeBeg, TypeEnd) == 0)
    error("ERROR - EvalCruiseBRE: the initial and final airspeed types must be the same for a Breguet-based cruise.");
end

% check that the altitudes are the same
if (abs(AltBeg - AltEnd) > EPS06)
    error("ERROR - EvalCruiseBRE: the initial and final altitudes must be the same for a Breguet-based cruise.");
end

% convert the velocity to TAS (can be initial or final - they're the same)
[~, VelCrs, ~, ~, ~, ~, ~] = MissionSegsPkg.ComputeFltCon( ...
                           AltBeg, 0, TypeBeg, VelBeg);

% remember the altitiude
AltCrs = AltBeg;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                   %
% physical quantities & regression quantities       %
%                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Getting Sebatt into the correct units, don't as for correct units because our database hasit in Wh/kg 
ebatt = ebatt * 3600; % Wh/kg to Ws/kg so units work out

% solving for eta_gt which changes with altitude
EtaOv = VelCrs / (TSFC * efuel);
EtaGT = EtaOv / EtaProp;

% acceleration due to gravity at alt
g = MissionSegsPkg.Gravity(AltCrs); % m/s^2

% search for the propulsion architecture and efficiencies
if     (strcmp(arch, "AC" ) == 1)
    
    % efficiencies for conventional aircraft
    eta1 = EtaGT  ;
    eta2 = 0      ;
    eta3 = EtaProp;
    
elseif (strcmp(arch, "E"  ) == 1)
    
    % efficiencies for electric aircraft
    eta1 = 0      ;
    eta2 = EtaEM  ;
    eta3 = EtaProp;
    
elseif (strcmp(arch, "PHE") == 1)
    
    % efficiencies for parallel-hybrid electric aircraft
    eta1 = EtaGT  ;
    eta2 = EtaEM  ;
    eta3 = EtaProp;
    
elseif (strcmp(arch, "SHE") == 1)
    
    % efficiencies for series-hybrid electric aircraft
    eta1 = EtaGT * EtaEG  ;
    eta2 = 1              ;
    eta3 = EtaEM * EtaProp;
    
elseif (strcmp(arch, "TE" ) == 1)
    
    % efficiencies for fully turboelectric aircraft
    eta1 = EtaGT * EtaEG  ;
    eta2 = 0              ;
    eta3 = EtaEM * EtaProp;
    
elseif (strcmp(arch, "PE" ) == 1)
    
    % no efficiencies to compute, all done in the loop
    
else
    
    % throw an error for invalid propulsion architecture
    error("ERROR - EvalCruise: invalid propulsion architecture provided.");
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% iteration setup            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% number of points in cruise segment
if (npoint < 2)
    npoint = 100;
    
end

% fully electric propulsion architecture only uses one segment
if (strcmp(arch, "E") == 1)
    npoint = 2;
    
end

% update structure with number of points in segment
Aircraft.Settings.CrsPoints = npoint;

% find index of arrays to start writing to
[Aircraft, ielem] = DataStructPkg.InitSegment(Aircraft, "cruise", SegsID);


%% Evaluate Cruise %%
%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
%    vector initialization   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize arrays for values that accumulate
Time  = zeros(npoint, 1);
Dist  = zeros(npoint, 1);
Fburn = zeros(npoint, 1);
Efuel = zeros(npoint, 1);
Ebatt = zeros(npoint, 1);
SOC   = zeros(npoint, 1);

% in cruise, mass is evaluated sequentially; can start with zeros in array
Mass  = zeros(npoint, 1);

% initialize arrays for values that don't change
FPA   = zeros(         npoint, 1);
TAS   = repmat(VelCrs, npoint, 1);
dh_dt = zeros(         npoint, 1);
dV_dt = zeros(         npoint, 1);
Alt   = repmat(AltCrs, npoint, 1);

% if not first segment, get accumulated quantities
if (ielem > 1)
    
    % distance flown and time aloft
    Dist(1) = Aircraft.Mission.History.SI.Performance.Dist(ielem);
    Time(1) = Aircraft.Mission.History.SI.Performance.Time(ielem);
    
    % get aircraft mass
    Mass(1) = Aircraft.Mission.History.SI.Weight.CurWeight(ielem);
    
    % get fuel burn
    Fburn(1) = Aircraft.Mission.History.SI.Weight.Fburn(ielem);
    
    % energy taken from fuel and battery
    Efuel(1) = Aircraft.Mission.History.SI.Energy.Fuel(ielem);
    Ebatt(1) = Aircraft.Mission.History.SI.Energy.Batt(ielem);
    
    % check if the detailed battery model is used
    if (DetailedBatt == 1)
        
        % get SOC from the mission history
        SOC(1) = Aircraft.Mission.History.SI.Power.SOC(ielem);
        
    end
    
else
    
    % assume flight begins at mtow
    Mass(1) = Aircraft.Specs.Weight.MTOW;
    
    % check if the detailed battery model is used
    if (DetailedBatt == 1)
        
        % get beginning SOC from the aircraft structure
        SOC(1) = Aircraft.Specs.Power.Battery.BegSOC;
        
    end
    
end
    

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                       %
% Breguet Range Equations, Segments Split Over Range    %
%                                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (R > 0) % if the range has a value, then we solve for final weight

    % divide range into equidistant segments
    Dist = linspace(Dist(1), R, npoint)';
    
    % distance traveled during each segment
    dDist = diff(Dist);

    % time to fly each segment
    dTime = dDist ./ VelCrs;
    
    % perform calculation for the architectures listed below
    if ((strcmp(arch, "AC" ) == 1) || ...
        (strcmp(arch, "PHE") == 1) || ...
        (strcmp(arch, "SHE") == 1) || ...
        (strcmp(arch, "TE" ) == 1) )
    
        % loop through each point and compute the aircraft's weight
        for i = 1:(npoint - 1)
            Mass(i+1) = Mass(i) ./ exp(dDist(i) ./ eta3 ./ (efuel ./g) ./ L_D ./ (eta1 + eta2 .* (phi ./ (1 - phi))));

        end 

        % estimate the fuel burned (ncases-1)
        dFburn = -diff(Mass);
        
        % energy produced by fuel (ncases-1)
        dEfuel = dFburn .* efuel;
        
        % power produced by fuel (ncases-1, and add a 0, so ncases)
        Pfuel = [dEfuel ./ dTime; 0]; % W
        
        % power produced by battery (ncases)
        Pbatt = Pfuel .* (phi / (1 - phi)); % eq. 4, vries paper

        % check if the detailed battery model should be used
        if (DetailedBatt == 1)
            
            % power available from the battery
            [~, Pbatt, ~, SOC(2:end), ~, ~] = BatteryPkg.Model(Pbatt, ...
                dTime, SOC(1), ParCells, SerCells);
            
            % check if the SOC falls below 20%
            BattDeplete = find(SOC < 20, 1);
            
            % update the battery/EM power and SOC
            if ((~isempty(BattDeplete)) && (strcmpi(arch, "E") == 0))
                
                % no more power is provided from the electric motor or battery
                Pbatt(BattDeplete:end) = 0;
                Phi(  BattDeplete:end) = 0;
                
                % change the SOC (prior index is last charge > 20%)
                SOC(  BattDeplete:end) = SOC(BattDeplete - 1);

                % flag this result
                Aircraft.Mission.History.Flags.SOCOff(MissID) = 1;
                
            end
        end

        % energy produced by battery (ncases-1)
        dEbatt = Pbatt(1:end-1) .* dTime; % J
        
        % power required to fly each (ncases)
        Preq = eta3 .* (eta1 .* Pfuel + eta2 .* Pbatt); % Eq 5 Vries paper
        
        % propulsive power at each point (ncases)
        Pprop = Preq ./ EtaProp; % the propulsive power, W
        
        % electric motor and generator power depends on architecture
        if     (strcmp(arch, "AC" ) == 1)
            
            % no electric motor nor electric generator
            Pem = zeros(npoint, 1);
            Peg = zeros(npoint, 1);
            
        elseif (strcmp(arch, "PHE") == 1)
            
            % electric motor power
            Pem = Pbatt .* eta2;
            
            % no electric generator
            Peg = zeros(npoint, 1);
            
        else % SHE or TE
            
            % electric motor power
            Pem = Pprop;
            
            % electric generator power
            Peg = Pfuel .* EtaGT .* EtaEG;

        end

    % Vries equation does not apply to partially turboelectric architecture, so equation from EATS18
    elseif strcmp(arch,'PE') == 1

        % loop through each point and compute the aircraft's weight)
        for i = 1:(npoint - 1)
            
            % Telec / Ttot
            zeta      = (24 * EtaEM * phi) / (25 * EtaGT + 24 * EtaEM * phi - 25 * EtaGT * phi);
            
            % compute overall efficiency
            eta0      = (EtaGT * EtaProp * (EtaEM * EtaEG)) / ((1 - zeta) * (EtaEM * EtaEG) + zeta);
            
            % update the aircraft's weight
            Mass(i+1) = Mass(i) * exp(-dDist(i) ./ (L_D .* eta0 .* efuel ./ g));
            
        end
    
        % fuel burned (ncases-1)
        dFburn = -diff(Mass);
        
        % energy produced by fuel (ncases-1)
        dEfuel = dFburn .* efuel;
        
        % power provided by fuel (ncases-1, and add a 0, so ncases)
        Pfuel = [dEfuel ./ dTime; 0]; % W
        
        % power provided by electric motor (ncases)
        Pem = Pfuel .* (zeta / (1 - zeta)); % W
        
        % power provided by electric generator (ncases)
        Peg = Pem ./ EtaEM; % W
        
        % required power at each point (ncases)
        Preq = Pem .* EtaProp ./ zeta; % W
        
        % propulsive power provided (ncases)
        Pprop = Pfuel .* EtaGT; % W
        
        % no battery in a turboelectric architecture
        Pbatt  = zeros(npoint  , 1);
        dEbatt = zeros(npoint-1, 1);

    % use EATS18 equation since Vries requires taking the limit for fully electric architecure
    elseif strcmp(arch,'E') == 1

        % estimate the battery weight (matches)
        Wbatt = Mass(1) * (R - Dist(1)) ./ (ebatt/g * L_D * EtaEM * EtaProp);

        % aircraft weight won't change (matches)
        Mass(2) = Mass(1);

        % fully electric, so no fuel is burned (ncases-1) (matches)
        dFburn = zeros(npoint-1, 1);
        dEfuel = zeros(npoint-1, 1); % J
        
        % fully electric, so fuel doesn't provide power (ncases)
        Pfuel = zeros(npoint, 1); % W
        
        % energy provided by battery (ncases-1)
        dEbatt = ebatt / Wbatt; % J
        
        % power provided by battery (ncases)
        Pbatt = repmat(dEbatt / dTime, npoint, 1); % W

        % check if the detailed model should be used
        if (DetailedBatt == 1)
            
            % power available from the battery
            [~, Pbatt, ~, SOC(2:end), ~, ~] = BatteryPkg.Model(Pbatt, ...
                dTime, SOC(1), ParCells, SerCells);
        
        end

        % power provided by electric motor (ncases)
        Pem = Pbatt .* EtaEM; % W
        
        % no electric generator in a fully electric architecture
        Peg = zeros(npoint, 1); % W
        
        % power required to fly cruise segment (ncases)
        Preq = Pem .* EtaProp; % W
        
        % propulsive power required (ncases)
        Pprop = Pem; % W 
        
    else
        
        % throw an error
        error("ERROR - EvalCruiseBRE: invalid propulsion architecture specified.");
        
    end 
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                           %
% Breguet Range Equations, Segments Split Over Final Weight %
%                                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% COMPUTE RANGE FOR NONZERO LANDING WEIGHT - IMPROVE AT A LATER DATE
%{
if Wf > 0 % if the final weight has a value, then we solve for range 

    % Final weight split into segments
    Wf      = linspace(Wi, Wf, ncases);
    Wfinal  = Wf(2:end)'; % gets final weight of each segment

    % Gets the dt
    dt      = (Rseg./Vcruise); % m / m/s = s

    if strcmp(config,'PE') == 0 && strcmp(config,'E')==0 % if not partially turboelectric and not electric
      
        % depending on the configuration, the eta 1-3 values change for the modified breguet range equation 
        % (Vries Paper) 

        config_mat = {'AC' eta_gt 0 eta_p
                      'PHE' eta_gt eta_em eta_p;
                      'TE' eta_gt*eta_eg 0 eta_em*eta_p;
                      'SHE' eta_gt*eta_eg 1 eta_em*eta_p};
        
        for i = 1:4
            if strcmp(config,config_mat(i,1)) == 1
                eta1 = cell2mat(config_mat(i,2));
                eta2 = cell2mat(config_mat(i,3));
                eta3 = cell2mat(config_mat(i,4));
            end 
        end

        % serial calculations of each segment 
        for i = 1:(length(Wfinal))
            
            Rseg(i) = log(Mass(i)/Wfinal(i)) .* (eta1 + eta2.*(phi./(1-phi))) .* LD .* (Sefuel ./g) .* eta3; 
            Mass(i+1)  = Wfinal(i); % for next segment iteration, takes new initial weight to be final weight if previous segment
    
        end
      
        Wac           = Mass;
        Mass(end) = [];
        Wfuel_burned  = Mass - Wfinal; % kg
        Efuel         = Sefuel .* Wfuel_burned; % J
        Pfuel         = Efuel ./ dt; % W
        Pbatt         = (phi/(1-phi)) .* Pfuel;% ./ dt; % W, Eq 4 Vries paper 
        Ebatt         = Pbatt * dt; % J
        Preq          = eta3 .* (eta1 .* Pfuel + eta2 .* Pbatt); % Eq 5 Vries paper
        Pprop         = Preq ./ eta_p; % the propulsive power, W
        
        % power of the electric motor changes with the configurations 
        Pem_mat = {'AC'  zeros(ncases-1,1);
                   'PHE' Pbatt .* eta2;
                   'TE'  Pprop;
                   'SHE' Pprop};
        
        for i = 1:4
            if strcmp(config,config_mat(i,1)) == 1
                Pem = cell2mat(Pem_mat (i,2));
            end 
        end 

        % power of the electric generator changes with the configurations 
        Peg_mat = {'AC'  zeros(ncases-1,1);
                   'PHE' zeros(ncases-1,1);
                   'TE'  Pfuel .* eta_gt .* eta_eg;
                   'SHE' Pfuel .* eta_gt .* eta_eg};
        
        for i = 1:4
            if strcmp(config,config_mat(i,1)) == 1
                Peg = cell2mat(Peg_mat (i,2));
            end 
        end 
    end 
        
    % Vries equation does not apply to partially turboelectric architecture, so equation from EATS18
    if strcmp(config,'PE') == 1
        for i = 1:length(Wfinal)
            zeta           = (24 * eta_em * phi) / (25*eta_gt + 24 * eta_em * phi - 25 * eta_gt * phi); % Telec / Ttot
            eta0           = (eta_gt*eta_p*(eta_em*eta_eg))/((1-zeta)*(eta_em*eta_eg)+zeta);
            Rseg(i)        = -log(Wfinal(i) ./ Mass(i)) .* LD .* eta0 .* Sefuel./g;
            Mass(i+1)  = Wfinal(i); % for next segment iteration,takes new initial weight to be final weight if previous segment
        end
    
        Wac           = Mass;
        Mass(end) = [];
        Wfuel_burned  = Mass - Wfinal;
        Efuel         = Sefuel .* Wfuel_burned; % J
        Pfuel         = Efuel ./ dt; % W
        Pem           = (zeta/(1-zeta)) .* Pfuel; % W
        Peg           = Pem ./ eta_em; % W
        Preq          = Pem .* eta_p ./ zeta; % W
        Pprop         = Pfuel .* eta_gt; % Propulsive power, W
        Pbatt         = zeros(ncases-1 ,1);
        Ebatt         = zeros(ncases-1 ,1);

    end 

    % Vries equation requires taking the limit for fully electric architecure, so putting in EATS18 equation
    if strcmp(config,'E') == 1
        
        % would be a single segment
        Rseg          = Sebatt/g * LD * eta_em * eta_p * Wbatt / Wi; % cannot do an iteration because weight would be gained not lost 
        Wac           = [Wi; Wi];
        Wfuel_burned  = 0;
        Efuel         = 0; % J
        Pfuel         = 0; % W
        Ebatt         = Sebatt ./ Wbatt; % J
        Pbatt         = Ebatt ./ dt; % W
        Pem           = Pbatt .* eta_em; % W
        Peg           = 0; % W
        Preq          = Pem .* eta_p; % W
        Pprop         = Pem; % Propulsive power, W 

    end 

end
%}


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% compute additional values  %
% to be returned to the      %
% aircraft structure         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% thrust required to fly cruise
Treq = Preq ./ TAS; % for turboprop would multiply by propeller efficiency, but not sure if thats becuase power is defined as shaft power (Pprop)

% potential and kinetic energy at each control point
PE = Mass .* g .* Alt;
KE = Mass .* (TAS .^ 2 / 2);

% additional airspeed conversions at each control point
[EAS, ~, Mach, ~, ~, ~, ~] = MissionSegsPkg.ComputeFltCon(Alt, 0, 'TAS', TAS);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% compute output parameters  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% time flown
Time(2:end) = Time(1) + cumsum(dTime);

% fuel burned
Fburn(2:end) = Fburn(1) + cumsum(dFburn);

% energy taken from fuel and battery
Efuel(2:end) = Efuel(1) + cumsum(dEfuel);
Ebatt(2:end) = Ebatt(1) + cumsum(dEbatt);

% convert constant values into arrays
EtaOv = repmat(EtaOv, npoint, 1);
TSFC  = repmat(TSFC , npoint, 1);


%% FILL THE AIRCRAFT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% performance metrics
Aircraft.Mission.History.SI.Performance.Dist(ielem:end) = Dist ;
Aircraft.Mission.History.SI.Performance.Time(ielem:end) = Time ;
Aircraft.Mission.History.SI.Performance.TAS( ielem:end) = TAS  ;
Aircraft.Mission.History.SI.Performance.EAS( ielem:end) = EAS  ;
Aircraft.Mission.History.SI.Performance.RC(  ielem:end) = dh_dt;
Aircraft.Mission.History.SI.Performance.Alt( ielem:end) = Alt  ;
Aircraft.Mission.History.SI.Performance.Acc( ielem:end) = dV_dt;
Aircraft.Mission.History.SI.Performance.FPA( ielem:end) = FPA  ;
Aircraft.Mission.History.SI.Performance.Mach(ielem:end) = Mach ;

% weights
Aircraft.Mission.History.SI.Weight.CurWeight(ielem:end) = Mass ;
Aircraft.Mission.History.SI.Weight.Fburn(    ielem:end) = Fburn;

% propulsion system quantities
Aircraft.Mission.History.SI.Propulsion.Treq(ielem:end) = Treq ;
Aircraft.Mission.History.SI.Propulsion.Eta( ielem:end) = EtaOv;
Aircraft.Mission.History.SI.Propulsion.TSFC(ielem:end) = TSFC ;

% power quantities
Aircraft.Mission.History.SI.Power.Req( ielem:end) = Preq ;
Aircraft.Mission.History.SI.Power.Out( ielem:end) = Preq ;
Aircraft.Mission.History.SI.Power.Fuel(ielem:end) = Pfuel;
Aircraft.Mission.History.SI.Power.Batt(ielem:end) = Pbatt;
Aircraft.Mission.History.SI.Power.Prop(ielem:end) = Pprop;
Aircraft.Mission.History.SI.Power.EM(  ielem:end) = Pem  ;
Aircraft.Mission.History.SI.Power.EG(  ielem:end) = Peg  ;
Aircraft.Mission.History.SI.Power.Phi( ielem:end) = Phi  ;
Aircraft.Mission.History.SI.Power.SOC( ielem:end) = SOC  ;

% energy quantities
Aircraft.Mission.History.SI.Energy.PE(  ielem:end) = PE   ;
Aircraft.Mission.History.SI.Energy.KE(  ielem:end) = KE   ;
Aircraft.Mission.History.SI.Energy.Fuel(ielem:end) = Efuel;
Aircraft.Mission.History.SI.Energy.Batt(ielem:end) = Ebatt;

% current segment
Aircraft.Mission.History.Segment(ielem:end) = "Cruise";

% ----------------------------------------------------------

end 