function [OffDesignInfo] = TF_OD_MapMaker(OnDesignEngine)
% Turbofan Off-Design Map Maker



OffParams.FlightCon.Mach = OnDesignEngine.Specs.Mach;
OffParams.FlightCon.Alt = OnDesignEngine.Specs.Alt;
OffParams.PC = 0.1;

%pcLower = findlower(OnDesignEngine,OffParams,0.1);
pcLower = 0.6;

N = 40;
PC = linspace(pcLower,1.1,N);

Thrusts = zeros(1,N);
BSFCs = zeros(1,N);

for ii = 1:length(PC)

    OffParams.PC = PC(ii);
    OffEngine = EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle2(OnDesignEngine,OffParams);
    Thrusts(ii) = OffEngine.Thrust.Net;
    BSFCs(ii) = OffEngine.BSFC;

end


OffParams.PC = 1;
OffEngine = EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle2(OnDesignEngine,OffParams);
ThrustBaseline = OffEngine.Thrust.Net;
BSFCBaseline = OffEngine.BSFC;

OffDesignInfo.Thrusts = smoothdata(Thrusts./ThrustBaseline);
OffDesignInfo.BSFCs = smoothdata(BSFCs./BSFCBaseline);





end



function [lower] = findlower(OnDesignEngine,OffParams,lower)

lower = lower + 0.01;

PC = linspace(lower,1.1);

try
    for ii = 1:length(PC)
        OffParams.PC = PC(ii);
        EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle2(OnDesignEngine,OffParams);
    end
catch
    lower = findlower(OnDesignEngine,OffParams,lower);
end


end

