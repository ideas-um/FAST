function [OffDesign] = TurbofanOffDesignDriver(OnDesignEngine,OffParams)


%% Compute Off Design Efficiencies

% EtaPoly = EtaPoly * reduction factor

%% Find OnDesignScaleFactor

BSFCScale = OnDesignEngine.OffDesignEngine.ODScale;
BSFCon = OnDesignEngine.OffDesignEngine.BSFC*BSFCScale;

%% Run Off Design

OffDesign = EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle2(OnDesignEngine,OffParams);
BSFCoff = OffDesign.BSFC;

%% Output

OffDesign.TSFC = BSFCoff*BSFCScale/BSFCon*OnDesignEngine.TSFC_Imperial;


%% Output BSFC In off Design

end

