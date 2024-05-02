function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Environmentally-friendly Aircraft Systems
% Laboratory
% 
% Aircraft Specifications Package (+AircraftSpecsPkg)
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
% README last updated: 24 apr 2024
% 
% -------------------------------------------------------------------------
%
% (I) Overview
%
%       The aircraft specification package stores both user-created and
%       prebuilt aircraft specification files. These files are functions
%       which take no input and output an aircraft data structure which is
%       modified during analysis in FAST. This README additionally contains
%       a tutorial for building a user created specification file, as well
%       as a list of all possible variables that can be modified.
%       Additionally there are some tips in section IV.
% 
% -------------------------------------------------------------------------
%
% (II) Specification Building Tutorial
%
%       (a) Copy the example file, AircraftSpecsPkg.Example. Rename it 
%           appropriately. Ensure both the function name and the file name
%           are changed and set to the same name. 
%
%       (b) Modify parameters such that they reflect the aircraft you would
%           like to design.
%
%       (c) See the full list of parameters you can modify in the table
%           below. Remember, aside from the required inputs, all other
%           fields can either be set to NaN or simply not included in your
%           file. The regressions and projections will fill out these
%           values for you based on the information you provide.
%
%       (d) You are ready to run FAST. See the main directory README for
%           more detailed information on running the code.
%
%
%
% -------------------------------------------------------------------------
%
% (III) List of Variables
%       
%       (a) Overview: This is a comprehensive list of all variables that
%           can be specified by a user in an aircraft specification file.
%           The table below will also specify the variables' units and what
%           defaults are used if they are left uninstantiated or left as
%           NaNs in the specifications.
%
%       (b) Key: Required values will have a default value set to *REQ*,
%           while values predicted by the regressions (as opposed to a 
%           constant value) will have their default set to PRED. Unitless
%           values will be denoted by --, while multiplication and division
%           symbols are represented by * and _ respectively. Some
%           parameters have additional notes when relevant
%
%       (c) Table:
%
%           ---------------------------------------------------------------
%           (1) Aircraft.Specs.TLAR.EIS
%                Description: Entry into Service
%                Units / Default Value: Year / 2021
%           ---------------------------------------------------------------
%           (2) Aircraft.Specs.TLAR.Class
%                Description: Turboprop or Turbofan or Piston or Propfan?
%                Units / Default Value: -- / *REQ*
%                NOTE: String input required, options are
%                      {"Turbofan" }
%                      {"Turboprop"}
%                      {"Propfan"  } (Not yet functional, coming soon)
%                      {"Piston"   } (Not yet functional, coming soon)
%           ---------------------------------------------------------------
%           (3) Aircraft.Specs.TLAR.MaxPax
%                Description: Number of passengers
%                Units / Default Value: -- / *REQ*
%           ---------------------------------------------------------------
%           (4) Aircraft.Specs.Performance.Vels.Tko
%                Description: Takeoff Velocity
%                Units / Default Value: meters_second / Variable
%                NOTE: Turbofans = 69, Turboprops = 59
%           ---------------------------------------------------------------
%           (5) Aircraft.Specs.Performance.Vels.Crs
%                Description: Cruise Velocity
%                Units / Default Value: Mach Number / PRED
%           ---------------------------------------------------------------
%           (6) Aircraft.Specs.Performance.Alts.Tko
%                Description: Takeoff altitude
%                Units / Default Value: meters / 0 (Mean Sea Level)
%                NOTE: negative altitudes (below MSL) not acceptable
%           ---------------------------------------------------------------
%           (7) Aircraft.Specs.Performance.Alts.Crs
%                Description: Cruise Altitude
%                Units / Default Value: meters / PRED
%           ---------------------------------------------------------------
%           (8) Aircraft.Specs.Performance.RCMax
%                Description: Maximum Rate of Climb
%                Units / Default Value: meters_second / PRED
%           ---------------------------------------------------------------
%           (9) Aircraft.Specs.Performance.Range
%                Description: Mission Range
%                Units / Default Value: meters / *REQ*
%           ---------------------------------------------------------------
%           (10) Aircraft.Specs.Aero.L_D.Clb
%                Description: Lift to drag ratio during climb
%                Units / Default Value: -- / Variable
%                NOTE: Turbofans = PRED, Turboprops = 9
%           ---------------------------------------------------------------
%           (11) Aircraft.Specs.Aero.L_D.Crs
%                Description: Lift to drag ratio at cruise
%                Units / Default Value: -- / Variable
%                NOTE: Turbofans = PRED, Turboprops = 15
%           ---------------------------------------------------------------
%           (12) Aircraft.Specs.Aero.L_D.Des
%                Description: Lift to drag ratio during descent
%                Units / Default Value: -- / Variable
%                NOTE: Turbofans = PRED, Turboprops = 9
%           ---------------------------------------------------------------
%           (13) Aircraft.Specs.Aero.W_S.SLS
%                Description: Wing loading at static sea level
%                Units / Default Value: kilogram_(meter^2) / PRED
%                NOTE: SLS refers to MTOW_(Wing Area)
%           ---------------------------------------------------------------
%           (14) Aircraft.Specs.Weight.MTOW
%                Description: Maximum takeoff weight (mass)
%                Units / Default Value: kilograms / PRED
%                NOTE: This value is used as an initial guess in the sizing
%                      iteration, and will be overwritten during sizing
%           ---------------------------------------------------------------
%           (15) Aircraft.Specs.Weight.EG
%                Description: Electric generator weight (mass)
%                Units / Default Value: kilograms / 0
%                NOTE: This value is used as an initial guess in the sizing
%                      iteration, and will be overwritten during sizing
%           ---------------------------------------------------------------
%           (16) Aircraft.Specs.Weight.EM
%                Description: Electric motor weight (mass)
%                Units / Default Value: kilograms / 0
%                NOTE: This value is used as an initial guess in the sizing
%                      iteration, and will be overwritten during sizing
%           ---------------------------------------------------------------
%           (17) Aircraft.Specs.Weight.Fuel
%                Description: Fuel weight (mass)
%                Units / Default Value: kilograms / PRED
%                NOTE: This value is used as an initial guess in the sizing
%                      iteration, and will be overwritten during sizing
%           ---------------------------------------------------------------
%           (18) Aircraft.Specs.Weight.Batt
%                Description: Battery weight (mass)
%                Units / Default Value: kilograms / 0
%                NOTE: This value is used as an initial guess in the sizing
%                      iteration, and will be overwritten during sizing
%           ---------------------------------------------------------------
%           (19) Aircraft.Specs.Weight.Payload
%                Description: Payload weight (mass)
%                Units / Default Value: kilograms / see note
%                NOTE: This value defaults to 95 kilograms (~220 pounds)
%                per passenger and will be overwritten in on-design mode,
%                however when running an off-design analysis the user MUST
%                update this payload weight from the design value or else 
%                the code will not recognize that the payload has changed, 
%                even if the number of passengers has been updated from the
%                design condition. See variable 70 for more information on
%                off-design analysis.
%           ---------------------------------------------------------------
%           (20) Aircraft.Specs.Weight.WairfCF
%                Description: Airframe weight calibration factor
%                Units / Default Value: -- / 1
%                NOTE: This will modify the value predicted by the airframe
%                regressions during sizing
%           ---------------------------------------------------------------
%           (21) Aircraft.Specs.Propulsion.Engine
%                Description: Engine specification file
%                Units / Default Value: -- / see note
%                NOTE: if left as NaN or uninstatiated, an engine will be
%                designed using a unique set of default values and
%                regression predictions. See
%                EngineModelPkg.EngineSpecsPkg.README, Section III.c and
%                III.d for more information.
%           ---------------------------------------------------------------
%           (22) Aircraft.Specs.Propulsion.NumEngines
%                Description: Number of gas turbine engines
%                Units / Default Value: -- / 2
%           ---------------------------------------------------------------
%           (23) Aircraft.Specs.Propulsion.T_W.SLS
%                Description: Thrust-to-weight ratio at static sea level
%                Units / Default Value: -- / PRED
%                NOTE: This value is overwritten for turboprops as power to
%                weight ratio is used instead
%           ---------------------------------------------------------------
%           (24) Aircraft.Specs.Propulsion.Thrust.SLS
%                Description: Total thrust at static sea level (NOT per
%                engine)
%                Units / Default Value: Newtons / PRED
%                NOTE: This value is overwritten for turboprops as power is
%                used instead.
%           ---------------------------------------------------------------
%           (25) Aircraft.Specs.Propulsion.Eta.Prop
%                NOTE: This parameter is obsolete and no longer used in the
%                FAST sizing code.
%           ---------------------------------------------------------------
%           (26) Aircraft.Specs.Propulsion.MDotCF
%                Description: Fuel (Jet-A) consumption calibration factor
%                Units / Default Value: -- / 1
%                NOTE: This will modify the value output by the gas turbine
%                engine models during sizing.
%           ---------------------------------------------------------------
%           (27) Aircraft.Specs.Propulsion.Arch.Type
%                Description:
%                Units / Default Value: -- / *REQ*
%                NOTE 1: String input required, options are
%                      {"C"  }     (Conventional)
%                      {"E"  }     (Fully electric)
%                      {"TE" }*    (Fully turboelectric)
%                      {"PE" }*    (Partially turboelectric)
%                      {"PHE"}     (Parallel hybrid-electric) 
%                      {"SHE"}*    (Series hybrid-electric)
%                      {"O"  }     (Other, user-specified)
%                      * denotes Not yet functional, coming soon
%               NOTE 2: If "O" is entered, a user must be careful to also
%               specify the power matrix variables (36 through 59 in this 
%               list), otherwise the code will assume conventional
%               architecture despite setting the type to other.
%           ---------------------------------------------------------------
%           (28) Aircraft.Specs.Power.SpecEnergy.Fuel
%                Description: Fuel specific energy
%                Units / Default Value: kiloWatt*hours_kilogram / 11.9
%           ---------------------------------------------------------------
%           (29) Aircraft.Specs.Power.SpecEnergy.Batt
%                Description: Battery specific energy
%                Units / Default Value: kiloWatt*hours_kilogram / PRED
%           ---------------------------------------------------------------
%           (30) Aircraft.Specs.Power.Eta.EM
%                Description: Electric motor efficiency
%                Units / Default Value: -- / 0.96
%           ---------------------------------------------------------------
%           (31) Aircraft.Specs.Power.Eta.EG
%                Description: Electric generator efficiency
%                Units / Default Value: -- / 0.96
%           ---------------------------------------------------------------
%           (32) Aircraft.Specs.Power.Eta.Propeller
%                Description: Propulsive (propeller) efficiency
%                Units / Default Value: -- / 0.8
%                NOTE: Turbofan efficiencies are calculated internal to the 
%                turbofan engine model. This parameter is used in place of 
%                a propeller model to capture losses in thrust sources 
%                powered by turboshaft
%                engines
%           ---------------------------------------------------------------
%           (33) Aircraft.Specs.Power.P_W.SLS
%                Description: Aircraft power-to-weight ratio at sea level
%                static conditions.
%                Units / Default Value: kiloWatts_kilogram / PRED
%                NOTE: This value is overwritten for turbofans as thrust to
%                weight ratio is used instead
%           ---------------------------------------------------------------
%           (34) Aircraft.Specs.Power.P_W.EM
%                Description: Electric motor power-to-weight ratio
%                Units / Default Value: kiloWatts_kilogram / PRED
%           ---------------------------------------------------------------
%           (35) Aircraft.Specs.Power.P_W.EG
%                Description: Electric generator power-to-weight ratio
%                Units / Default Value: kiloWatts_kilogram / 5
%           ---------------------------------------------------------------
%           (36) Aircraft.Specs.Power.LamTS.Tko
%           (37) Aircraft.Specs.Power.LamTS.Clb
%           (38) Aircraft.Specs.Power.LamTS.Crs
%           (39) Aircraft.Specs.Power.LamTS.Des
%           (40) Aircraft.Specs.Power.LamTS.Lnd
%           (41) Aircraft.Specs.Power.LamTS.SLS
%           (42) Aircraft.Specs.Power.LamTSPS.Tko
%           (43) Aircraft.Specs.Power.LamTSPS.Clb
%           (44) Aircraft.Specs.Power.LamTSPS.Crs
%           (45) Aircraft.Specs.Power.LamTSPS.Des
%           (46) Aircraft.Specs.Power.LamTSPS.Lnd
%           (47) Aircraft.Specs.Power.LamTSPS.SLS
%           (48) Aircraft.Specs.Power.LamPSPS.Tko
%           (49) Aircraft.Specs.Power.LamPSPS.Clb
%           (50) Aircraft.Specs.Power.LamPSPS.Crs
%           (51) Aircraft.Specs.Power.LamPSPS.Des
%           (52) Aircraft.Specs.Power.LamPSPS.Lnd
%           (53) Aircraft.Specs.Power.LamPSPS.SLS
%           (54) Aircraft.Specs.Power.LamPSES.Tko
%           (55) Aircraft.Specs.Power.LamPSES.Clb
%           (56) Aircraft.Specs.Power.LamPSES.Crs
%           (57) Aircraft.Specs.Power.LamPSES.Des
%           (58) Aircraft.Specs.Power.LamPSES.Lnd
%           (59) Aircraft.Specs.Power.LamPSES.SLS
%                Description: These variables are propulsion architecture
%                power matrices. They have default configurations depending
%                on which option was chosen for
%                Aircraft.Specs.Propulsion.Arch.Type (Variable 27). If set
%                to "O", the user must specify some or all of these values.
%                It is not recommended to use user-specified matrices
%                without proper understanding. See the README in the main
%                directory, Section II.1.f for more information.
%           ---------------------------------------------------------------
%           (60) Aircraft.Specs.Power.Battery.ParCells
%                Description: Number of battery cells in parallel
%                Units / Default Value: -- / NaN
%                NOTE: If a user does not specify this variable, FAST will
%                run a simplified battery model. See BatteryPkg.README,
%                Section I for more information.
%           ---------------------------------------------------------------
%           (61) Aircraft.Specs.Power.Battery.SerCells 
%                Description: Number of battery cells in series
%                Units / Default Value: -- / NaN
%                NOTE: If a user does not specify this variable, FAST will
%                run a simplified battery model. See BatteryPkg.README,
%                Section I for more information.
%           ---------------------------------------------------------------
%           (62) Aircraft.Specs.Power.Battery.BegSOC
%                Description: Beginning state of charge for the battery
%                Units / Default Value: percentage / 100
%           ---------------------------------------------------------------
%           (63) Aircraft.Settings.TkoPoints
%                Description: Number of discrete points used in the takeoff
%                segment during sizing.
%                Units / Default Value: -- / 10
%           ---------------------------------------------------------------
%           (64) Aircraft.Settings.ClbPoints
%                Description: Number of discrete points used in the climb
%                segment during sizing.
%                Units / Default Value: -- / 10
%           ---------------------------------------------------------------
%           (65) Aircraft.Settings.CrsPoints
%                Description: Number of discrete points used in the cruise
%                segment during sizing.
%                Units / Default Value: -- / 10
%           ---------------------------------------------------------------
%           (66) Aircraft.Settings.DesPoints
%                Description: Number of discrete points used in the descent
%                segment during sizing.
%                Units / Default Value: -- / 10
%           ---------------------------------------------------------------
%           (67) Aircraft.Settings.OEW.MaxIter
%                Description: Maximum number of iterations permitted when
%                predicting operational empty weight.
%                Units / Default Value: -- / 20
%           ---------------------------------------------------------------
%           (68) Aircraft.Settings.OEW.Tol
%                Description: Convergence tolerance for the operational
%                empty weight iteration.
%                Units / Default Value: -- / 1e-6
%           ---------------------------------------------------------------
%           (69) Aircraft.Settings.Analysis.MaxIter
%                Description: Maximum number of iterations permitted in
%                on-design or off-design alaysis
%                Units / Default Value: -- / 50
%           ---------------------------------------------------------------
%           (70) Aircraft.Settings.Analysis.Type
%                Description: On-design or off-design analysis flag
%                Units / Default Value: -- / 1
%                NOTE 1: Options are
%                       1 (On-design)
%                      -2 (Off-design)
%                NOTE 2: When running an off design analysis, the aircraft
%                data structure input into the driver Main() must be a
%                previously sized aircraft. It is also recommended to
%                change the payload weight (Variable 19) or the range
%                (Variable 9) to evaluate aircraft performance at a new
%                condition. If nothing is changed, the sized aircraft is
%                flying its design mission and the code will return the
%                same aircraft.
%                NOTE 3: When running off-design analysis, ensure that the
%                mission profile is parameterized by the aircraft data
%                structure. See MissionProfilesPkg.README, Section III.a
%                for more information.
%           ---------------------------------------------------------------
%           (71) Aircraft.Settings.Plotting
%                Description: Mission history plotting flag
%                Units / Default Value: -- / 0
%                Note 1: Options are:
%                       1 (plot mission history)
%                       0 (do not plot mission history)
%           ---------------------------------------------------------------
%           (72) Aircraft.Settings.Table
%                Description: Mission history tabulation flag
%                Units / Default Value: -- / 0
%                Note 1: Options are:
%                       1 (tabulate mission history)
%                       0 (do not tabulate mission history)
%           ---------------------------------------------------------------
%           (73) Aircraft.Settings.VisualizeAircraft
%                Description: Aircraft visualization flag
%                Units / Default Value: -- / 0
%                Note 1: Options are:
%                       1 (visualize aircraft)
%                       0 (do not visualize aircraft)
%           ---------------------------------------------------------------
%           (74) Aircraft.Settings.Dir.Size
%                Description: Sizing directory
%                Units / Default Value: -- / Current Directory
%                NOTE: Not recommended to modify this variable
%           ---------------------------------------------------------------
%           (75) Aircraft.Settings.Dir.Oper
%                Description: Operations directory
%                Units / Default Value: -- / EAP Directory
%                NOTE: Not recommended to modify this variable
%           ---------------------------------------------------------------
%           (76) Aircraft.Geometry.LengthSet
%                Description: Fuselage length (used in aircraft
%                visualization).
%                Units / Default Value: meters / PRED
%           ---------------------------------------------------------------
%           (77) Aircraft.Geometry.Preset
%                Description: Geometry specification file
%                Units / Default Value: -- / see note
%                NOTE 1: A user may create their own aircraft geometry file
%                if they wish to visualize a geometry that is not built
%                into FAST. See VisualizationPkg.README for more
%                information.
%                NOTE 2: if left as NaN or uninstantiated AND visualization
%                was requested (Variable 73 set to 1), FAST will use a
%                default geometry that is most likely to be seen depending
%                on the class of aircraft (Variable 2) and the number of
%                passengers (Variable 3). The default geometry for
%                turbofans is an A320, while the default geometry for
%                turboprops with 20+ passengers is an ATR 42, and
%                turboprops with 19 or fewer passengers is a Beechcraft
%                Model 99. More default turbofan geometries coming soon!
%                Note 3: The geometries will scale as the aircraft is
%                sized, even if they are specified by the user.
%           ---------------------------------------------------------------
%
%
%
% -------------------------------------------------------------------------
%   
% (IV) Helpful Tips
%
%           (a) Use pre-built propulsion architectures for unconventional
%               aircraft designs. A thorough understanding of the power
%               split matrices is not required to design hybrid or fully
%               electric aircraft!
%
%           (b) The minimum required inputs are the following 4 variables
%               Aircraft.Specs.TLAR.Class             (Variable 2)
%               Aircraft.Specs.TLAR.MaxPax            (Variable 3)
%               Aircraft.Specs.Performance.Range      (Variable 9)
%               Aircraft.Specs.Propulsion.Arch.Type   (Variable 27)
%
% end AircraftSpecsPkg.README
%
end