function [Success] = TestSegmentOperMatrices()
%
% [Success] = TestSegmentOperMatrices()
% written by Triet Ho
% last updated: 22 sep 2026
%
% Confirm that FAST selects direct numeric operational matrices by mission
% segment while preserving the architecture-level fallback.
%
% OUTPUTS:
%     Success - true when all segment selection checks pass.
%               size/type/units: 1-by-1 / logical / []
%

BaseUps = [0, 1; 0, 0];
BaseDwn = [0, 0; 1, 0];
ClimbUps = [0, 0.95; 0, 0];
ClimbDwn = [0, 0; 0.95, 0];

Aircraft.Specs.Propulsion.PropArch.OperUps = BaseUps;
Aircraft.Specs.Propulsion.PropArch.OperDwn = BaseDwn;
Aircraft.Mission.Profile.SegsID = 1;
[ActualUps, ActualDwn] = PropulsionPkg.SelectOperMatrices(Aircraft);
Success = isequal(ActualUps, BaseUps) && isequal(ActualDwn, BaseDwn);

Aircraft.Specs.Propulsion.PropArch.OperUpsBySegment = {BaseUps; ClimbUps};
Aircraft.Specs.Propulsion.PropArch.OperDwnBySegment = {BaseDwn; ClimbDwn};
Aircraft.Mission.Profile.SegsID = 2;
[ActualUps, ActualDwn] = PropulsionPkg.SelectOperMatrices(Aircraft);
Success = Success && isequal(ActualUps, ClimbUps) && ...
          isequal(ActualDwn, ClimbDwn);
Success = Success && isequal(PropulsionPkg.EvalSplit(ActualUps, 0.25), ClimbUps);

end
