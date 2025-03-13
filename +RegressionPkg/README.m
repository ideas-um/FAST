function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Environmentally-friendly Aircraft Systems
% Laboratory
% 
% Regression Package (+RegressionPkg)
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
% README last updated: 26 December 2024
% 
% -------------------------------------------------------------------------
%
% (I) Overview
%
%       The regression package contains functions which perform the
%       non-parametric Gaussian Process Regression used to predict aircraft
%       characteristics during the aircraft sizing process. Users may
%       perform regressions on their own, or search the database for values
%       they would like. Tutorials are coming to FAST soon, as well as
%       updated functional documentation for the regression package. If a
%       user would like to use the regressions outside of the sizing code
%       before the tutorial is released, they may inspect the existing
%       function documentation in the following files
%
%       RegressionPkg.NLGPR
%       RegressionPkg.SearchDB
%
%       And look for example regression calls in
%       DataStructPkg.SpecProcessing. The developers recommend looking at
%       lines 413 and 414 in that code for a simple one-input one-output
%       example.
%       
% 
% -------------------------------------------------------------------------
% (II) Warning
%
%       This package contains information that is essential to FAST's
%       functionality, and should not be altered by end users.
%
% -------------------------------------------------------------------------
%
% (III) Example Regression and Search function calls
%
%       (a) Regression
%       (b) Search
%
% -------------------------------------------------------------------------
%
% (IV)  Appendix of Database Variables (TURBOFAN)
%       
%       These variables are listed as they should be input into the
%       Regression function, RegressionPkg.NLGPR for the Input/Output
%       space. This format is also used for the SearchDB function. To
%       reference a variable, the search path through an aircraft data
%       structure is specified as a list of strings. See the function 
%       documentation for more information and an example.
%
%       The variables are simply listed here. Detailed explanations of each
%       variable are available in both +AircraftSpecsPkg/README.m and 
%       +EngineModelPkg.EngineSpecsPkg.README
%
%       (a) Overview Variables
% 
%           ["Overview",   "Manufacturer"        ]
%           ["Overview",   "AlternateDesignation"]
%           ["Overview",   "Monikers"            ]
%           ["Overview",   "Description"         ]
%           ["Overview",   "Family"              ]  
%           ["Overview",   "SubFamily"           ]
%           ["Overview",   "PayloadType"         ]
%           ["Overview",   "NumSold"             ]
%           ["Overview",   "NumCrew"             ]
%           ["Overview",   "NumAttendants"       ]
%           ["Overview",   "References"          ]
%           ["Overview",   "Aisle"               ]
%           ["Overview",   "RangeCapability"     ]
%           ["Overview",   "ModelType"           ]
%           ["Overview",   "PassengerType"       ]
% 
%       (b) Top Level Aircraft Requirement Variables
% 
%           ["Specs",   "TLAR",   "EIS"   ]
%           ["Specs",   "TLAR",   "MaxPax"]
%           ["Specs",   "TLAR",   "Pax"   ]
%           ["Specs",   "TLAR",   "Class" ]
% 
%       (c) Propulsion Variables
% 
%           ["Specs",   "Propulsion",   "EngineDesignation"]
%           ["Specs",   "Propulsion",   "AlternateEngines" ]
%           ["Specs",   "Propulsion",   "NumEngines"       ]
%           
%           ["Specs",   "Propulsion",   "Thrust",   "SLS"  ]
%           ["Specs",   "Propulsion",   "Thrust",   "Max"  ]
%           ["Specs",   "Propulsion",   "Thrust",   "Crs"  ]
%           
%           ["Specs",   "Propulsion",   "Fuel",     "Type"       ]
%           ["Specs",   "Propulsion",   "Fuel",     "Density"    ]
%           ["Specs",   "Propulsion",   "Fuel",     "CapUsable"  ]
%           ["Specs",   "Propulsion",   "Fuel",     "CapUnusable"]
%           
%           ["Specs",   "Propulsion",   "T_W",   "SLS"]
%           
%           ["Specs",   "Propulsion",   "Arch",   "Type"]
%           
%           ["Specs",   "Propulsion",   "Eta",   "Prop"] (**defunct**)
% 
%       (d) Engine Variables
% 
%           These variables are the same as those stored in the engine 
%           databases. The "EngineDesignation" variable will call an engine
%           from the engine database and assign it to the "Engine" variable
%           within the aircraft. For example, lets say an A320 has 
%           TurbofanAC.A320.Specs.Propulsion.EngineDesignation = "LEAP_1A". 
%           Then, TurbofanAC.A320.Specs.Propulsion.Engine will be a clone 
%           of TurbofanEngines.LEAP_1A. The engine database exists as a 
%           separate entity because multiple aircraft may use an engine 
%           more than once. Statistical analysis based on engine parameters
%           using the aircraft database will be biased towards engines 
%           which are used more frequently. 
% 
% 
%           ["Specs",   "Propulsion",   "Engine",   "Manufacturer"        ]
%           ["Specs",   "Propulsion",   "Engine",   "EIS"                 ]
%           ["Specs",   "Propulsion",   "Engine",   "AlternateDesignation"]
%           ["Specs",   "Propulsion",   "Engine",   "Description"         ]
%           ["Specs",   "Propulsion",   "Engine",   "NumSold"             ]
%           ["Specs",   "Propulsion",   "Engine",   "Thrust_Max"          ]
%           ["Specs",   "Propulsion",   "Engine",   "Thrust_SLS"          ]
%           ["Specs",   "Propulsion",   "Engine",   "Thrust_Crs"          ]
%           ["Specs",   "Propulsion",   "Engine",   "FPR"                 ]
%           ["Specs",   "Propulsion",   "Engine",   "BPR"                 ]
%           ["Specs",   "Propulsion",   "Engine",   "OPR_SLS"             ]
%           ["Specs",   "Propulsion",   "Engine",   "OPR_Crs"             ]
%           ["Specs",   "Propulsion",   "Engine",   "Mach_Crs"            ]
%           ["Specs",   "Propulsion",   "Engine",   "Alt_Crs"             ]
%           ["Specs",   "Propulsion",   "Engine",   "DryWeight"           ]
%           ["Specs",   "Propulsion",   "Engine",   "DiamFan"             ]
%           ["Specs",   "Propulsion",   "Engine",   "Width"               ]
%           ["Specs",   "Propulsion",   "Engine",   "Height"              ]
%           ["Specs",   "Propulsion",   "Engine",   "Length"              ]
%           ["Specs",   "Propulsion",   "Engine",   "TSFC_SLS"            ]
%           ["Specs",   "Propulsion",   "Engine",   "TSFC_Crs"            ]
%           ["Specs",   "Propulsion",   "Engine",   "FanStages"           ]
%           ["Specs",   "Propulsion",   "Engine",   "GearStages"          ]
%           ["Specs",   "Propulsion",   "Engine",   "GearRatio"           ]
%           ["Specs",   "Propulsion",   "Engine",   "LPCStages"           ]
%           ["Specs",   "Propulsion",   "Engine",   "IPCStages"           ]
%           ["Specs",   "Propulsion",   "Engine",   "HPCStages"           ]
%           ["Specs",   "Propulsion",   "Engine",   "RCStages"            ]
%           ["Specs",   "Propulsion",   "Engine",   "HPTStages"           ]
%           ["Specs",   "Propulsion",   "Engine",   "IPTStages"           ]
%           ["Specs",   "Propulsion",   "Engine",   "LPTStages"           ]
%           ["Specs",   "Propulsion",   "Engine",   "HP100"               ]
%           ["Specs",   "Propulsion",   "Engine",   "IP100"               ]
%           ["Specs",   "Propulsion",   "Engine",   "LP100"               ]
%           ["Specs",   "Propulsion",   "Engine",   "HPContPer"           ]
%           ["Specs",   "Propulsion",   "Engine",   "IPContPer"           ]
%           ["Specs",   "Propulsion",   "Engine",   "LPContPer"           ]
%           ["Specs",   "Propulsion",   "Engine",   "Airflow_SLS"         ]
%           ["Specs",   "Propulsion",   "Engine",   "Airflow_Crs"         ]
%           ["Specs",   "Propulsion",   "Engine",   "TurbExitTemp"        ]
%           ["Specs",   "Propulsion",   "Engine",   "TurbEntryTemp"       ]
%           ["Specs",   "Propulsion",   "Engine",   "References"          ]
%           ["Specs",   "Propulsion",   "Engine",   "PresPerStage"        ]
% 
% 
% 
%       (e) Performance Variables
% 
%           ["Specs",   "Performance",   "Range"]
%           
%           ["Specs",   "Performance",   "Vels",   "Tko"  ]
%           ["Specs",   "Performance",   "Vels",   "Crs"  ]
%           ["Specs",   "Performance",   "Vels",   "MaxOp"]
%           
%           ["Specs",   "Performance",   "Alts",   "Tko"]
%           ["Specs",   "Performance",   "Alts",   "Crs"]
%           
%           ["Specs",   "Performance",   "TOFL"]
%           
%           ["Specs",   "Performance",   "RCMax"]
% 
%       (f) Weight Variables
% 
%           ["Specs",   "Weight",   "Cargo    "]
%           ["Specs",   "Weight",   "MRW      "]
%           ["Specs",   "Weight",   "MTOW     "]
%           ["Specs",   "Weight",   "MLW      "]
%           ["Specs",   "Weight",   "MZFW     "]
%           ["Specs",   "Weight",   "OEW      "]
%           ["Specs",   "Weight",   "Fuel     "]
%           ["Specs",   "Weight",   "Airframe "]
%           ["Specs",   "Weight",   "OEW_MTOW "]
%           ["Specs",   "Weight",   "MZFW_MTOW"]
%           ["Specs",   "Weight",   "EngFrac  "]
%           ["Specs",   "Weight",   "FuelFrac "]
%           ["Specs",   "Weight",   "Batt     "]
%           ["Specs",   "Weight",   "EM       "]
%           ["Specs",   "Weight",   "EG       "]
%           ["Specs",   "Weight",   "Payload  "]
% 
%       (g) Aerodynamic Variables
% 
%           ["Specs",   "Aero",   "Span         "]
%           ["Specs",   "Aero",   "Length       "]
%           ["Specs",   "Aero",   "Height       "]
%           ["Specs",   "Aero",   "TipChord     "]
%           ["Specs",   "Aero",   "Sweep        "]
%           ["Specs",   "Aero",   "RootChord    "]
%           ["Specs",   "Aero",   "S            "]
%           ["Specs",   "Aero",   "WingtipDevice"]
%           ["Specs",   "Aero",   "MAC          "]
%          
%           ["Specs",   "Aero",   "L_D          ",   "CrsBRE" ]
%           ["Specs",   "Aero",   "L_D          ",   "Crs"    ]
%           ["Specs",   "Aero",   "L_D          ",   "Clb"    ]
%           ["Specs",   "Aero",   "L_D          ",   "Des"    ]
%           ["Specs",   "Aero",   "L_D          ",   "CrsMAC" ]
%           ["Specs",   "Aero",   "L_D          ",   "CrsMAC2"]
%          
%           ["Specs",   "Aero",   "W_S          ",   "SLS"]
%          
%           ["Specs",   "Aero",   "TaperRatio   "]
%           ["Specs",   "Aero",   "AR           "]
% 
%       (h) Power Variables
% 
%           ["Specs",   "Power",   "SpecEnergy",   "Fuel"]
%           ["Specs",   "Power",   "SpecEnergy",   "Batt"]
%           
%           ["Specs",   "Power",   "Eta",   "EM"]
%           ["Specs",   "Power",   "Eta",   "EG"]
%           
%           ["Specs",   "Power",   "Phi",   "SLS"]
%           ["Specs",   "Power",   "Phi",   "Tko"]
%           ["Specs",   "Power",   "Phi",   "Clb"]
%           ["Specs",   "Power",   "Phi",   "Crs"]
%           ["Specs",   "Power",   "Phi",   "Des"]
%           ["Specs",   "Power",   "Phi",   "Lnd"]
%           
%           ["Specs",   "Power",   "PW",   "AC"]
%           ["Specs",   "Power",   "PW",   "EM"]
%           ["Specs",   "Power",   "PW",   "EG"]
% 
%       (i) Settings Variables
% 
%           These variables are set by a user during aircraft sizing. 
%           They are instantiated for database aircraft so that database 
%           aircraft can be directly sized without user action, however 
%           there would be no need to run a regression with them. If left
%           unmodified in a specification file, they will take default 
%           values which are set in +DataStructPkg/SpecProcessing.m
% 
%           ["Settings",   "TkoPoints         "]
%           ["Settings",   "ClbPoints         "]
%           ["Settings",   "CrsPoints         "]
%           ["Settings",   "DesPoints         "]
%           ["Settings",   "OEW               "]
%           ["Settings",   "Analysis          "]
%           ["Settings",   "Plotting          "]
%           ["Settings",   "DataTypeValidation"]
% 
% 
%
% -------------------------------------------------------------------------
%
% end RegressionPkg.README
%
end