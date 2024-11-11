function [OffOutputs] = TurbofanOffDesign(OnDesignEngine,OffParams,ElectricLoad)
% Use this one. others dont work
% OnDesignEngine is just the sized engine structure which is output from
% the functinon TurbofanNonlienarSizing. OffParams is a structur with the
% following fields:
%
% OffParams.FlightCon.Mach = Mach Number at which you want to evaluate
%   engine performance
% OffParams.FlightCon.Alt = altitude at which you want to evaluate engine
%   performance. This should be in [meters]
% OffParams.Thrust = thrust in Newtons you would like the engine to
% produce. if you want maximum thrust set this variable not to a value but
% to OffParams.Thrust = "maximum" (not case sensitive)
% Electric load is a parameter in Watts which tells the engine how much
% electric power the engine receives from a generator (positive
% ElectricLoad) or how much additional electric power the LPT needs to
% produce (negative ElectricLoad)
%
% Output is a structure containing 4 fields: Fuel [kg/s], Thrust [N], TSFC
% [kg/N/s], and TSFC_Imperial [lbm/lbf/hr]
% in all cases where thrust was not set to "maximum", thrust will be equal
% to what was input in OffParams.Thrust. In the case it was set to Maximum,
% this will be useful, like for takeoff. Limit maximum thrust output to 5
% minutes of continuous use.



%% Find Maximum Thrust At Current Condition

% MaxParams.FlightCon = OffParams.FlightCon;
% MaxParams.PC = 1;
%
% OnParams.FlightCon.Alt = OnDesignEngine.Specs.Alt;
% OnParams.FlightCon.Mach = OnDesignEngine.Specs.Mach;
% OnParams.PC = 1;

%MaxT_Engine = EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle2(OnDesignEngine,MaxParams);
% OnOffDesign = EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle2(OnDesignEngine,OnParams);


% MaxT = MaxT_Engine.Thrust.Net*OnOffDesign.ThrustScale;

[~,~,RhoH] = MissionSegsPkg.StdAtm(OffParams.FlightCon.Alt);
[~,~,RhoSL] = MissionSegsPkg.StdAtm(OnDesignEngine.Specs.Alt);

mexp = 1;
AltScale = @(parameter) (RhoH/RhoSL)^mexp*parameter;
DesT = OnDesignEngine.Thrust.Net;
MaxT = AltScale(DesT);

if nargin == 2 || ElectricLoad == 0

        % New maxT model needed





        %MaxT = MaxT - OffParams.FlightCon.Mach*sqrt(1.4*287*TH)*(RhoH/RhoSL)*OnDesignEngine.MDotAir;

        Thrusts = OnDesignEngine.OffDesignMap.Thrusts;
        BSFCs = OnDesignEngine.OffDesignMap.BSFCs;

        if isstring(OffParams.Thrust) || ischar(OffParams.Thrust)

            OffParams.Thrust = max(Thrusts);
            OutThrust = max(Thrusts)*MaxT;
        elseif OffParams.Thrust <= 2
%             OffParams.Thrust = max(Thrusts);
            OutThrust = OffParams.Thrust*MaxT;            

        else
            OutThrust = OffParams.Thrust;
            OffParams.Thrust = OffParams.Thrust/MaxT;


        end

        OnAtAltSpecs = OnDesignEngine.Specs;
        OnAtAltSpecs.Alt = OffParams.FlightCon.Alt;
        OnAtAltSpecs.Mach = OffParams.FlightCon.Mach;
        OnAtAltSpecs.DesignThrust = MaxT;
        OnAtAltSpecs.Sizing = 0;
        OnDesignAtAlt = EngineModelPkg.TurbofanNonlinearSizing(OnAtAltSpecs);


        if OffParams.Thrust > max(Thrusts)
            OffParams.Thrust = max(Thrusts);
            % or return an error
        elseif OffParams.Thrust < min(Thrusts)
            OffParams.Thrust = min(Thrusts);
            % or return an error
        end

        TSFCSCale = interp1(Thrusts,BSFCs,OffParams.Thrust);


        OutTSFC = OnDesignAtAlt.TSFC*TSFCSCale;
        OutMDot = OutTSFC*OutThrust;

        % MDotFuel = OnDesignFuel*    interp1(Thrusts,BSFCs,OffParams.Thrust);






else

        Thrust_Data = OnDesignEngine.OffDesignMap.Thrusts';
        BSFC_Data = OnDesignEngine.OffDesignMap.BSFCs';
        Power_Data = OnDesignEngine.OffDesignMap.OutputPower';

        % if max thrust change it to a number
        if isstring(OffParams.Thrust) || ischar(OffParams.Thrust)
            OffParams.Thrust = max(Thrust_Data)*MaxT;
        end


        % find maximum power that the gas turbine can produce
        % scale design power required by compressor using altitude method

        if (OnDesignEngine.FanSysObject.ElecWork <= 0)

%             case -1
                DesP = OnDesignEngine.FanSysObject.ReqWork;
                MaxP = AltScale(DesP);
                
        else
%             case +1
                DesP = OnDesignEngine.FanSysObject.TotalWork;
                MaxP = AltScale(DesP) - OnDesignEngine.FanSysObject.ElecWork;
        end

        % Find requested GT power by subtracting electric power from thrust
        % power

        % find thrust power
        Thrust2Power = @(thrust) thrust*(OnDesignEngine.FanSysObject.TotalWork/OnDesignEngine.Thrust.Net);
        ThrustP = Thrust2Power(OffParams.Thrust);

        % Find Required GT Power
        ReqGTP = ThrustP - ElectricLoad;

        % if Required gas turbine power is 0 or negative, no fuel
        % consumption
        if ReqGTP <= 0
            OffOutputs.Fuel = 0;
            OffOutputs.Thrust = OffParams.Thrust;
            OffOutputs.TSFC = 0;
            OffOutputs.TSFC_Imperial = 0;
            return
        end

        % Power Ratio Calculation Relative to Maximum Power
        PowRat = ReqGTP/MaxP;

        if     (PowRat > max(Power_Data))
            PowRat = max(Power_Data);
            
        elseif (PowRat < min(Power_Data))
            PowRat = min(Power_Data);
            
        end
            
%         if PowRat > 1.2*max(Power_Data)
%            error('Power Requested Exceeds Gas Turbine Capability')
%            PowRat = max(Power_Data);
%         elseif PowRat > max(Power_Data)
%             PowRat = max(Power_Data);
%             % or return an error
%         elseif PowRat < min(Power_Data)
%             PowRat = min(Power_Data);
%         end

        % interpolate the BSFC scale
        BSFCScale = interp1(Power_Data,BSFC_Data,PowRat);

        % Find on Design TSFC
        OnAtAltSpecs = OnDesignEngine.Specs;
        OnAtAltSpecs.Alt = OffParams.FlightCon.Alt;
        OnAtAltSpecs.Mach = OffParams.FlightCon.Mach;
        OnAtAltSpecs.DesignThrust = MaxT;
        OnAtAltSpecs.Sizing = 0;
        OnDesignAtAlt = EngineModelPkg.TurbofanNonlinearSizing(OnAtAltSpecs,OnDesignEngine.FanSysObject.ElecWork);

        DesFuel = OnDesignAtAlt.Fuel.MDot;
        DesTSFC = OnDesignAtAlt.TSFC;
        DesBSFC = DesFuel/OnDesignAtAlt.FanSysObject.ReqWork;

        OutBSFC = DesBSFC*BSFCScale;
        OutMDot = OutBSFC*ReqGTP;
        OutThrust = OffParams.Thrust;
        OutTSFC = OutMDot/OutThrust;


        % find
end



%% Assign Outputs
OffOutputs.Fuel = OutMDot;
OffOutputs.Thrust = OutThrust;
OffOutputs.TSFC = OutTSFC;
OffOutputs.TSFC_Imperial = UnitConversionPkg.ConvTSFC(OutTSFC,'SI','Imp');

end

