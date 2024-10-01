function [Map] = CreateMap_V_App(CompressorObject,PolyPsi,PolyEta)
%
%
%


%% Initialize Necesary Variables

% Design Temp and Pressure inlet
DesT = CompressorObject.States.Entry.Tt;
DesP = CompressorObject.States.Entry.Pt;

% Define number of stages
% first get fieldnames
RefStageList = fieldnames(CompressorObject.States);

% subtract one to account for the double counting of the exit (see
% EngineModelPkg.ComponentOnPkg.Compressor) and the fact that we only look
% at the entry of each of the stages (exit of last stage is not used as a
% reference
NStages = length(RefStageList)-2;


% create matrix of reference values
% 8 Columns: Eta, Phi, Psi, Zeta, Mass, Rotation, Area, Radius (in that order)
RefVal = zeros(NStages,10);

% Start at 2 because we want to extract the information ACROSS each stage
% and access the previous stage (why we go to NStages + 1)
for ii = 2:NStages+1
    CurStage = CompressorObject.States.(RefStageList{ii});
    PrevStage = CompressorObject.States.(RefStageList{ii-1});
    % want greek symbols across the stage while areas and normalized values
    % at the beginning of the stage
    RefVal(ii-1,:) = [CurStage.Eta, CurStage.Phi, CurStage.Psi, CurStage.Zeta, PrevStage.MNorm, PrevStage.NNorm, PrevStage.Area, PrevStage.Rp, CurStage.Cp, CurStage.Gam];
end



%% Create N and M meshgrids

Npnts = 100;

Rot = linspace(0,140,Npnts);

RotGrid = repmat(Rot,[Npnts,1]);

% MassGrid = zeros(Npnts);
% for ii = 1:Npnts
%     [SurgeLimit,ChokeLimit] = EngineModelPkg.MapPkg.MassFlowLimits(Rot(ii));
%     MassGrid(:,ii) = linspace(SurgeLimit,ChokeLimit,Npnts)';
% end

MassGrid = RotGrid';


% Divide the grids by 100 to change from percent to decimal
MassGrid = MassGrid./100;
RotGrid = RotGrid./100;

% Multiply the grids by their reference value to give the absolute inputs
MassGrid = MassGrid.*RefVal(1,5);
RotGrid = RotGrid.*RefVal(1,6);

%% Iterate through the grids and find the efficiency and the pressure ratio

% initialize the output grid
PR = zeros(Npnts);
Eta = zeros(Npnts);


% run through the grid values
for ii = 1:Npnts
    for jj = 1:Npnts
        [PR(ii,jj),Eta(ii,jj)] = RunThermoAnalysis(MassGrid(ii,jj),RotGrid(ii,jj),NStages,RefVal);

    end
end

%% Assign Outputs

for ii = 1:Npnts
    for jj = 1:Npnts
        if isnan(Eta(ii,jj))
        elseif Eta(ii,jj) > 1 || Eta(ii,jj) < 0
            Eta(ii,jj) = NaN;
            PR(ii,jj) = NaN;
        end

    end
end


Map.Mass = MassGrid/RefVal(1,5)*100;
Map.Rot = RotGrid/RefVal(1,6)*100;
Map.Eta = Eta;
Map.PR = PR;

%% Functions

    function [PR, Eta] = RunThermoAnalysis(initmass,initrot,NStages,RefVal)
        

        % initialize the stages
        Pressures = zeros(1,NStages)';
        Tempsreal = zeros(1,NStages)';
        Tempsideal = zeros(1,NStages)';
        MassFlows = zeros(1,NStages)';
        Rotations = zeros(1,NStages)';
        eta = zeros(1,NStages)';
        phi = zeros(1,NStages)';
        psi = zeros(1,NStages)';
%         g = zeros(1,NStages)';
%         Cp = zeros(1,NStages)';

        % R = 287 always
        RU = 8314;
        R = 287;
        PStd = 101325.353;
        TStd = 288.15;


        % First stage info is known
        MassFlows(1) = initmass;
        Rotations(1) = initrot;
        Pressures(1) = DesP;
        Tempsreal(1) = DesT;
        Tempsideal(1) = DesT;
        Cp = EngineModelPkg.SpecHeatPkg.CpAir(Tempsreal(1));
        g = Cp/(Cp-R);

        for is = 1:NStages-1
            U = Rotations(is)*sqrt(Tempsideal(is)/TStd)*RefVal(is,8)*2*pi/60;
            phi(is) = R*60/(2*pi*RefVal(is,7)*RefVal(is,8))*(MassFlows(is)*sqrt(TStd)/PStd)/(Rotations(is)/sqrt(TStd));



            phirat = phi(is)/RefVal(is,2);
            if phirat > 1.6
                PR = NaN;
                Eta = NaN;
                % compressor choked
                return;
            elseif phirat < 0.6
                PR = NaN;
                Eta = NaN;
                % compressor surge
                return;
            end
            psirat = polyval(PolyPsi,phirat);
            psi(is) = psirat*RefVal(is,3);
            etarat = polyval(PolyEta,phirat);
            eta(is) = etarat*RefVal(is,1);

            Tempsideal(is+1) = EngineModelPkg.SpecHeatPkg.NewtonRaphsonTt1(Tempsideal(is),psi(is)*U^2);
            Tempsreal(is+1) = EngineModelPkg.SpecHeatPkg.NewtonRaphsonTt1(Tempsreal(is),psi(is)*U^2/eta(is));
            Pressures(is+1) = Pressures(is)*(Tempsideal(is+1)/Tempsideal(is))^((g)/(g-1));
            MassFlows(is+1) = MassFlows(is)*Pressures(is)/Pressures(is+1)*sqrt(Tempsideal(is+1)/Tempsideal(is));
            Rotations(is+1) = Rotations(is)*sqrt(Tempsideal(is)/Tempsideal(is+1));
        end
        PR = Pressures(end)/Pressures(1);

        Eta = EngineModelPkg.SpecHeatPkg.CpAir(Tempsideal(end),Tempsideal(1))/...
            EngineModelPkg.SpecHeatPkg.CpAir(Tempsreal(end),Tempsreal(1));



    end % RunThermoAnalysis




end

