function [OffDesign] = TurbofanOffDesignDriver(OnDesignEngine,OffParams)

% DEFUNCT DO NOT USE THIS


%% Compute Off Design Efficiencies

% EtaPoly = EtaPoly * reduction factor

%% Find OnDesignScaleFactor

BSFCScale = OnDesignEngine.OffDesignEngine.ODScale;
BSFCon = OnDesignEngine.OffDesignEngine.BSFC*BSFCScale;



%% Run Off Design

OffDesign = EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle2(OnDesignEngine,OffParams);
BSFCoff = OffDesign.BSFC;

ThrustScale = OnDesignEngine.OffDesignEngine.ThrustScale;



%% Output

OffDesign.TSFC = BSFCoff*BSFCScale/BSFCon*OnDesignEngine.TSFC_Imperial;
% OffDesign.Thrust.Net = ThrustScale.*OffDesign.Thrust.Net;
% OffDesign.TSFC = OffDesign.TSFC_Imperial/ThrustScale; 

%% Output BSFC In off Design

end

