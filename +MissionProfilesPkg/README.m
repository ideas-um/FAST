function [] = README()
%
% Copyright 2024 The Regents of the University of Michigan,
% The Integrated Design of Environmentally-friendly Aircraft Systems
% Laboratory
% 
% Mission Profiles Package (+MissionProfilesPkg)
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
%     The mission profiles package stores both missions included in FAST
%     and missions created by users. These missions are called as functions
%     when FAST performs any on- or off- design analysis. 
% 
% -------------------------------------------------------------------------
%
% (II) Mission Profile Building Tutorial
%
%     A mission profile is defined as a flight path/trajectory that an
%     analyzed aircraft will fly. Each mission profile is comprised of
%     segments which include takeoff, climb, cruise, descent, and landing.
%     All of these segments can be optionally included in a mission
%     profile.
%
%     The user can define as many missions as they'd like within one
%     mission profile specification file (by using multiple mission IDs, as
%     described later in this README). For example, the user may want to
%     define a design mission and a reserve mission.
%
%     There are six main steps to creating a mission profile:
%
%         (1) Draw out your mission profile on paper (or using "ASCII art"
%             as done in the mission profiles shipped with FAST). This will
%             help identify which segments must be included in your mission
%             profile.
%
%             In this example, a 2,000 nmi mission and 30-minute loiter
%             will serve as an example case. It's mission profile is drawn
%             below:
%
%             mission 1: 2,000 nmi               | mission 2: 30-minute
%                                                |            loiter 
%                                                |
%                     _______________________    |
%                    /                       \   |
%                   /                         \  |  ______
%                  /                           \ | /      \
%                 /                             \|/        \ 
%              __/                               |          \__
%
%         (2) Identify the mission targets by filling in the
%             "Mission.Target.Valu" and "Mission.Target.Type" fields. These
%             are the desired ranges/endurances that the designed aircraft
%             must fly. The "Mission.Target.Valu" field accepts either
%             distances (in m) to specify a desired range to fly, or a time
%             (in min) to specify a desired endurance. The
%             "Mission.Target.Type" field is used to define whether the
%             target value is a distance-based target ("Dist") or a
%             time-based target ("Time"). For the example at-hand, these
%             fields would be:
%
%             Mission.Target.Valu = [UnitConversionPkg.ConvLength(2000, "naut mi", "m"); 30];
%             Mission.Target.Type = ["Dist"; "Time"];
%
%             Notice that the above are set as column vectors. For mission
%             profile processing purposes, please keep all mission profile
%             specifications as column vectors, justl like the ones shown
%             in the remainder of the tutorial.
%
%         (3) List the mission segments and their associated ID using the
%             "Mission.Segs" and "Mission.ID" fields. The "Mission.Segs"
%             field accepts strings of either "Takeoff", "Climb", "Cruise",
%             "Descent", or "Landing". The "Mission.ID" field is used to
%             group segments of the same mission together. For example, if
%             a user is creating a mission profile with a design mission
%             and a reserve mission, all mission segments for the design
%             mission are assigned a Mission ID of 1. Then, all mission
%             segments for the reserve mission are assigned a Mission ID of
%             2. For the example mission profile, the mission segments and
%             IDs are:
%
%             Mission.Segs = ["Takeoff"; "Climb"; "Cruise"; "Descent" ;
%                             "Climb"; "Cruise"; "Descent"; "Landing"];
%             Mission.ID   = [   1     ;    1   ;     1   ;     1     ;
%                                2     ;    2   ;     2   ;     2    ];
%
%             Notice that the first mission has an ID of 1, and consists of
%             a takeoff, climb, cruise, and descent segment. The second
%             mission has an ID of 2, and consists of a climb, cruise,
%             descent, and landing segment.
%
%             When creating mission profiles, please make sure that the
%             first mission has an ID of 1 and all successive missions have
%             IDs of 2, 3, 4, etc.
%
%             While specifying the segments in a mission, please note the
%             following:
%
%                 (a) The "Takeoff" segment can only be used as the first
%                     mission segment in the entire mission profile.
%                     Similarly, the "Landing" segment can only be used as
%                     the final segment in the entire mission profile.
%
%                 (b) A "Cruise" segment can appear only once per mission.
%                     This is because the cruise segments are iterated
%                     upon in order to converge the mission analysis. If
%                     multiple "Cruise" segments are provided per mission,
%                     an error will be thrown because FAST does not know
%                     which cruise segment to lengthen or shorten to
%                     converge the mission analysis.
%
%                     There can, be multiple "Cruise" segments in the
%                     entire mission profile. However, "Cruise" can only
%                     appear once within the mission segments associated
%                     with a single mission ID. (This is why Mission 1 can
%                     have a "Cruise" segment and Mission 2 can have a
%                     "Cruise" segment in the mission profile prescribed
%                     above.)
%
%         (4) Determine the beginning/ending altitudes and airspeeds
%             (boundary conditions) for each segment flown. Similar to the
%             mission segments and ID, these are defined in one, continuous
%             column vector. The beginning and ending altitude fields are
%             "Mission.AltBeg" and "Mission.AltEnd", respectively, and
%             require units of m.
%
%             The beginning and ending velocity fields are "Mission.VelBeg"
%             and "Mission.VelEnd", respectively, and require units of
%             either m/s or mach. Additionally, the user must specify the
%             velocity type using the "Mission.TypeBeg" and
%             "Mission.TypeEnd" fields. The available velocity types are
%             "TAS" (true airspeed, requires units of m/s), "EAS"
%             (equivalent airspeed, requires units or m/s), or "Mach" (mach
%             number, requires unitless input).
%
%             Note that the user may specify different velocity types for
%             the beginning and ending parts of a mission segment
%             (speed/unit conversions are done within FAST).
%
%             For the mission profile example used here, an example set of
%             boundary conditions:
%
%             Mission.AltBeg  = [     0;      0;  10668;  10668 ; ...
%                                  1000;   3048;   3048;      0];
%
%             Mission.AltEnd  = [     0;  10668;  10668;   1000 ; ...
%                                  3048;   3048;      0;      0];
%
%             Mission.VelBeg  = [  0.00;  77.20;   0.78;   0.78 ; ...
%                                 92.60; 123.50; 123.50;  82.30];
%
%             Mission.VelEnd  = [ 77.20;   0.78;   0.78;  92.60 ; ...
%                                123.50; 123.50;  82.30;   0.00];
%
%             Mission.TypeBeg = ["TAS" ; "EAS" ; "Mach"; "Mach" ; ...
%                                "TAS" ; "EAS" ; "EAS" ; "TAS" ];
%
%             Mission.TypeEnd = ["TAS" ; "Mach"; "Mach"; "TAS"  ; ...
%                                "EAS" ; "EAS" ; "TAS" ; "TAS" ];
%
%         (5) Lastly, specify a climb rate for each segment using the 
%             "Mission.ClbRate" field. For the "Takeoff", "Cruise", and
%             "Landing" segments, the rate of climb can be prescribed as
%             NaN. For the "Climb" and "Descent" segments, the user can
%             either specify a rate of climb (in m/s) or leave it as NaN.
%             For the example at-hand:
%
%             Mission.ClbRate = [ NaN; 10.16; NaN; NaN; ...
%                                 NaN;   NaN; NaN; NaN] ;
%
%             If a climb rate is specified, the climb segment will adhere
%             to the prescribed climb rate and change the velocity
%             according to the aircraft's power available. If a climb rate
%             is specified as NaN, the climb segment will adhere to the
%             prescribed boundary conditions and change the rate of climb.
%
%     (6) The mission profile is now defined! It can be stored in the
%         "Aircraft.Mission.Profile" variable, where "Aircraft" is the
%         highest-level structure associated with a candidate aircraft
%         design. An example line of code for this is shown below (assuming
%         the "Aircraft" is returned from the function).
%
%             Aircraft.Mission.Profile = Mission;
%
% -------------------------------------------------------------------------
%   
% (III) Helpful Tips
%
%     (a) Depending on user intention, it may be beneficial to parameterize
%         mission characteristics based on the input aircraft. In other
%         words, if the mission profile a user intends to fly has a hard-
%         coded range as opposed to reading a range in from the aircraft
%         structure, despite changing Aircraft.Specs.Performance.Range
%         before running the analysis, the mission flown will still target
%         the hard-coded range. This is true of segment velocities and
%         altitudes as well.
%           
%     (b) It is recommended to copy an existing mission from the
%         +MissionProfilesPkg and modify it as opposed to starting from
%         scratch. This will provide the user a template that they can fill
%         out so no fields are left uninstantiated. The developer-
%         recommended template mission is NotionalMission00.
%
%     (c) Aligning the mission ID and mission segments is an easy way to
%         debug the mission profile specification. Also, aligning the
%         beginning/ending speeds and altitudes, rate of climb, and speed
%         type can help with debugging too.
%
% -------------------------------------------------------------------------
%
% end MissionProfilesPkg.README
%
end