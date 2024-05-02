function [State3,CompressorObject] = Compressor(State21,CPR,CompRPM,EtaPoly)
%
% [State3,CompressorObject] = Compressor(State21,CPR,CompRPM,EtaPoly)
% Written by Maxfield Arnson, marnson@umich.edu
% Updated 10/3/2023
%
% This function computes the change in the airflow properties across a
% compressor. It outputs the new state and a compressor object describing
% the properties of the machinery compressing the air.
%
%
% INPUTS:
%
% State21 = Flow state coming into the compressor. Usually post fan, engine
%           core airflow. 
%       size: 1x1 struct
%
% CPR = Compressor pressure ratio. Multiplier of input total
%           pressure that will yield desired output pressure
%       size: scalar double
%
% CompRPM = Revolutions per minute this compressor spins at.
%       size: scalar double
%
% EtaPoly = structure containing various efficiencies for the engine.
%           The compressor and its child functions use EtaPoly.Compressors
%       size: 1x1 struct
%
%
% OUTPUTS:
%
% State3 = flow state post compression. Mimics the format of the inputted
%           state.
%       size: 1x1 struct
%
% CompressorObject = structure describing required work, compressor ratios, 
%           RPM, number of stages, etc. 
%           Also stores flow states between compressor stages
%       size: 1x1 struct


%% Initialize
R = 287;
RU = 8314;

CurState = State21;

PStd = 101325.353;
TStd = 288.15;

% Map Variables
CurState.Rp     = (CurState.Ro+CurState.Ri)/2;
w               = CompRPM/60*2*pi;
CurState.Eta    = NaN; % not used
CurState.Psi    = NaN; % not used
CurState.MNorm  = CurState.MDot*sqrt(CurState.Ts/TStd)/(CurState.Ps/PStd);  
CurState.NNorm  = CompRPM/sqrt(CurState.Ts/TStd);
CurState.Phi    = R*60/(2*pi*CurState.Area*CurState.Rp)*(CurState.MNorm*sqrt(TStd)/PStd)/(CurState.NNorm/sqrt(TStd));
CurState.Zeta   = CurState.Psi/CurState.Eta;

% initialize entry
CompressorObject.States.Entry = CurState;

%% Find RPM by limiting tip relative Mach Number to 0.9; (Defunct)
% aE = sqrt(EngineModelPkg.IsenRelPkg.Ts_Tt(State21.Tt,State21.Mach,State21.Gam)...
%     *R*State21.Gam);
% V1E = State21.Mach*aE;
% V1RelE = 0.9*aE;
% 
% wrE = sqrt(V1RelE^2-V1E^2);
% 
% CompRPM = wrE./State21.Ro*60/2/pi;

%% Loop through stages

Fan = false;
CurPi = 1;
i = 1;
while CurPi < CPR
    if CPR/CurPi > sqrt(2)
        StagePR = sqrt(2);
    else
        StagePR = CPR/CurPi;
    end
    Pi(i) = StagePR;
    [CurState,StageWork(i),Tau(i)] = ...
        EngineModelPkg.ComponentOnPkg.CompStg(CurState,EtaPoly,StagePR,CompRPM,Fan);
    CurPi = cumprod(Pi); CurPi = CurPi(end);
    
    CompressorObject.States.("Stage_" + i) = CurState;
    
loading = CurState.Cp*(CurState.Tt*(Tau(i)-1))/(CompRPM/60*2*pi*0.5*(CurState.Ro+CurState.Ri))^2;

% if Pi(i) > 1.5
%     warning('Stage Pressure Ratio in excess of 1.5')
%     Pi(i);
% end
i = i+1;
end

NStages = i-1;
CompressorObject.States.Exit = CompressorObject.States.("Stage_" + NStages);

PiComp = CurPi;
TauComp = cumprod(Tau); TauComp = TauComp(end);
CompWork = cumsum(StageWork); CompWork = CompWork(end);


%% Remove map fields from output state
State3 = CompressorObject.States.Exit;
State3 = rmfield(State3,["Zeta","Eta","Psi","Phi","MNorm","Rp","NNorm"]);

%% Calculate adiabatic Efficiency

T3_ideal = State21.Tt*CPR^((State21.Gam-1)/State21.Gam);
H3_ideal = T3_ideal*EngineModelPkg.SpecHeatPkg.CpAir(T3_ideal);
H3 = State3.Tt*EngineModelPkg.SpecHeatPkg.CpAir(State3.Tt);
H2 = State21.Tt*EngineModelPkg.SpecHeatPkg.CpAir(State21.Tt);

CompressorObject.AdiabaticEfficiency = EtaPoly.Compressors; %(H3_ideal - H2)/(H3-H2);


%% Define Outputs

CompressorObject.NoStages = NStages;
CompressorObject.Pi = PiComp;
CompressorObject.Tau = TauComp;
CompressorObject.ReqWork = CompWork;
CompressorObject.RPM = CompRPM;




end