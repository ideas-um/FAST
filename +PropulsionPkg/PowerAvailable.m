function [Aircraft] = PowerAvailable(Aircraft)
%
% [Aircraft] = PowerAvailable(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 13 may 2024
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

% get the types of power sources
Eng = PSType == +1;
EM  = PSType ==  0;

% get the efficiencies
EtaTSPS = Aircraft.Specs.Propulsion.Eta.TSPS;
EtaPSPS = Aircraft.Specs.Propulsion.Eta.PSPS;

% get the propulsion architecture
UpTSPS = Aircraft.Specs.Propulsion.Upstream.TSPS;
UpPSPS = Aircraft.Specs.Propulsion.Upstream.PSPS;

% get the necessary splits
LamTS   = Aircraft.Mission.History.SI.Power.LamTS(  SegBeg:SegEnd);
LamTSPS = Aircraft.Mission.History.SI.Power.LamTSPS(SegBeg:SegEnd);
LamPSPS = Aircraft.Mission.History.SI.Power.LamPSPS(SegBeg:SegEnd);

% operation matrices
OperTS   = Aircraft.Specs.Propulsion.Oper.TS  ;
OperTSPS = Aircraft.Specs.Propulsion.Oper.TSPS;
OperPSPS = Aircraft.Specs.Propulsion.Oper.PSPS;

% get the number of thrust and power sources
[nts, nps] = size(UpTSPS);


%% COMPUTE THE POWER AVAILABLE FOR THE POWER SOURCES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% find the power available   %
% by lapsing the SLS thrust/ %
% power for engines (keep    %
% constant for the electric  %
% motors)                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% repeat this split for the number of points being assessed
ThrustAv = repmat(Aircraft.Specs.Propulsion.SLSThrust, npnt, 1);
 PowerAv = repmat(Aircraft.Specs.Propulsion.SLSPower , npnt, 1);

% check for any engines
if (any(Eng))
        
    % get power based on the aircraft class
    if      (strcmpi(aclass, "Turbofan" ) == 1)
                
        % lapse the SLS thrust
        ThrustAv(:, Eng) = PropulsionPkg.EngineLapse(ThrustAv(:, Eng), aclass, Rho);
                        
        % get the available power from the gas-turbine engines
        PowerAv(:, Eng) = ThrustAv(:, Eng) .* TAS;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )
                
        % lapse the power
        PowerAv(:, Eng) = PropulsionPkg.EngineLapse(PowerAv(:, Eng), aclass, Rho);
        
%         % size engines to get equivalent shaft power
%         for ipnt = 1:npnt
%             
%             % input the flight conditions (assume flying very slowly)
%             Aircraft.Specs.Propulsion.Engine.Mach = 0.05;
%             Aircraft.Specs.Propulsion.Engine.Alt  = Alt(ipnt);
%             
%             % lapse each engine
%             for ieng = 1:length(HasEng)
%             
%                 % input the lapsed thrust
%                 Aircraft.Specs.Propulsion.Engine.ReqPower = PowerAv(ipnt, HasEng(ieng));
%                 
%                 % design the engine
%                 SizedEngine = EngineModelPkg.TurbopropNonlinearSizing(Aircraft.Specs.Propulsion.Engine, 0);
%                 
%                 % compute the equivalent shaft power
%                 PowerAv(ipnt, HasEng(ieng)) = SizedEngine.Power + SizedEngine.JetThrust * TAS(ipnt) / Aircraft.Specs.Power.Eta.Propeller;
%                 
%             end
%         end
                
    else
        
        % throw error
        error("ERROR - PowerAvailable: invalid aircraft class.");
        
    end
end

% check for an electric motor
if (any(EM))
    
    % input electric motor model, if desired
        
end


%% CHECK WHICH COMPONENTS ARE ON/OFF %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assume a "very large" power required
Preq = repmat(1.0e+99, npnt, 1);

% allocate memory for the power required
PreqTS = zeros(npnt, nts);
PreqPS = zeros(npnt, nps);

% loop through points to get power outputs by thrust/power sources
for ipnt = 1:npnt
    
    % evaluate the function handles for the current splits
    SplitTS   = PropulsionPkg.EvalSplit(OperTS  , LamTS(  ipnt, :));
    SplitTSPS = PropulsionPkg.EvalSplit(OperTSPS, LamTSPS(ipnt, :));
    SplitPSPS = PropulsionPkg.EvalSplit(OperPSPS, LamPSPS(ipnt, :));
    
    % get the power output by the thrust sources
    PreqTS(ipnt, :) = Preq(ipnt) * SplitTS;
    
    % get the power output by the driven  power sources
    PreqPS(ipnt, :) = PreqTS(ipnt, :) * (SplitTSPS ./ EtaTSPS);
    
    % get the power output by the driving power sources
    PreqPS(ipnt, :) = PreqPS(ipnt, :) * (SplitPSPS ./ EtaPSPS);
       
end

% check if the power required exceeds the power available
irow = find(PreqPS > PowerAv);

% if power required exceeds the power available, set power available
if (any(irow))
    PreqPS(irow) = PowerAv(irow);
end

% set the required power as the available power
PowerAv = PreqPS;

% compute the thrust available
ThrustAv = PowerAv ./ TAS;

% remember the thrust and power available for the power sources
Aircraft.Mission.History.SI.Power.Pav_PS(SegBeg:SegEnd, :) = PowerAv ;
Aircraft.Mission.History.SI.Power.Tav_PS(SegBeg:SegEnd, :) = ThrustAv;


%% COMPUTE THE POWER AVAILABLE AT THE THRUST SOURCES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% propagate the power available forward along the powertrain
PowerTS = PowerAv * (UpPSPS .* EtaPSPS)' * (UpTSPS .* EtaTSPS)';

% convert the power available to thrust available
ThrustTS = PowerTS ./ TAS;

% remember the thrust and power available for the power sources
Aircraft.Mission.History.SI.Power.Pav_TS(SegBeg:SegEnd, :) = PowerTS ;
Aircraft.Mission.History.SI.Power.Tav_TS(SegBeg:SegEnd, :) = ThrustTS;


%% COMPUTE THE TOTAL POWER AVAILABLE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% consolidate into a scalar value
Power = PowerTS * ones(nts, 1);

% remember the power available (as a scalar)
Aircraft.Mission.History.SI.Power.TV(SegBeg:SegEnd) = Power;

% ----------------------------------------------------------

end