function [OperUps, OperDwn] = SelectOperMatrices(Aircraft)
%
% [OperUps, OperDwn] = SelectOperMatrices(Aircraft)
% written by Triet Ho
% last updated: 22 sep 2026
%
% Select the operational matrices for the mission segment currently being
% evaluated. If no segment-indexed matrices are supplied, use the original
% architecture-level matrices for backward compatibility and SLS sizing.
%
% INPUTS:
%     Aircraft - structure containing the propulsion architecture and the
%                current mission segment identifier.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     OperUps - upstream operational matrix or function.
%               size/type/units: n-by-n or 1-by-1 / double or function handle / []
%
%     OperDwn - downstream operational matrix or function.
%               size/type/units: n-by-n or 1-by-1 / double or function handle / []
%

PropArch = Aircraft.Specs.Propulsion.PropArch;
OperUps = PropArch.OperUps;
OperDwn = PropArch.OperDwn;

HaveUps = isfield(PropArch, "OperUpsBySegment");
HaveDwn = isfield(PropArch, "OperDwnBySegment");
if (~HaveUps && ~HaveDwn)
    return
end
if (~HaveUps || ~HaveDwn)
    error("FAST:IncompleteSegmentOperMatrices", ...
          "OperUpsBySegment and OperDwnBySegment must be supplied together.");
end
if (~isfield(Aircraft.Mission.Profile, "SegsID"))
    error("FAST:MissingSegmentID", ...
          "A current mission segment ID is required to select operational matrices.");
end

SegsID = Aircraft.Mission.Profile.SegsID;
if (~isscalar(SegsID) || SegsID < 1 || SegsID ~= floor(SegsID) || ...
    SegsID > numel(PropArch.OperUpsBySegment) || ...
    SegsID > numel(PropArch.OperDwnBySegment))
    error("FAST:InvalidSegmentID", ...
          "Mission segment ID %g does not identify a segment operational matrix.", SegsID);
end

OperUps = PropArch.OperUpsBySegment{SegsID};
OperDwn = PropArch.OperDwnBySegment{SegsID};

end
