function [ModelDemand] = ResolveEngineDemand(Demand, IdleDemand, AllowShutdown)
%
% [ModelDemand] = ResolveEngineDemand(Demand, IdleDemand, AllowShutdown)
% written by Triet Ho
% last updated: 24 sep 2026
%
% Apply an engine idle floor without preventing deliberate electric-only
% operation. A nonzero electrical supplement alone is not an engine-off
% command; AllowShutdown must confirm that assistance covers the full
% demand and is large enough to represent intentional electric operation.
%
% INPUTS:
%     Demand          - target demand before the model supplement.
%                       size/type/units: n-by-1 / double / [N or W]
%
%     IdleDemand      - minimum net output for an operating engine.
%                       size/type/units: 1-by-1 / double / [N or W]
%
%     AllowShutdown   - true only where electric power covers the complete
%                       demand and the mission permits engine shutdown.
%                       size/type/units: n-by-1 / logical / []
%
% OUTPUTS:
%     ModelDemand     - gross demand passed to the engine model before it
%                       subtracts ModelSupplement.
%                       size/type/units: n-by-1 / double / [N or W]
%

NeedsIdle = (Demand < 1) & ~AllowShutdown;
ModelDemand = Demand;
ModelDemand(NeedsIdle) = IdleDemand;

end
