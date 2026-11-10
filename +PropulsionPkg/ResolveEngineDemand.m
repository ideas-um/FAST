function [ModelDemand] = ResolveEngineDemand(Demand, IdleDemand, AllowShutdown)
%
% [ModelDemand] = ResolveEngineDemand(Demand, IdleDemand, AllowShutdown)
% written by Triet Ho
% last updated: 09 nov 2026
%
% Apply an engine idle floor without preventing deliberate electric-only
% operation. A nonzero electrical supplement alone is not an engine-off
% command; AllowShutdown must confirm that assistance covers the complete
% demand and the mission permits engine shutdown.
%
% INPUTS:
%     Demand        - target demand before the model supplement.
%                     size/type/units: numeric array / double / [N or W]
%
%     IdleDemand    - minimum output for an operating engine.
%                     size/type/units: scalar / double / [N or W]
%
%     AllowShutdown - true where electric power deliberately replaces the
%                     engine and mission rules permit shutdown.
%                     size/type/units: same as Demand / logical / []
%
% OUTPUTS:
%     ModelDemand   - gross demand passed to the engine model before it
%                     subtracts any applicable model supplement.
%                     size/type/units: same as Demand / double / [N or W]
%

NeedsIdle = (Demand < 1) & ~AllowShutdown;
ModelDemand = Demand;
ModelDemand(NeedsIdle) = IdleDemand;

end
