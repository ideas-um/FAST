function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Efficient Aerospace Systems
% Laboratory
% 
% Engine Specifications Package (+AircraftSpecsPkg/+EngineSpecsPkg)
%
% Written by the IDEAS Lab at the University of Michigan. 
% https://ideas.engin.umich.edu
%
% Principal Authors:
%     Paul Mokotoff, prmoko@umich.edu
%     Max Arnson, marnson@umich.edu
%
% Principal Investigator:
%     Dr. Gokcin Cinar, cinar@umich.edu
%
% Additional Contributors:
%     Huseyin Acar
%     Nawa Khailany
%     Janki Patel
%     Michael Tsai
% 
% README last updated: 29 mar 2024
% 
% -------------------------------------------------------------------------
%
% (I) Overview
%
%       The engine specification package stores both user-created and
%       prebuilt engine specification files. These files are functions
%       which take no input and output an engine data structure which is
%       modified during analysis in FAST. This README additionally contains
%       a tutorial for building a user created specification file, as well
%       as a list of all possible variables that can be modified.
% 
% -------------------------------------------------------------------------
%
% (II) Specification Building Tutorial
%
%       (a) Copy one of the example files,
%           EngineModelPkg.EngineSpecsPkg.ExampleTF or 
%           EngineModelPkg.EngineSpecsPkg.ExampleTP, and rename it
%           appropriately. Ensure both the function name and the file name
%           are changed and set to the same name. In this tutorial I will
%           use "MyEngine" as the example name.
%
%       (b) Modify parameters such that they reflect the engine you would
%           like to design. Use recommended values in the tables below if
%           you are unsure of what to put. 
%
%       (c) Run the sizing code!
%           
%           >> Sized Engine = EngineModelPkg.TurbofanNonLinearSizing(MyEngine)
%           for turbofans, and 
%
%           >> Sized Engine = EngineModelPkg.TurbofanNonLinearSizing(MyEngine)
%           for turboprops.
%
%       (d) Set >> MyEngine.Visualize = 1; before you run the code so that 
%           you can see the engine you have designed!
%
%       (e) If you wanted to just design an engine, you are done here. If
%           you want to use your engine in the aircraft sizing code, 
%           continue to step (f).
%
%       (f) Initialize your aircraft specification file with your new 
%           engine. In your aircraft specification file, set
%
%           Aircraft.Specs.Propulsion.Engine = ...
%           EngineModelPkg.EngineSpecsPkg.MyEngine
%
% -------------------------------------------------------------------------
%
% (III) List of Variables
%       
%       (a) Overview: This is a comprehensive list of all variables that
%           can be specified by a user in an engine specification file.
%           The table below will also specify the variables' units.
%
%       (b) Key: Unitless values will be denoted by --. Recommendations for
%           parameter values are given for users with less propulsion
%           experience. Additional notes are provided for some parameters.
%
%       (c) Turbofan Table:
%
%           ---------------------------------------------------------------
%           (1) Engine.Mach
%                Description: Mach Number at engine design point
%                Units / Recommendation: -- / 0.05
%                NOTE: 0 does not work for SLS conditions. If the design
%                point is SLS, 0.05 is a good approximation
%           ---------------------------------------------------------------
%           (2) Engine.Alt
%                Description: Altitude at engine design point
%                Units / Recommendation: meters / 0
%           ---------------------------------------------------------------
%           (3) Engine.OPR
%                Description: Overall pressure ratio at design point
%                Units / Recommendation: -- / see note
%                NOTE 1: Overall pressure ratio refers to the pressure rise
%                from the free stream pressure to the pressure just after
%                all compressor stages.
%                NOTE 2: OPR varies quite a bit as engine technology
%                improves. State-of-the-art engines such as the CFM LEAP
%                engine family have OPRs between 30 to 40 at SLS.
%           ---------------------------------------------------------------
%           (4) Engine.FPR
%                Description: Fan Pressure Ratio
%                Units / Recommendation: -- / 1.5
%           ---------------------------------------------------------------
%           (5) Engine.BPR 
%                Description: Bypass Ratio
%                Units / Recommendation: -- /  see note
%                NOTE: BPR varies as engine technology improves, just like
%                OPR. State-of-the-art turbofans have BPRs between 10 and
%                12, while older engines may be closer to 5.
%           ---------------------------------------------------------------
%           (6) Engine.Tt4Max
%                Description: Combustion temperature
%                Units / Recommendation: kelvin / 2000
%           ---------------------------------------------------------------
%           (7) Engine.DesignThrust
%                Description: Thrust the (single) engine should produce at 
%                its design condition
%                Units / Recommendation: Newtons / see note
%                NOTE: Design thrust varies based on the size of the engine
%                desired. Single aisle aircraft usually have SLS thrusts on
%                the order of 100,000 newtons, while the cruise thrust is
%                on the order of 20,000 newtons
%           ---------------------------------------------------------------
%           (8) Engine.NoSpools
%                Description: Number of spools/shafts the engine has
%                Units / Recommendation: -- / 2
%                NOTE: Only 2 and 3 are acceptable values.
%           ---------------------------------------------------------------
%           (9) Engine.RPMs
%                Description: Engine spool/shaft revolutions per minute
%                Units / Recommendation: RPM / see note
%                NOTE 1: This input must be a vector of length
%                Engine.NoSpools (Variable 8). 
%                NOTE 2: The order of the RPMS should be 
%                [LowPressureShaft,IntermediatePressureShaft,HighPressureShaft]
%                if the engine has 3 spools or 
%                [LowPressureShaft,HighPressureShaft] if the engine has 2
%                spools.                
%           ---------------------------------------------------------------
%           (10) Engine.FanGearRatio
%                Description: RPM ratio between the fan spool (turbine) and
%                the fan itself.
%                Units / Recommendation: -- / NaN
%                NOTE 1: Leave as NaN for an ungeared fan.
%                NOTE 2: Geared turbofans usually have their fans spin on the
%                order of 2000 RPM. If a user would like to design a geared
%                fan but is unsure of the correct gear ratio, the
%                recommended ratio is (Engine.RPMs(1) / 2000).
%           ---------------------------------------------------------------
%           (11) Engine.FanBoosters
%                Description: Fan Booster flag
%                Units / Recommendation: -- / 0
%                NOTE 1: Options are
%                       1 (boosted)
%                       0 (not boosted)
%                NOTE 2: Boosters refer to compressor stages connected to
%                the fan shaft BEFORE the gear reduction (spinning at the
%                same RPM as the low pressure turbine).
%           ---------------------------------------------------------------
%           (12) Engine.CoreFlow.PaxBleed
%                Description: Percentage of post compressor airflow to be
%                extacted for passenger comfort/survival.
%                Units / Recommendation: -- / 0.05
%           ---------------------------------------------------------------
%           (13) Engine.CoreFlow.Leakage
%                Description: Percentage of core airflow which leaks out of
%                the flowpath.
%                Units / Recommendation: -- / 0.01
%           ---------------------------------------------------------------
%           (14) Engine.CoreFlow.Cooling
%                Description: Percentage of the flow extracted to cool the
%                combustion products
%                Units / Recommendation: -- / 0
%                NOTE: The cooling component is currently full of bugs. Do
%                not set cooling flow to anything other than 0.
%           ---------------------------------------------------------------
%           (15) Engine.MaxIter
%                Description: Maximum iterations the engine sizing code
%                will run.
%                Units / Recommendation: -- / 50
%           ---------------------------------------------------------------
%           (16) Engine.EtaPoly.Inlet
%                Description: Inlet diffuser pressure recovery
%                Units / Recommendation: -- / 0.99
%           ---------------------------------------------------------------
%           (17) Engine.EtaPoly.Diffusers
%                Description: Internal diffuser pressure recover
%                Units / Recommendation: -- / 0.99
%           ---------------------------------------------------------------
%           (18) Engine.EtaPoly.Fan
%                Description: Fan adiabatic efficiency
%                Units / Recommendation: -- / 0.95
%           ---------------------------------------------------------------
%           (19) Engine.EtaPoly.Compressors
%                Description: Compressor adiabatic efficiency
%                Units / Recommendation: -- / 0.90
%           ---------------------------------------------------------------
%           (20) Engine.EtaPoly.Combustor
%                Description: Combustion efficiency
%                Units / Recommendation: -- / 0.985
%           ---------------------------------------------------------------
%           (21) Engine.EtaPoly.Turbines
%                Description: Turbine adiabatic efficiency
%                Units / Recommendation: -- / 0.89
%           ---------------------------------------------------------------
%           (22) Engine.EtaPoly.Nozzles
%                Description: Nozzle Pressure Recovery
%                Units / Recommendation: -- / 0.98
%           ---------------------------------------------------------------
%           (23) Engine.EtaPoly.Mixing
%                Description: Coolant mixing pressure recovery
%                Units / Recommendation: -- / see note
%                NOTE: This value should be set to 1 always due to the bugs
%                in the cooling function. See variable 14.
%           ---------------------------------------------------------------
%           (24) Engine.Visualize
%                Description: visualization flag
%                Units / Recommendation: -- / 1
%                NOTE 1: Options are
%                       1 (visualize engine)
%                       0 (do not visualize engine)
%           ---------------------------------------------------------------
%
%       (d) Turboprop/Turboshaft Table:
%
%           ---------------------------------------------------------------
%           (1) Engine.Mach
%                Description: Mach Number at engine design point
%                Units / Recommendation: -- / 0.05
%                NOTE: 0 does not work for SLS conditions. If the design
%                point is SLS, 0.05 is a good approximation
%           ---------------------------------------------------------------
%           (2) Engine.Alt
%                Description: Altitude at engine design point
%                Units / Recommendation: meters / 0
%           ---------------------------------------------------------------
%           (3) Engine.OPR
%                Description: Overall pressure ratio at design point
%                Units / Recommendation: -- / see note
%                NOTE 1: Overall pressure ratio refers to the pressure rise
%                from the free stream pressure to the pressure just after
%                all compressor stages. It does not account for the
%                pressure rise due to a propeller.
%                NOTE 2: OPR varies quite a bit as engine technology
%                improves. Turboprops have lower OPRs than turbofans.
%                Between 12 and 20 is reasonable
%           ---------------------------------------------------------------
%           (4) Engine.Tt4Max
%                Description: Combustion Temperature
%                Units / Recommendation: kelvin / 1200
%           ---------------------------------------------------------------
%           (5) Engine.ReqPower
%                Description: Power production required of the gas turbine
%                at the design condition
%                Units / Recommendation: Watts / see note
%                NOTE: Depending on the size of the engine this value is
%                usually between 1.5 and 3.5 million Watts.
%           ---------------------------------------------------------------
%           (6) Engine.NPR
%                Description: Nozzle pressure ratio (turbine exit pressure
%                divided by ambient pressure)
%                Units / Recommendation: -- / 1.3
%           ---------------------------------------------------------------
%           (7) Engine.NoSpools
%                Description: Number of spools/shafts the engine has
%                Units / Recommendation: -- / 2
%                NOTE: Only 1, 2, and 3 are acceptable values.
%           ---------------------------------------------------------------
%           (8) Engine.RPMs
%                Description: Engine spool/shaft revolutions per minute
%                Units / Recommendation: RPM / see note
%                NOTE 1: This input must be a vector of length
%                Engine.NoSpools (Variable 8). 
%                NOTE 2: The order of the RPMS should be 
%                [IntermediatePressureShaft,HighPressureShaft,FreeTurbineShaft]
%                if the engine has 3 spools or 
%                [HighPressureShaft,FreeTurbineShaft] if the engine has 2
%                spools. For single spooled engines [ShaftRPM] should be
%                entered.
%           ---------------------------------------------------------------
%           (9) Engine.EtaPoly.Inlet
%                Description: Inlet diffuser pressure recovery
%                Units / Recommendation: -- / 0.99
%           ---------------------------------------------------------------
%           (10) Engine.EtaPoly.Diffusers
%                Description: Internal diffuser pressure recover
%                Units / Recommendation: -- / 0.99
%           ---------------------------------------------------------------
%           (11) Engine.EtaPoly.Compressors
%                Description: Compressor adiabatic efficiency
%                Units / Recommendation: -- / 0.90
%           ---------------------------------------------------------------
%           (12) Engine.EtaPoly.Combustor
%                Description: Combustion efficiency
%                Units / Recommendation: -- / 0.985
%           ---------------------------------------------------------------
%           (13) Engine.EtaPoly.Turbines
%                Description: Turbine adiabatic efficiency
%                Units / Recommendation: -- / 0.89
%           ---------------------------------------------------------------
%           (14) Engine.EtaPoly.Nozzles
%                Description: Nozzle Pressure Recovery
%                Units / Recommendation: -- / 0.98
%           ---------------------------------------------------------------
%           (15) Engine.Visualize
%                Description: visualization flag
%                Units / Recommendation: -- / 1
%                NOTE 1: Options are
%                       1 (visualize engine)
%                       0 (do not visualize engine)
%           ---------------------------------------------------------------
%
% -------------------------------------------------------------------------
%   
%
% end EngineModelPkg.EngineSpecsPkg.README
%
end






















