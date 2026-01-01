function [Aircraft] = PowerAvailable(Aircraft)
%
% [Aircraft] = PowerAvailable(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 17 sep 2025
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

% get the sink indices
isnk = (nsrc + ntrn + 1) : ncomp;


%% COMPUTE THE POWER AVAILABLE FOR THE TRANSMITTERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the SLS thrust/power available in each transmitter
ThrustAv = repmat(Aircraft.Specs.Propulsion.SLSThrust, npnt, 1);
 PowerAv = repmat(Aircraft.Specs.Propulsion.SLSPower , npnt, 1);
 
% remember the SLS power separately
SLSPower = Aircraft.Specs.Propulsion.SLSPower;

% get indices for transmitters
itrn = (1:ntrn) + nsrc;

% find all upstream transmitters (i.e., input at least one transmitter and
% maybe a source)
UpTrn = find(sum(Arch(itrn, itrn), 1) > 0);

% assume no power available at the propellers yet (need to propagate)
PowerAv(:, UpTrn) = 0; %#ok<FNDSB>
 
% loop through all transmitters
for jtrn = 1:ntrn
    
    % check for the proper power source
    if     (TrnType(jtrn) == 1) % engine
        
        % get the thrust/power available based on the aircraft class
        if      (strcmpi(aclass, "Turbofan" ) == 1)
                
            % lapse the SLS thrust
            ThrustAv(:, jtrn) = PropulsionPkg.EngineLapse(ThrustAv(:, jtrn), aclass, Rho);
            
            % get the available power from the gas-turbine engines
            PowerAv(:, jtrn) = ThrustAv(:, jtrn) .* TAS;
            
        elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
                (strcmpi(aclass, "Piston"   ) == 1) )
            
            % lapse the SLS power
            PowerAv(:, jtrn) = PropulsionPkg.EngineLapse(PowerAv(:, jtrn), aclass, Rho);
                
        else
            
            % throw error
            error("ERROR - PowerAvailable: invalid aircraft class.");
            
        end
        
    elseif (TrnType(jtrn) == 0) % electric motor
        
        % once available, input an electric motor model here
        
    elseif (TrnType(jtrn) == 2) % fuel cell
        
        % once available, input a fuel cell model here
        
    elseif (TrnType(jtrn) == 3) % electric generator
        
        % once available, input an electric generator model here
        
    elseif (TrnType(jtrn) == 4) % cables
        
        % once available, input a cable model here
        
    else
        
        % throw an error
        error("ERROR - PowerAvailable: invalid power source type in position %d.", jtrn);
        
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

    % find all upstream transmitters and propellers
    UpTrn = find(sum(Lambda(itrn, itrn), 1) > 0 | (TrnType == 2));
    
    % assume no power available at the propellers yet (need to propagate)
    PowerAv(ipnt, UpTrn) = 0; %#ok<FNDSB>
    
    % get the initial power available
    Pav(ipnt, :) = [zeros(1, nsrc), PowerAv(ipnt, :), zeros(1, nsnk)];

    % propagate the power upstream
    Pav(ipnt, idx) = PropulsionPkg.PowerFlow(Pav(ipnt, idx)', Arch(idx, idx), Lambda(idx, idx), EtaUps(idx, idx), +1)';
    
    % check that the component is not overloaded
    Overload = Pav(ipnt, itrn) > SLSPower;
    
    % suppress component overloads
    if (any(Overload))
        
        % get the indices
        TempIdx = find(Overload);
        
        % update the power available
        Pav(ipnt, TempIdx + nsrc) = SLSPower(TempIdx);
        
        % get the sink inputs
        [TempTrn, ~] = find(Arch(:, isnk));
        
        % get a temporary index
        TempIdx = [TempTrn', isnk];
        
        % re-compute the power at the sink(s)
        Pav(ipnt, TempIdx) = PropulsionPkg.PowerFlow(Pav(ipnt, TempIdx)', Arch(TempIdx, TempIdx), Lambda(TempIdx, TempIdx), EtaUps(TempIdx, TempIdx), +1)';
        
    end
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