clc; clear;

%% A320Neo Testing ; A320()
% call main
A320Neo = Main(AircraftSpecsPkg.A320Neo(), @MissionProfilesPkg.A320)

% collect variables of interest
Weights_A320 = A320Neo.Specs.Weight;
Slits_Up_A320 = A320Neo.Mission.History.SI.Power.LamUps;
% DesignStrat_A320 = A320Neo.Specs.Propulsion.DesignStrategy;
% NumStrat_A320 = A320Neo.Specs.Propulsion.NumStrats;

%% LM100J_Hybrid Testing ; LM100J()
% call main
LMhybrid = Main(AircraftSpecsPkg.LM100J_Hybrid(), @MissionProfilesPkg.LM100J)

% collect variables of interest
Weights_LMH = LMhybrid.Specs.Weight;
Slits_Up_LMH = LMhybrid.Mission.History.SI.Power.LamUps;
% DesignStrat_LMH = LMhybrid.Specs.Propulsion.DesignStrategy;
% NumStrat_LMH = LMhybrid.Specs.Propulsion.NumStrats;

%% AEA Testing ; AEAProfile()
% call main
AEA = Main(AircraftSpecsPkg.AEA(), @MissionProfilesPkg.AEAProfile)

% collect variables of interest
Weights_AEA = AEA.Specs.Weight;
Slits_Up_AEA = AEA.Mission.History.SI.Power.LamUps;
% DesignStrat_AEA = AEA.Specs.Propulsion.DesignStrategy;
% NumStrat_AEA = AEA.Specs.Propulsion.NumStrats;


%% ATR42 Testing ; ATR42_600()
% call main
ATR = Main(AircraftSpecsPkg.ATR42(), @MissionProfilesPkg.ATR42_600)

% collect variables of interest
Weights_ATR = ATR.Specs.Weight;
Slits_Up_ATR = ATR.Mission.History.SI.Power.LamUps;
% DesignStrat_ATR = ATR.Specs.Propulsion.DesignStrategy;
% NumStrat_ATR = ATR.Specs.Propulsion.NumStrats;

% %% ATR42 Testing ; ATR42MissionBRE()
% % call main
% ATR_BRE = Main(AircraftSpecsPkg.ATR42(), @MissionProfilesPkg.ATRMissionBRE)
% 
% % collect variables of interest
% Weights_ATR_BRE = ATR_BRE.Specs.Weight;
% Slits_Up_ATR_BRE = ATR_BRE.Mission.History.SI.Power.LamUps;
% DesignStrat_ATR_BRE = ATR_BRE.Specs.Propulsion.DesignStrategy;
% NumStrat_ATR_BRE = ATR_BRE.Specs.Propulsion.NumStrats;

% %% ATR42 Testing ; ATR42MissionEPASS()
% % call main
% ATR_EPASS = Main(AircraftSpecsPkg.ATR42(), @MissionProfilesPkg.ATRMissionEPASS)
% 
% % collect variables of interest
% Weights_ATR_EPASS = ATR_EPASS.Specs.Weight;
% Slits_Up_ATR_EPASS = ATR_EPASS.Mission.History.SI.Power.LamUps;
% % DesignStrat_ATR_EPASS = ATR_EPASS.Specs.Propulsion.DesignStrategy;
% % NumStrat_ATR_EPASS = ATR_EPASS.Specs.Propulsion.NumStrats;

%% ERJ175LR Testing ; ERJ()
% call main
ERJ175 = Main(AircraftSpecsPkg.ERJ175LR(), @MissionProfilesPkg.ERJ)

% collect variables of interest
Weights_ERJ175 = ERJ175.Specs.Weight;
Slits_Up_ERJ175 = ERJ175.Mission.History.SI.Power.LamUps;
% DesignStrat_ERJ175 = ERJ175.Specs.Propulsion.DesignStrategy;
% NumStrat_ERJ175 = ERJ175.Specs.Propulsion.NumStrats;

%% ERJ175LR Testing ; ERJ_ClimbThenAccel()
% call main
ERJ175_accel = Main(AircraftSpecsPkg.ERJ175LR(), @MissionProfilesPkg.ERJ_ClimbThenAccel)

% collect variables of interest
Weights_ERJ175_accel = ERJ175_accel.Specs.Weight;
Slits_Up_ERJ175_accel = ERJ175_accel.Mission.History.SI.Power.LamUps;
% DesignStrat_ERJ175_accel = ERJ175_accel.Specs.Propulsion.DesignStrategy;
% NumStrat_ERJ175_accel = ERJ175_accel.Specs.Propulsion.NumStrats;

%% ERJ190_E2 Testing ; ERJ()
% call main
E2 = Main(AircraftSpecsPkg.ERJ190_E2(), @MissionProfilesPkg.ERJ)

% collect variables of interest
Weights_E2 = E2.Specs.Weight;
Slits_Up_E2 = E2.Mission.History.SI.Power.LamUps;
% DesignStrat_E2 = E2.Specs.Propulsion.DesignStrategy;
% NumStrat_E2 = E2.Specs.Propulsion.NumStrats;

%% ERJ190_FE Testing ; ERJ()
% call main
FE_PAO = Main(AircraftSpecsPkg.ERJ190_FE(), @MissionProfilesPkg.ERJ)

% collect variables of interest
Weights_FE_PAO = FE_PAO.Specs.Weight;
Slits_Up_FE_PAO = FE_PAO.Mission.History.SI.Power.LamUps;
% DesignStrat_FE = FE.Specs.Propulsion.DesignStrategy;
% NumStrat_FE = FE.Specs.Propulsion.NumStrats;

%% Example Testing ; NotionalMission00()
% call main
Not00 = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.NotionalMission00)

% collect variables of interest
Weights_Not00 = Not00.Specs.Weight;
Slits_Up_Not00 = Not00.Mission.History.SI.Power.LamUps;
% DesignStrat_Not00 = Not00.Specs.Propulsion.DesignStrategy;
% NumStrat_Not00 = Not00.Specs.Propulsion.NumStrats;

%% Example Testing ; NotionalMission01()
% call main
Not01 = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.NotionalMission01)

% collect variables of interest
Weights_Not01 = Not01.Specs.Weight;
Slits_Up_Not01 = Not01.Mission.History.SI.Power.LamUps;
% DesignStrat_Not01 = Not01.Specs.Propulsion.DesignStrategy;
% NumStrat_Not01 = Not01.Specs.Propulsion.NumStrats;

%% Example Testing ; NotionalMission02()
% call main
Not02 = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.NotionalMission02)

% collect variables of interest
Weights_Not02 = Not02.Specs.Weight;
Slits_Up_Not02 = Not02.Mission.History.SI.Power.LamUps;
% DesignStrat_Not02 = Not02.Specs.Propulsion.DesignStrategy;
% NumStrat_Not02 = Not02.Specs.Propulsion.NumStrats;

%% Example Testing ; RegionalJetMission00()
% call main
Reg00 = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.RegionalJetMission00)

% collect variables of interest
Weights_Reg00 = Reg00.Specs.Weight;
Slits_Up_Reg00 = Reg00.Mission.History.SI.Power.LamUps;
% DesignStrat_Reg00 = Reg00.Specs.Propulsion.DesignStrategy;
% NumStrat_Reg00 = Reg00.Specs.Propulsion.NumStrats;

%% Example Testing ; RegionalJetMission01()
% call main
Reg01 = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.RegionalJetMission01)

% collect variables of interest
Weights_Reg01 = Reg01.Specs.Weight;
Slits_Up_Reg01 = Reg01.Mission.History.SI.Power.LamUps;
% DesignStrat_Reg01 = Reg01.Specs.Propulsion.DesignStrategy;
% NumStrat_Reg01 = Reg01.Specs.Propulsion.NumStrats;

%% Example Testing ; RegionalJetMission02()
% call main
Reg02 = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.RegionalJetMission02)

% collect variables of interest
Weights_Reg02 = Reg02.Specs.Weight;
Slits_Up_Reg02 = Reg02.Mission.History.SI.Power.LamUps;
% DesignStrat_Reg02 = Reg02.Specs.Propulsion.DesignStrategy;
% NumStrat_Reg02 = Reg02.Specs.Propulsion.NumStrats;

%% Example Testing ; TurboPropMission00()
% call main
Turbo00 = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.TurbopropMission00)

% collect variables of interest
Weights_Turbo00 = Turbo00.Specs.Weight;
Slits_Up_Turbo00 = Turbo00.Mission.History.SI.Power.LamUps;
% DesignStrat_Turbo00 = Turbo00.Specs.Propulsion.DesignStrategy;
% NumStrat_Turbo00 = Turbo00.Specs.Propulsion.NumStrats;

%% Example Testing ; TurboPropMission01()
% call main
Turbo01 = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.TurbopropMission01)

% collect variables of interest
Weights_Turbo01 = Turbo01.Specs.Weight;
Slits_Up_Turbo01 = Turbo01.Mission.History.SI.Power.LamUps;
% DesignStrat_Turbo01 = Turbo01.Specs.Propulsion.DesignStrategy;
% NumStrat_Turbo01 = Turbo01.Specs.Propulsion.NumStrats;

%% Example Testing ; TurboPropMission02()
% call main
Turbo02 = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.TurbopropMission02)

% collect variables of interest
Weights_Turbo02 = Turbo02.Specs.Weight;
Slits_Up_Turbo02 = Turbo02.Mission.History.SI.Power.LamUps;
% DesignStrat_Turbo02 = Turbo02.Specs.Propulsion.DesignStrategy;
% NumStrat_Turbo02 = Turbo02.Specs.Propulsion.NumStrats;

%% Example Testing ; ParametricReegional()
% call main
Param = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.ParametricRegional)

% collect variables of interest
Weights_Param = Param.Specs.Weight;
Slits_Up_Param = Param.Mission.History.SI.Power.LamUps;
% DesignStrat_Param = Param.Specs.Propulsion.DesignStrategy;
% NumStrat_Param = Param.Specs.Propulsion.NumStrats;

% %% Example Testing ; BRECruise00()
% % call main
% BRE00 = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.BRECruise00)
% 
% % collect variables of interest
% Weights_BRE00 = BRE00.Specs.Weight;
% Slits_Up_BRE00 = BRE00.Mission.History.SI.Power.LamUps;
% DesignStrat_BRE00 = BRE00.Specs.Propulsion.DesignStrategy;
% NumStrat_BRE00 = BRE00.Specs.Propulsion.NumStrats;

% %% Example Testing ; BRECruise01()
% % call main
% BRE01 = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.BRECruise01)
% 
% % collect variables of interest
% Weights_BRE01 = BRE01.Specs.Weight;
% Slits_Up_BRE01 = BRE01.Mission.History.SI.Power.LamUps;
% DesignStrat_BRE01 = BRE01.Specs.Propulsion.DesignStrategy;
% NumStrat_BRE01 = BRE01.Specs.Propulsion.NumStrats;
% 
% %% Example Testing ; BRECruise02()
% % call main
% BRE02 = Main(AircraftSpecsPkg.Example(), @MissionProfilesPkg.BRECruise02)
% 
% % collect variables of interest
% Weights_BRE02 = BRE02.Specs.Weight;
% Slits_Up_BRE02 = BRE02.Mission.History.SI.Power.LamUps;
% DesignStrat_BRE02 = BRE02.Specs.Propulsion.DesignStrategy;
% NumStrat_BRE02 = BRE02.Specs.Propulsion.NumStrats;

%% LM100J_Conventional Testing ; LM100J_NoRsrv()
% call main
LMconv = Main(AircraftSpecsPkg.LM100J_Conventional(), @MissionProfilesPkg.LM100J_NoRsrv)

% collect variables of interest
Weights_LMC = LMconv.Specs.Weight;
Slits_Up_LMC = LMconv.Mission.History.SI.Power.LamUps;
% DesignStrat_LMC = LMconv.Specs.Propulsion.DesignStrategy;
% NumStrat_LMC = LMconv.Specs.Propulsion.NumStrats;

