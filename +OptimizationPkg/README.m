function [] = README()
%
% EAP power management optimization for FAST
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
% 
% 
% ------------------------------------------------------------
% 
% 
% Background:
% --------------------
% 
% The "+OptimizationPkg" contains all of the files used to
% perform two optimizations:
% 
%     1) A design power split optimization, which selects the
%        design (sea-level static takeoff) power split that
%        minimizes the selected objective function.
% 
%     2) An operational power split optimization, which
%        selects the operational power splits to be used while
%        flying the mission.
% 
% 
% Note that both power split optimizations can be combined
% together and solved. However, please note that there are
% two separate optimization problems being solved - it does
% not get combined into one problem (but the same objective
% function is used for both). As a result of this, there have
% been convergence issues in some of the test cases run.
% 
% 
% In this work, the design power split is defined as:
% 
%               Electric Motor Power Available
%     --------------------------------------------------
%       (Electric Motor + Gas Turbine) Power Available
% 
% 
% The operational power splits are defined as:
% 
%                 Electric Motor Power Output
%     --------------------------------------------------
%       (Electric Motor + Gas Turbine) Power Available
% 
% 
% Please note that the power available considers the lapsed
% engine power for the operational power splits.
% 
% 
% ------------------------------------------------------------
% 
% 
% Using the package:
% --------------------
% 
% To use the optimization package, seven variables must be
% defined in the aircraft specification file:
% 
%     1) Aircraft.PowerOpt.Settings.DesPowSplit - a flag to
%        turn on the design power split optimizer. Set this to
%        1 to run this optimizer or 0 to not run it.
% 
%     2) Aircraft.PowerOpt.Settings.OpsPowSplit - a flag to
%        turn on the operational power split optimizer. Set
%        this to 1 to run this optimizer or 0 to not run it.
% 
%     3) Aircraft.PowerOpt.Tol - convergence tolerance when
%        running the operational power split optimizer.
% 
%     4) Aircraft.PowerOpt.MaxIter - maximum number of
%        iterations to be run by the operational power split
%        optimizer.
% 
%     5) Aircraft.PowerOpt.ObjFun - the objective function to
%        use while performing the optimization(s). the current
%        options are:
% 
%            a) "FuelBurn" - fuel burn while flying.
%            b) "Energy"   - energy consumed by both the fuel
%                            and battery (combined into a
%                            scalar value) while flying.                           
%            c) "DOC"      - direct operating cost (currently
%                            unavailable and will return 0).
% 
%     6) Aircraft.PowerOpt.Segments - the segments that should
%        be hybridized during the operational power split
%        optimization. The following segments have been tested
%        and can be included:
% 
%            - "Takeoff"
%            - "Climb"
%            - "Cruise"
% 
%        The following segments have not been tested (because
%        re-charging hasn't been included in the optimization
%        models yet):
% 
%            - "Descent"
%            - "Landing"
% 
%     7) Aircraft.Specs.Power.RechargeEM - the electric motor
%        recharge power. currently, recharging is not included
%        in the optimization models, so this parameter can be
%        set to 0. In the future, a nonzero number can be
%        provided to specify how much power the electric motor
%        can send to the battery for recharging.
% 
% Examples of these variable initializations are available in
% either "Example.m" (which has the variables, but are not
% necessarily initialized to anything because this aircraft is
% conventionally powered) or "ERJ190_PowerOpt.m" (has all of
% the variables initialized to meaningful values), which can
% be found in the "+AircraftSpecsPkg" folder.
% 
% 
% ------------------------------------------------------------
% 
% 
% Notes and warnings:
% --------------------
%
% 0) This tool is currently deprecated and had worked on a
%    previous version of FAST. Additional updates are expected
%    to be worked on in Spring/Summer 2024 with an intended
%    release of these features by the end of 2024.
% 
% 1) When using the operational power split optimization, make
%    sure to provide an electric motor weight and battery
%    weight. If these are not provided, the optimization will
%    fail, even if the design power split optimization was
%    requested to be run as well.
% 
%    When using the design power split optimization, the
%    initial battery weight must be guessed (in order for the
%    first sizing iteration to appropriately optimize the
%    operational power splits). An electric motor weight does
%    not need to be guessed (though the user is welcome to do
%    so, and is required if both the design and operational
%    power split optimizations are being run). 
% 
% 2) For the operational power split optimization, the power
%    splits for takeoff, climb, cruise, descent, and landing
%    are overwritten within the optimizer. Therefore, it is
%    okay to leave them as 0 in the aircraft specification
%    file.
% 
%    However, if running the design power split optimization
%    only, make sure to define which segments should be
%    hybridized by providing positive power splits in the
%    "Aircraft.Specs.Power.Lambda*" variables. The design power
%    split doesn't need to be provided because the optimizer
%    will guess an initial design power split (though the user
%    is welcome to provide an initial guess themself).
% 
% 3) All power split optimizations are called by setting their
%    respective flags to 1. There are no other additional
%    calls required to be made by the user.
% 
% 4) The optimized operational power splits can be accessed
%    by calling the following variable in the aircraft
%    structure:
% 
%        [Aircraft].Mission.History.SI.Power.Lambda.*
% 
%    where [Aircraft] is the name of the output variable.
%    simiarly, the design power split can be obtained by
%    accessing:
% 
%        [Aircraft].Specs.Power.Lambda*.SLS
% 
% 5) The objective function values for the operational power
%    split optimization are printed to the command window. The
%    objective for the design power split optimization is
%    stored in:
% 
%        [Aircraft].PowerOpt.ObjFunVal
% 
%    where [Aircraft] has the same meaning from note (4).
% 
% 6) The design power split optimizer has its own built-in
%    convergence tolerances, which cannot (currently) be
%    modified by the user. However, should a user desire,
%    the convergence tolerance and maximum number of
%    iterations can be changed by modifying Lines 49 and 52
%    in "InteriorPoint.m" (located in the "+OptimizationPkg").
% 
% 7) To allow convergence in the aircraft sizing code, the
%    tolerance was loosened by multiple orders of magnitude.
%    This is not expected to adversely impact the
%    optimization's results, particularly because FAST is an
%    early-phase conceptual design tool. In the future, the
%    aircraft sizing code will be improved to alleviate this
%    issue.
% 
%    Also, there are some cases in which the combined design/
%    operational power split optimziation fails to converge.
%    Therefore, it is not guaranteed (right now) that the
%    combined optimization problem will converge. The
%    individual optimization problems do converge.
% 
% 8) Right now, lots of information is printed to the command
%    window during the optimization. This is done primarily
%    to track the progress made in the optimizer (and to show
%    that it's not getting stuck anywhere). Also, some very
%    large (and possibly negative) numbers may be printed out.
%    Do not be alarmed, this is the optimizer finding the best
%    path forward in the design space (and is perfectly
%    normal). It is also assumed that the printouts could help
%    with debugging (if needed).
% 
%    If the user wishes to suppress the outputs, comment any
%    line in "EAPAnalysis.m" (located in the root directory)
%    and "OpsOptimize.m" (located in the "+OptimizationPkg")
%    that contains an "fprintf" statement.
% 
%    Additionally, some warnings may be thrown from the
%    mission analysis - especially when the optimizer tries to
%    find an optimal design (and makes the aircraft's engine
%    too small). It is okay to suppress all warnings in Matlab
%    while running this if the user doesn't want any text
%    printed to the command window.
% 
% 9) Please contact Paul Mokotoff (prmoko@umich.edu) with any
%    questions, issues, suggestions to improve the code, or
%    successes.
% 
% 
% ------------------------------------------------------------
% 
% end README
%
end