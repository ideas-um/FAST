function [Success] = TestEdgePowerConsistency()
%
% [Success] = TestEdgePowerConsistency()
% written by Triet Ho
% last updated: 16 sep 2026
%
% Stress test edge-flow agreement between upstream and downstream power
% splits, including asymmetric branches, losses, and mission rejection.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Success - 1 when every consistency check passes, otherwise 0.
%               size/type/units: 1-by-1 / int / []
%

%% TEST CASE SETUP %%
%%%%%%%%%%%%%%%%%%%%%

Pass = false(9, 1);
[Arch, LamUps, LamDwn, EtaUps, EtaDwn] = makeParallelMotorGraph(0.5, 0.5);

%% CONSISTENT EDGE FLOWS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Equal branches and asymmetric but matched branches both conserve power.
Pass(1) = CheckAccepted(Arch, LamUps, LamDwn, EtaUps, EtaDwn, 100);
[Arch, LamUps, LamDwn, EtaUps, EtaDwn] = makeParallelMotorGraph(0.7, 0.7);
Pass(2) = CheckAccepted(Arch, LamUps, LamDwn, EtaUps, EtaDwn, 100);

% With losses, the source split is normalized by required input power,
% so it differs from the downstream split at the shared target.
TargetShare = 0.6;
MotorInput = TargetShare / 0.8;
OtherInput = 1 - TargetShare;
SourceShare = MotorInput / (MotorInput + OtherInput);
[Arch, LamUps, LamDwn, EtaUps, EtaDwn] = ...
    makeParallelMotorGraph(SourceShare, TargetShare);
EtaUps(2, 4) = 0.8;
EtaDwn(4, 2) = 0.8;
Pass(3) = CheckAccepted(Arch, LamUps, LamDwn, EtaUps, EtaDwn, 100);

% A zero-demand point has no physical edge flow to contradict the splits.
Pass(4) = CheckAccepted(Arch, LamUps, LamDwn, EtaUps, EtaDwn, 0);

%% INCONSISTENT EDGE FLOWS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Both directions normalize to one, but they assign opposite branch power.
[Arch, LamUps, LamDwn, EtaUps, EtaDwn] = makeParallelMotorGraph(0.7, 0.3);
Pass(5) = CheckRejected(Arch, LamUps, LamDwn, EtaUps, EtaDwn, 100);

% Matching split fractions cannot compensate for unequal path efficiencies.
[Arch, LamUps, LamDwn, EtaUps, EtaDwn] = makeParallelMotorGraph(0.5, 0.5);
EtaUps(2, 4) = 0.8;
EtaDwn(4, 2) = 0.8;
Pass(6) = CheckRejected(Arch, LamUps, LamDwn, EtaUps, EtaDwn, 100);

% Even a correctly adjusted split must reject incompatible efficiencies.
[Arch, LamUps, LamDwn, EtaUps, EtaDwn] = ...
    makeParallelMotorGraph(SourceShare, TargetShare);
EtaUps(2, 4) = 0.9;
EtaDwn(4, 2) = 0.8;
Pass(7) = CheckRejected(Arch, LamUps, LamDwn, EtaUps, EtaDwn, 100);

% A single edge that is active in only one direction must also fail.
[Arch, LamUps, LamDwn, EtaUps, EtaDwn] = makeParallelMotorGraph(1, 0);
Pass(8) = CheckRejected(Arch, LamUps, LamDwn, EtaUps, EtaDwn, 100);

% Mission analysis must surface the same rejection, not only the helper.
Aircraft = makeMissionPoint(Arch, LamUps, LamDwn, EtaUps, EtaDwn);
Pass(9) = CheckMissionRejected(Aircraft);

%% CHECK THE TEST RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Success = all(Pass);
if (Success)
    fprintf(1, "EdgePowerConsistency tests passed!\n");
else
    fprintf(1, "EdgePowerConsistency tests failed:\n");
    fprintf(1, "    Test %d\n", find(~Pass));
end

end

function [Arch, LamUps, LamDwn, EtaUps, EtaDwn] = makeParallelMotorGraph(SourceShare, TargetShare)
%
% [Arch, LamUps, LamDwn, EtaUps, EtaDwn] = makeParallelMotorGraph(SourceShare, TargetShare)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Build battery -> two motors -> propeller -> thrust, with independent
% source-side and target-side split fractions.
%
% INPUTS:
%     SourceShare - fraction of battery power routed to the first motor.
%                   size/type/units: 1-by-1 / double / []
%     TargetShare - fraction of propeller power supplied by first motor.
%                   size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     Arch        - source-to-target architecture matrix.
%                   size/type/units: 5-by-5 / double / []
%     LamUps      - upstream operational matrix.
%                   size/type/units: 5-by-5 / double / []
%     LamDwn      - downstream operational matrix.
%                   size/type/units: 5-by-5 / double / []
%     EtaUps      - upstream efficiency matrix.
%                   size/type/units: 5-by-5 / double / []
%     EtaDwn      - downstream efficiency matrix.
%                   size/type/units: 5-by-5 / double / []
%

Arch = zeros(5);
Arch(1, 2:3) = 1;
Arch(2:3, 4) = 1;
Arch(4, 5) = 1;
LamUps = zeros(5);
LamUps(1, 2:3) = [SourceShare, 1 - SourceShare];
LamUps(2:3, 4) = 1;
LamUps(4, 5) = 1;
LamDwn = zeros(5);
LamDwn(2:3, 1) = 1;
LamDwn(4, 2:3) = [TargetShare, 1 - TargetShare];
LamDwn(5, 4) = 1;
EtaUps = ones(5);
EtaDwn = ones(5);
end

function Pass = CheckAccepted(Arch, LamUps, LamDwn, EtaUps, EtaDwn, SinkPower)
%
% Pass = CheckAccepted(Arch, LamUps, LamDwn, EtaUps, EtaDwn, SinkPower)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Return true only if a physically consistent point is accepted.
%
% INPUTS:
%     Arch, LamUps, LamDwn, EtaUps, EtaDwn - matrices defined above.
%     SinkPower - final sink demand in watts.
%
% OUTPUTS:
%     Pass - true if validation returns without an error.
%            size/type/units: 1-by-1 / logical / []
%

Pass = true;
try
    PropulsionPkg.CheckEdgePowerConsistency( ...
        Arch, LamUps, LamDwn, EtaUps, EtaDwn, SinkPower);
catch
    Pass = false;
end
end

function Pass = CheckRejected(Arch, LamUps, LamDwn, EtaUps, EtaDwn, SinkPower)
%
% Pass = CheckRejected(Arch, LamUps, LamDwn, EtaUps, EtaDwn, SinkPower)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Return true only when an inconsistent point produces the requested error.
%
% INPUTS:
%     Arch, LamUps, LamDwn, EtaUps, EtaDwn - matrices defined above.
%     SinkPower - final sink demand in watts.
%
% OUTPUTS:
%     Pass - true if the specific inconsistency error is raised.
%            size/type/units: 1-by-1 / logical / []
%

Pass = false;
try
    PropulsionPkg.CheckEdgePowerConsistency( ...
        Arch, LamUps, LamDwn, EtaUps, EtaDwn, SinkPower);
catch Error
    Pass = strcmp(Error.identifier, "FAST:EdgePowerInconsistent") && ...
           strcmp(Error.message, ...
                  "Edge power is not consistent. Your power splits are over-constrained.");
end
end

function Aircraft = makeMissionPoint(Arch, LamUps, LamDwn, EtaUps, EtaDwn)
%
% Aircraft = makeMissionPoint(Arch, LamUps, LamDwn, EtaUps, EtaDwn)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Supply the mission fields needed before PropAnalysis validates edge flow.
%
% INPUTS:
%     Arch, LamUps, LamDwn, EtaUps, EtaDwn - matrices defined above.
%
% OUTPUTS:
%     Aircraft - minimal propulsion and mission structure for rejection.
%                size/type/units: 1-by-1 / struct / []
%

Aircraft.Specs.TLAR.Class = "Turboprop";
Aircraft.Specs.Power.SpecEnergy.Fuel = 1;
Aircraft.Specs.Propulsion.PropArch.Type = "E";
Aircraft.Specs.Propulsion.PropArch.SrcType = 0;
Aircraft.Specs.Propulsion.PropArch.TrnType = [0, 0, 2];
Aircraft.Specs.Propulsion.PropArch.Arch = Arch;
Aircraft.Specs.Propulsion.PropArch.OperUps = @() LamUps;
Aircraft.Specs.Propulsion.PropArch.OperDwn = @() LamDwn;
Aircraft.Specs.Propulsion.PropArch.EtaUps = EtaUps;
Aircraft.Specs.Propulsion.PropArch.EtaDwn = EtaDwn;
Aircraft.Specs.Propulsion.PropArch.WhichProp = repmat({[]}, 1, 3);
Aircraft.Mission.Profile.SegsID = 1;
Aircraft.Mission.Profile.SegBeg = 1;
Aircraft.Mission.Profile.SegEnd = 1;
Aircraft.Mission.Profile.MissID = 1;
Aircraft.Mission.History.SI.Power.Req = 100;
Aircraft.Mission.History.SI.Power.Pav = zeros(1, 5);
Aircraft.Mission.History.SI.Power.LamUps = zeros(1, 0);
Aircraft.Mission.History.SI.Power.LamDwn = zeros(1, 0);
Aircraft.Mission.History.SI.Power.Windmill = false(1, 3);
end

function Pass = CheckMissionRejected(Aircraft)
%
% Pass = CheckMissionRejected(Aircraft)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Confirm that the mission entry point rejects mismatched edge power.
%
% INPUTS:
%     Aircraft - minimal inconsistent mission point.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Pass     - true if the specific inconsistency error is raised.
%                size/type/units: 1-by-1 / logical / []
%

Pass = false;
try
    PropulsionPkg.PropAnalysis(Aircraft);
catch Error
    Pass = strcmp(Error.identifier, "FAST:EdgePowerInconsistent") && ...
           strcmp(Error.message, ...
                  "Edge power is not consistent. Your power splits are over-constrained.");
end
end
