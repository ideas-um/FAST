function [ComponentPower, PowerDeficit] = PowerManagementConstraints(Preq, Pav, ComponentIndex)
%
% [ComponentPower, PowerDeficit] = PowerManagementConstraints(Preq, Pav,
% ComponentIndex)
%
% Return inequality-constraint residuals for a supplied power allocation.
% A residual is feasible when it is less than or equal to zero. The
% component residuals retain the architecture layout, while PowerDeficit
% consolidates the largest residual among components that transmit power
% to the aircraft sink.
%
% INPUTS:
%     Preq           - power required from each architecture component.
%     Pav            - power available from each architecture component.
%     ComponentIndex - columns containing transmitters and sinks.
%
% OUTPUTS:
%     ComponentPower - required minus available component power.
%     PowerDeficit   - largest active component residual at each point.
%


%% COMPUTE CONSTRAINT RESIDUALS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isequal(size(Preq), size(Pav)))
    error("ERROR - PowerManagementConstraints: Preq and Pav must have the same size.");
end

if (isempty(ComponentIndex))
    error("ERROR - PowerManagementConstraints: at least one component index is required.");
end

if (any(ComponentIndex < 1) || any(ComponentIndex > size(Preq, 2)))
    error("ERROR - PowerManagementConstraints: component index is out of bounds.");
end

ComponentPower = Preq - Pav;
PowerDeficit = max(ComponentPower(:, ComponentIndex), [], 2);

% ----------------------------------------------------------

end
