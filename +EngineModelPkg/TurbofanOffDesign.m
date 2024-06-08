function [OffOutputs] = TurbofanOffDesign(OnDesignEngine,OffParams)
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





% New maxT model needed
[~,~,RhoH] = MissionSegsPkg.StdAtm(OffParams.FlightCon.Alt);
[~,~,RhoSL] = MissionSegsPkg.StdAtm(OnDesignEngine.Specs.Alt);

mexp = 1;
DesT = OnDesignEngine.Thrust.Net;
MaxT = (RhoH/RhoSL)^mexp*DesT;

%MaxT = MaxT - OffParams.FlightCon.Mach*sqrt(1.4*287*TH)*(RhoH/RhoSL)*OnDesignEngine.MDotAir;

Thrusts = OnDesignEngine.OffDesignMap.Thrusts;
BSFCs = OnDesignEngine.OffDesignMap.BSFCs;

if isstring(OffParams.Thrust) || ischar(OffParams.Thrust)

    OffParams.Thrust = max(Thrusts);
    OutThrust = max(Thrusts)*MaxT;
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




%% Assign Outputs
OffOutputs.Fuel = OutMDot;
OffOutputs.Thrust = OutThrust;
OffOutputs.TSFC = OutTSFC;
OffOutputs.TSFC_Imperial = UnitConversionPkg.ConvTSFC(OutTSFC,'SI','Imp');

end

