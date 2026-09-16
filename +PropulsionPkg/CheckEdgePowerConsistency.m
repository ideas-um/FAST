function [] = CheckEdgePowerConsistency(Arch, LamUps, LamDwn, EtaUps, EtaDwn, SinkPower)
%
% [] = CheckEdgePowerConsistency(Arch, LamUps, LamDwn, EtaUps, EtaDwn, SinkPower)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Check that upstream and downstream matrices describe the same power on
% every active edge at one mission control point. Downstream propagation
% gives the component powers needed to meet the sink demand. Each edge's
% delivered power must then agree with upstream propagation from its source.
%
% INPUTS:
%     Arch      - source-to-target propulsion architecture matrix.
%                 size/type/units: n-by-n / logical or double / []
%     LamUps    - evaluated upstream operational matrix.
%                 size/type/units: n-by-n / double / []
%     LamDwn    - evaluated downstream operational matrix.
%                 size/type/units: n-by-n / double / []
%     EtaUps    - upstream edge efficiencies.
%                 size/type/units: n-by-n / double / []
%     EtaDwn    - downstream edge efficiencies.
%                 size/type/units: n-by-n / double / []
%     SinkPower - power required at the final sink.
%                 size/type/units: 1-by-1 / double / [W]
%
% OUTPUTS:
%     none; throws an error when an edge is inconsistent.
%

% An infinite demand is handled by PropAnalysis as an infeasible mission
% point, so it has no finite edge flow to compare.
if (isinf(SinkPower))
    return;
end

% Use the same downstream propagation as the mission analysis, including
% path losses, to recover power at every component from the sink demand.
ncomp = length(Arch);
Power = zeros(ncomp, 1);
Power(end) = SinkPower;
Power = PropulsionPkg.PowerFlow(Power, Arch', LamDwn, EtaDwn, -1);

% Compare delivered power on each source-to-target edge. The downstream
% split is a fraction of target demand; the upstream split is a fraction
% of source power and must include the upstream edge efficiency.
[Source, Target] = find(Arch);
DownIndex = sub2ind([ncomp, ncomp], Target, Source);
UpIndex = sub2ind([ncomp, ncomp], Source, Target);
DownEdge = Power(Target) .* LamDwn(DownIndex);
UpEdge = Power(Source) .* LamUps(UpIndex) .* EtaUps(UpIndex);

% Match PowerFlow's 1e-6 W convergence floor while allowing small
% relative rounding error at large power. Row sums alone cannot detect
% mismatched individual edge flows.
Tolerance = max(1.0e-06, 1.0e-08 * max(abs(DownEdge), abs(UpEdge)));
if (any(~isfinite(DownEdge)) || any(~isfinite(UpEdge)) || ...
        any(abs(DownEdge - UpEdge) > Tolerance))
    error("FAST:EdgePowerInconsistent", ...
          "Edge power is not consistent. Your power splits are over-constrained.");
end

end
