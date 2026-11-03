function [ComponentPower, PowerDeficit] = FullPowerLambdaConstraints(Aircraft, Pav, LamDwn, LamUps)
%
% [ComponentPower, PowerDeficit] = FullPowerLambdaConstraints(Aircraft,
% Pav, LamDwn, LamUps)
%
% Return full-power inequality residuals for parallel transmitter groups.
% Full-power mission points have no finite power request, so feasibility is
% determined by allocating the group's total available power according to
% the supplied downstream split. A positive residual means that allocation
% asks a component to provide more power than it has available.
%
% INPUTS:
%     Aircraft - aircraft containing the propulsion architecture and the
%                operational matrix for the current mission segment.
%     Pav      - available component power at each control point, W.
%     LamDwn   - supplied downstream split history.
%     LamUps   - upstream split history; rows with no active upstream split
%                do not participate in full-power split constraints.
%
% OUTPUTS:
%     ComponentPower - allocated minus available component power, W.
%     PowerDeficit   - largest parallel-component residual, W.
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

npnt = size(Pav, 1);
ncomp = size(Pav, 2);

if (size(LamDwn, 1) ~= npnt || size(LamUps, 1) ~= npnt)
    error("ERROR - FullPowerLambdaConstraints: split histories must match Pav rows.");
end

ComponentPower = zeros(npnt, ncomp);
PowerDeficit = zeros(npnt, 1);

PropArch = Aircraft.Specs.Propulsion.PropArch;
ParConns = PropArch.ParConns;
if (isempty(ParConns))
    return
end

Arch = PropArch.Arch;
[OperUps, OperDwn] = PropulsionPkg.SelectOperMatrices(Aircraft);
EtaUps = PropArch.EtaUps;
ActivePoint = any(LamUps > 0, 2);
ActiveComponent = false(1, ncomp);


%% COMPUTE PARALLEL-GROUP RESIDUALS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for ipar = 1:length(ParConns)
    Group = ParConns(ipar);
    imain = Group.Driving;
    isupp = Group.Helping;
    jdx = [imain, isupp(:)'];
    iups = Group.Target;

    if (~isscalar(iups) || ~all(Arch(jdx, iups) > 0))
        error("ERROR - FullPowerLambdaConstraints: invalid parallel connection group.");
    end

    for ipnt = find(ActivePoint)'
        SplitUps = PropulsionPkg.EvalSplit(OperUps, LamUps(ipnt, :));
        SplitDwn = PropulsionPkg.EvalSplit(OperDwn, LamDwn(ipnt, :));
        RoutedPower = Pav(ipnt, jdx) .* SplitUps(jdx, iups)';
        ReceivedPower = RoutedPower .* EtaUps(jdx, iups)';
        TotalReceived = sum(ReceivedPower);
        RequestedPower = TotalReceived .* SplitDwn(iups, jdx) ./ ...
                         EtaUps(jdx, iups)';
        GroupResidual = RequestedPower - RoutedPower;
        PreviouslyActive = ActiveComponent(jdx);
        ComponentPower(ipnt, jdx(PreviouslyActive)) = max( ...
            ComponentPower(ipnt, jdx(PreviouslyActive)), ...
            GroupResidual(PreviouslyActive));
        ComponentPower(ipnt, jdx(~PreviouslyActive)) = GroupResidual(~PreviouslyActive);
    end
    ActiveComponent(jdx) = true;
end

PowerDeficit(ActivePoint) = max(ComponentPower(ActivePoint, ActiveComponent), [], 2);

% ----------------------------------------------------------

end
