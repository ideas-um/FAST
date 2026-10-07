function [Aircraft] = B777300ER(Aircraft)
%
% [Aircraft] = B777300ER(Aircraft)
%
% Define the Boeing 777-300ER mission using FAST's standard turbofan
% mission profile.
%
% INPUTS:
%     Aircraft - aircraft structure without a mission profile.
%
% OUTPUTS:
%     Aircraft - aircraft structure with a mission profile.
%

Aircraft = MissionProfilesPkg.StandardTurbofanProfile(Aircraft);

end
