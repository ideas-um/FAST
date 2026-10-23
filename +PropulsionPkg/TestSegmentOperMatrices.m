function TestSegmentOperMatrices()
%
% Test segment-indexed operational-matrix selection and fallback behavior.
%

BaseUps = [0, 1; 0, 0];
BaseDwn = [0, 0; 1, 0];
ClimbUps = [0, 0.95; 0, 0];
ClimbDwn = [0, 0; 0.95, 0];

Aircraft.Specs.Propulsion.PropArch.OperUps = BaseUps;
Aircraft.Specs.Propulsion.PropArch.OperDwn = BaseDwn;
Aircraft.Mission.Profile.SegsID = 1;
[ActualUps, ActualDwn] = PropulsionPkg.SelectOperMatrices(Aircraft);
assert(isequal(ActualUps, BaseUps));
assert(isequal(ActualDwn, BaseDwn));

Aircraft.Specs.Propulsion.PropArch.OperUpsBySegment = {BaseUps; ClimbUps};
Aircraft.Specs.Propulsion.PropArch.OperDwnBySegment = {BaseDwn; ClimbDwn};
Aircraft.Mission.Profile.SegsID = 2;
[ActualUps, ActualDwn] = PropulsionPkg.SelectOperMatrices(Aircraft);
assert(isequal(ActualUps, ClimbUps));
assert(isequal(ActualDwn, ClimbDwn));
assert(isequal(PropulsionPkg.EvalSplit(ActualUps, 0.25), ClimbUps));

fprintf("Segment operational-matrix tests passed.\n");

end
