function [Aircraft] = PowerAvailable(Aircraft)
%
% [Aircraft] = PowerAvailable(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 12 dec 2024
%
% For a given propulsion architecture, compute the power available.
%
% INPUTS:
%     Aircraft - structure with information about the aircraft's propulsion
%                system architecture and SLS thrust/power requirements.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - updated structure with the total thrust power (TV)
%                that can be provided by the propulsion system.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the segment id
SegsID = Aircraft.Mission.Profile.SegsID;

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% aircraft performance history
TAS = Aircraft.Mission.History.SI.Performance.TAS(SegBeg:SegEnd);
Rho = Aircraft.Mission.History.SI.Performance.Rho(SegBeg:SegEnd);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get information about the  %
% configuration and mission  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% aircraft class
aclass = Aircraft.Specs.TLAR.Class;

% get the transmitter types
TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;

% get the number of control points in the segment
npnt = length(TAS);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get information about the  %
% power sources in the arch. %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the propulsion architecture matrix
Arch = Aircraft.Specs.Propulsion.PropArch.Arch;

% get the efficiency matrices
EtaUps = Aircraft.Specs.Propulsion.PropArch.EtaUps;

% get the operational matrices
OperUps = Aircraft.Specs.Propulsion.PropArch.OperUps;

% get the upstream power splits
LamUps = Aircraft.Mission.History.SI.Power.LamUps(SegBeg:SegEnd, :);

% get the number of components
ncomp = length(Arch);

% get the number of sources and transmitters
nsrc = length(Aircraft.Specs.Propulsion.PropArch.SrcType);
ntrn = length(Aircraft.Specs.Propulsion.PropArch.TrnType);

% get the number of sinks
nsnk = ncomp - nsrc - ntrn;


%% COMPUTE THE POWER AVAILABLE FOR THE TRANSMITTERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the SLS thrust/power available in each transmitter
ThrustAv = repmat(Aircraft.Specs.Propulsion.SLSThrust, npnt, 1);
 PowerAv = repmat(Aircraft.Specs.Propulsion.SLSPower , npnt, 1);
 
% assume no power available at the propellers yet (need to propagate)
PowerAv(:, TrnType == 2) = 0;
 
% loop through all transmitters
for itrn = 1:ntrn
    
    % check for the proper power source
    if     (TrnType(itrn) == 1) % engine
        
        % get the thrust/power available based on the aircraft class
        if      (strcmpi(aclass, "Turbofan" ) == 1)
                
            % lapse the SLS thrust
            ThrustAv(:, itrn) = PropulsionPkg.EngineLapse(ThrustAv(:, itrn), aclass, Rho);
            
            % get the available power from the gas-turbine engines
            PowerAv(:, itrn) = ThrustAv(:, itrn) .* TAS;
            
        elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
                (strcmpi(aclass, "Piston"   ) == 1) )
            
            % lapse the SLS power
            PowerAv(:, itrn) = PropulsionPkg.EngineLapse(PowerAv(:, itrn), aclass, Rho);
                
        else
            
            % throw error
            error("ERROR - PowerAvailable: invalid aircraft class.");
            
        end
        
    elseif (TrnType(itrn) == 0) % electric motor
        
        % once available, input an electric motor model here
        
    elseif (TrnType(itrn) == 2) % fuel cell
        
        % once available, input a fuel cell model here
        
    elseif (TrnType(itrn) == 3) % electric generator
        
        % once available, input an electric generator model here
        
    else
        
        % throw an error
        error("ERROR - PowerAvailable: invalid power source type in position %d.", itrn);
        
    end
end


%% COMPUTE THE TOTAL POWER AVAILABLE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% allocate memory for the power available
Pav = zeros(npnt, ncomp);

% get the transmitter and sink indices
idx = (nsrc + 1) : ncomp;

% loop through points to get the power available
for ipnt = 1:npnt
    
    % evaluate the function handles for the current splits
    Lambda = PropulsionPkg.EvalSplit(OperUps, LamUps(ipnt, :));

    % get the initial power available
    Pav(ipnt, :) = [zeros(1, nsrc), PowerAv(ipnt, :), zeros(1, nsnk)];
    
    % propagate the power upstream
    Pav(ipnt, idx) = PropulsionPkg.PowerFlow(Pav(ipnt, idx)', Arch(idx, idx), Lambda(idx, idx), EtaUps(idx, idx), +1)';
               
end

% convert the power available to thrust available
Tav = Pav ./ TAS;

% consolidate power from all sinks for now (later on, a flag will be
% introduced to neglect power off-takes)
TV = sum(Pav(:, nsrc+ntrn+1:end), 2);


%% STORE OUTPUTS IN THE AIRCRAFT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the thrust and power available for the transmitters
Aircraft.Mission.History.SI.Power.Pav(SegBeg:SegEnd, :) = Pav;
Aircraft.Mission.History.SI.Power.Tav(SegBeg:SegEnd, :) = Tav;

% remember the power available
Aircraft.Mission.History.SI.Power.TV(SegBeg:SegEnd) = TV;

% ----------------------------------------------------------

end