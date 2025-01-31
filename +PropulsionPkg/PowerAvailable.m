function [Aircraft] = PowerAvailable(Aircraft)
%
% [Aircraft] = PowerAvailable(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 04 sep 2024
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
TAS  = Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd);
Rho  = Aircraft.Mission.History.SI.Performance.Rho( SegBeg:SegEnd);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get information about the  %
% configuration and mission  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% aircraft class
aclass = Aircraft.Specs.TLAR.Class;

% get the power source types
PSType = Aircraft.Specs.Propulsion.PropArch.PSType;

% get the number of control points in the segment
npnt = length(TAS);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get information about the  %
% power sources in the arch. %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the efficiencies
EtaTSPS = Aircraft.Specs.Propulsion.Eta.TSPS;
EtaPSPS = Aircraft.Specs.Propulsion.Eta.PSPS;
EtaPSES = Aircraft.Specs.Propulsion.Eta.PSES;

% get the propulsion architecture
TSPS = Aircraft.Specs.Propulsion.PropArch.TSPS;
PSPS = Aircraft.Specs.Propulsion.PropArch.PSPS;
PSES = Aircraft.Specs.Propulsion.PropArch.PSES;

% get the necessary splits
LamTS   = Aircraft.Mission.History.SI.Power.LamTS(  SegBeg:SegEnd);
LamTSPS = Aircraft.Mission.History.SI.Power.LamTSPS(SegBeg:SegEnd);
LamPSPS = Aircraft.Mission.History.SI.Power.LamPSPS(SegBeg:SegEnd);
LamPSES = Aircraft.Mission.History.SI.Power.LamPSES(SegBeg:SegEnd);

% operation matrices
OperTS   = Aircraft.Specs.Propulsion.Oper.TS  ;
OperTSPS = Aircraft.Specs.Propulsion.Oper.TSPS;
OperPSPS = Aircraft.Specs.Propulsion.Oper.PSPS;
OperPSES = Aircraft.Specs.Propulsion.Oper.PSES;

% get the number of thrust and power sources
[nts, nps] = size(TSPS);
[~  , nes] = size(PSES);


%% COMPUTE THE POWER AVAILABLE FOR THE POWER SOURCES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the SLS thrust available in each power source
ThrustAv = repmat(Aircraft.Specs.Propulsion.SLSThrust, npnt, 1);
 PowerAv = repmat(Aircraft.Specs.Propulsion.SLSPower , npnt, 1);
 
% loop through all power sources
for ips = 1:nps
    
    % check for the proper power source
    if     (PSType(ips) == 1) % engine
        
        % get the thrust/power available based on the aircraft class
        if      (strcmpi(aclass, "Turbofan" ) == 1)
                
            % lapse the SLS thrust
            ThrustAv(:, ips) = PropulsionPkg.EngineLapse(ThrustAv(:, ips), aclass, Rho);
            
            % get the available power from the gas-turbine engines
            PowerAv(:, ips) = ThrustAv(:, ips) .* TAS;
            
        elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
                (strcmpi(aclass, "Piston"   ) == 1) )
            
            % lapse the SLS power
            PowerAv(:, ips) = PropulsionPkg.EngineLapse(PowerAv(:, ips), aclass, Rho);
                
        else
            
            % throw error
            error("ERROR - PowerAvailable: invalid aircraft class.");
            
        end
        
    elseif (PSType(ips) == 0) % electric motor
        Pav = Aircraft.Specs.Weight.EM/2 * 10^3;
        PC_EM = Aircraft.Mission.History.SI.Power.PC(SegBeg:SegEnd, [3,4]);
        PowerAv(:,[3,4]) = PC_EM.*repmat(Pav, npnt, 2);
        
        % once available, input an electric motor model here
        
    elseif (PSType(ips) == 2) % fuel cell
        
        % once available, input a fuel cell model here
        
    else
        
        % throw an error
        error("ERROR - PowerAvailable: invalid power source type in position %d.", ips);
        
    end
end


%% CHECK WHICH COMPONENTS ARE ON/OFF %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assume a "very large" pseudo power required
Preq = repmat(1.0e+99, npnt, 1);

% allocate memory for the power required
PreqTS    = zeros(npnt, nts);
PreqPSUps = zeros(npnt, nps);
PreqPSDwn = zeros(npnt, nps);
PreqES    = zeros(npnt, nes);

% loop through points to get power outputs by thrust/power sources
for ipnt = 1:npnt
    
    % evaluate the function handles for the current splits
    SplitTS   = PropulsionPkg.EvalSplit(OperTS  , LamTS(  ipnt, :));
    SplitTSPS = PropulsionPkg.EvalSplit(OperTSPS, LamTSPS(ipnt, :));
    SplitPSPS = PropulsionPkg.EvalSplit(OperPSPS, LamPSPS(ipnt, :));
    SplitPSES = PropulsionPkg.EvalSplit(OperPSES, LamPSES(ipnt, :));
    
    % get the power output by the thrust sources
    PreqTS(   ipnt, :) = Preq(     ipnt   ) *  SplitTS              ;
    
    % get the power output by the (upstream) driven  power sources
    PreqPSUps(ipnt, :) = PreqTS(   ipnt, :) * (SplitTSPS ./ EtaTSPS);
          
    % get the power output by the (downstream) driving power sources
    PreqPSDwn(ipnt, :) = PreqPSUps(ipnt, :) * (SplitPSPS ./ EtaPSPS);
               
    % get the power output by the energy sources
    PreqES(   ipnt, :) = PreqPSDwn(ipnt, :) * (SplitPSES ./ EtaPSES);
    
end

% assume the pseudo power required from the upstream PS is the power available
PavPSUps = PreqPSUps;

% check if the power required exceeds the power available
irow = find(PavPSUps > PowerAv);

% if power required exceeds the power available, set power available
if (any(irow))
    PavPSUps(irow) = PowerAv(irow);
end

% allocate memory for the power required
PtempPSDwn = zeros(npnt, nps);

% loop through points to get power outputs by all power sources
for ipnt = 1:npnt
    
    % evaluate the function handles for the current splits
    SplitPSPS = PropulsionPkg.EvalSplit(OperPSPS, LamPSPS(ipnt, :));
              
    % get the power output by the (downstream) driving power sources
    PtempPSDwn(ipnt, :) = PavPSUps(ipnt, :) * (SplitPSPS ./ EtaPSPS);
    
end

% assume the pseudo power required is the power available
PavPSDwn = PtempPSDwn;

% check if the power required exceeds the power available
irow = find(PavPSDwn > PowerAv);

% if power required exceeds the power available, set power available
if (any(irow))
    PavPSDwn(irow) = PowerAv(irow);
end

% set the component-based required power as the available power
PowerAv = PavPSDwn;

% compute the component-based thrust available
ThrustAv = PowerAv ./ TAS;

% allocate memory for the actual energy source power required
PactES = zeros(npnt, nes);

% now that the power has been limited, compute the ES power required
for ipnt = 1:npnt
    
    % evaluate the function handle for the current split
    SplitPSES = PropulsionPkg.EvalSplit(OperPSES, LamPSES(ipnt, :));
    
    % compute the power required by the energy sources
    PactES(ipnt, :) = PavPSDwn(ipnt, :) * (SplitPSES ./ EtaPSES);
    
end


%% COMPUTE THE TOTAL POWER AVAILABLE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% allocate memory for the available thrust source power
PowerTS = zeros(npnt, nts);

% loop through points to get power outputs by thrust/power sources
for ipnt = 1:npnt
    
    % evaluate the function handles for the current splits
    SplitTSPS = PropulsionPkg.EvalSplit(OperTSPS, LamTSPS(ipnt, :));
    SplitPSPS = PropulsionPkg.EvalSplit(OperPSPS, LamPSPS(ipnt, :));
    SplitPSES = PropulsionPkg.EvalSplit(OperPSES, LamPSES(ipnt, :));
    
    % compute the upstream power-power splits
    UpTSPS = PropulsionPkg.UpstreamSplit(PreqTS(   ipnt, :), PreqPSDwn(ipnt, :), TSPS, SplitTSPS, EtaTSPS, 0);
    UpPSPS = PropulsionPkg.UpstreamSplit(PreqPSUps(ipnt, :), PreqPSDwn(ipnt, :), PSPS, SplitPSPS, EtaPSPS, 1);
    UpPSES = PropulsionPkg.UpstreamSplit(PreqPSDwn(ipnt, :), PreqES(   ipnt, :), PSES, SplitPSES, EtaPSES, 0);
    
    % propagate the power available from the energy sources to driving PS
    DrivingPower = PactES(ipnt, :) * (UpPSES .* EtaPSES)';
    
    % propagate the power available from the driving PS to the driven PS
    DrivenPower  = DrivingPower    * (UpPSPS .* EtaPSPS)';
    
    % propagate the power from driven PS to the TS
    PowerTS(ipnt, :) = DrivenPower * (UpTSPS .* EtaTSPS)';
           
end

% convert the power available to thrust available
ThrustTS = PowerTS ./ TAS;

% consolidate power from thrust sources into a scalar value
TVPower = PowerTS * ones(nts, 1);

%% HARD CODING POWER AVAILABLE FOR EM w/ PC %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if Aircraft.Specs.Power.LamTSPS.SLS ~= 0
    Pav = Aircraft.Specs.Weight.EM/2 * 10^3;
    PC_EM = Aircraft.Mission.History.SI.Power.PC(SegBeg:SegEnd, [3,4]);
    PowerAv(:,[3,4]) = PC_EM.*repmat(Pav, npnt, 2);
end


%% STORE OUTPUTS IN THE AIRCRAFT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the thrust and power available for the power sources
Aircraft.Mission.History.SI.Power.Pav_PS(SegBeg:SegEnd, :) = PowerAv ;
Aircraft.Mission.History.SI.Power.Tav_PS(SegBeg:SegEnd, :) = ThrustAv;

% remember the thrust and power available for the power sources
Aircraft.Mission.History.SI.Power.Pav_TS(SegBeg:SegEnd, :) = PowerTS ;
Aircraft.Mission.History.SI.Power.Tav_TS(SegBeg:SegEnd, :) = ThrustTS;

% remember the power available (as a scalar)
Aircraft.Mission.History.SI.Power.TV(SegBeg:SegEnd) = TVPower;

% ----------------------------------------------------------

end