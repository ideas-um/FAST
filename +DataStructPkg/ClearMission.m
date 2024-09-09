function [Aircraft] = ClearMission(Aircraft, ielem)
%
% [Aircraft] = ClearMission(Aircraft, ielem)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 11 jun 2024
%
% Reset all of the information from the Aircraft.Mission.History.SI.*
% sub-structure to 0s. This is needed each time a mission is re-flown.
%
% INPUTS:
%     Aircraft - structure with the mission history to be cleared.
%                size/type/units: 1-by-1 / struct / []
%
%     ielem    - (optional argument) index to start clearing the mission
%                history at, either:
%                    a)  0: clear all (the default argument)
%                    b) >0: clear only ielem:end
%                size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     Aircraft - structure with the mission history cleared.
%                size/type/units: 1-by-1 / struct / []
%


%% SETUP %%
%%%%%%%%%%%

% if no second argument, clear all indices
if (nargin < 2)
    ielem = 0;
end


%% CLEAR THE ARRAYS %%
%%%%%%%%%%%%%%%%%%%%%%

% check what data should be cleared
if (ielem == 0)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % clear all data             %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    % aircraft performance data
    Aircraft.Mission.History.SI.Performance.Time(:, :) = 0;
    Aircraft.Mission.History.SI.Performance.Dist(:, :) = 0;
    Aircraft.Mission.History.SI.Performance.TAS( :, :) = 0;
    Aircraft.Mission.History.SI.Performance.EAS( :, :) = 0;
    Aircraft.Mission.History.SI.Performance.RC(  :, :) = 0;
    %Aircraft.Mission.History.SI.Performance.Alt( :, :) = 0;
    Aircraft.Mission.History.SI.Performance.Acc( :, :) = 0;
    Aircraft.Mission.History.SI.Performance.FPA( :, :) = 0;
    Aircraft.Mission.History.SI.Performance.Mach(:, :) = 0;
    Aircraft.Mission.History.SI.Performance.Rho( :, :) = 0;
    Aircraft.Mission.History.SI.Performance.Ps(  :, :) = 0;
    
    % propulsion data
    Aircraft.Mission.History.SI.Propulsion.TSFC(    :, :) = 0;
    Aircraft.Mission.History.SI.Propulsion.MDotFuel(:, :) = 0;
    Aircraft.Mission.History.SI.Propulsion.MDotAir( :, :) = 0;
    Aircraft.Mission.History.SI.Propulsion.FanDiam( :, :) = 0;
    Aircraft.Mission.History.SI.Propulsion.ExitMach(:, :) = 0;
    
    % aircraft weights as a function of time
    Aircraft.Mission.History.SI.Weight.CurWeight(:, :) = 0;
    Aircraft.Mission.History.SI.Weight.Fburn(    :, :) = 0;
    
    % aircraft power as a function of time
    Aircraft.Mission.History.SI.Power.TV(     :, :) = 0;
    Aircraft.Mission.History.SI.Power.Req(    :, :) = 0;
    %Aircraft.Mission.History.SI.Power.LamTS(  :, :) = 0; %dont clear power
    %split
    %Aircraft.Mission.History.SI.Power.LamTSPS(:, :) = 0;
    %Aircraft.Mission.History.SI.Power.LamPSPS(:, :) = 0;
    %Aircraft.Mission.History.SI.Power.LamPSES(:, :) = 0;
    Aircraft.Mission.History.SI.Power.SOC(    :, :) = 0;
    Aircraft.Mission.History.SI.Power.Pav_TS( :, :) = 0;
    Aircraft.Mission.History.SI.Power.Pav_PS( :, :) = 0;
    Aircraft.Mission.History.SI.Power.Preq_TS(:, :) = 0;
    Aircraft.Mission.History.SI.Power.Preq_PS(:, :) = 0;
    Aircraft.Mission.History.SI.Power.Tav_TS( :, :) = 0;
    Aircraft.Mission.History.SI.Power.Tav_PS( :, :) = 0;
    Aircraft.Mission.History.SI.Power.Treq_TS(:, :) = 0;
    Aircraft.Mission.History.SI.Power.Treq_PS(:, :) = 0;
    Aircraft.Mission.History.SI.Power.Pout_TS(:, :) = 0;
    Aircraft.Mission.History.SI.Power.Tout_TS(:, :) = 0;
    Aircraft.Mission.History.SI.Power.Pout_PS(:, :) = 0;
    Aircraft.Mission.History.SI.Power.Tout_PS(:, :) = 0;
    Aircraft.Mission.History.SI.Power.P_ES(   :, :) = 0;
    
    % aircraft energy as a function of time
    Aircraft.Mission.History.SI.Energy.KE(      :, :) = 0;
    Aircraft.Mission.History.SI.Energy.PE(      :, :) = 0;
    Aircraft.Mission.History.SI.Energy.E_ES(    :, :) = 0;
    Aircraft.Mission.History.SI.Energy.Eleft_ES(:, :) = 0;
    
    % segments flown as a function of time
    Aircraft.Mission.History.Segment(:, :) = "";
    
else

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % clear indices ielem:end    %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % aircraft performance data
    Aircraft.Mission.History.SI.Performance.Time(ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Performance.Dist(ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Performance.TAS( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Performance.EAS( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Performance.RC(  ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Performance.Alt( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Performance.Acc( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Performance.FPA( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Performance.Mach(ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Performance.Rho( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Performance.Ps(  ielem:end, :) = 0;
    
    % propulsion data
    Aircraft.Mission.History.SI.Propulsion.TSFC(    ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Propulsion.MDotFuel(ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Propulsion.MDotAir( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Propulsion.FanDiam( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Propulsion.ExitMach(ielem:end, :) = 0;    
    
    % aircraft weights as a function of time
    Aircraft.Mission.History.SI.Weight.CurWeight(ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Weight.Fburn(    ielem:end, :) = 0;
    
    % aircraft power as a function of time
    Aircraft.Mission.History.SI.Power.TV(      ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Req(     ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.LamTS(   ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.LamTSPS( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.LamPSPS( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.LamPSES( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.SOC(     ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Pav_TS(  ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Pav_PS(  ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Preq_TS( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Preq_PS( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Tav_TS(  ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Tav_PS(  ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Treq_TS( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Treq_PS( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Pout_TS( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Tout_TS( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Pout_PS( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Tout_PS( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.P_ES(    ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Voltage( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Current( ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Power.Capacity(ielem:end, :) = 0;
    
    % aircraft energy as a function of time
    Aircraft.Mission.History.SI.Energy.KE(      ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Energy.PE(      ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Energy.E_ES(    ielem:end, :) = 0;
    Aircraft.Mission.History.SI.Energy.Eleft_ES(ielem:end, :) = 0;
    
    % segments flown as a function of time
    Aircraft.Mission.History.Segment(ielem:end, :) = "";
    
end

% ----------------------------------------------------------

end