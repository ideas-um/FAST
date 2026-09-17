function [Success] = TestPropArchConnections()
%
% [Success] = TestPropArchConnections()
% written by Triet Ho
% last updated: 16 sep 2026
%
% Each engine sharing a propeller with electric motors must retain the
% complete list of companion motors, including when Driving is nonscalar.
%
% OUTPUTS:
%     Success - true when the one-, two-, three-, and nine-engine cases pass.
%               size/type/units: 1-by-1 / logical / []
%

EngineCounts = [1, 2, 3, 9];
Pass = false(size(EngineCounts));
for icase = 1:length(EngineCounts)
    neng = EngineCounts(icase);
    nsrc = 1;
    ntrn = neng + 3;
    prop = nsrc + ntrn;
    engines = nsrc + (1:neng);
    motors = nsrc + neng + (1:2);
    arch = zeros(nsrc + ntrn + 1);
    arch([engines, motors], prop) = 1;
    aircraft.Specs.Propulsion.PropArch.Arch = arch;
    aircraft.Specs.Propulsion.PropArch.SrcType = 1;
    aircraft.Specs.Propulsion.PropArch.TrnType = [ones(1, neng), 0, 0, 2];
    aircraft = PropulsionPkg.PropArchConnections(aircraft);
    connections = aircraft.Specs.Propulsion.PropArch.ParConns;
    Pass(icase) = all(cellfun(@(item) isequal(item, motors), connections(1:neng))) && ...
                  all(cellfun(@isempty, connections(neng + 1:end)));
end
Success = all(Pass);
if (~Success)
    fprintf(1, "PropArchConnections failed for engine count(s): %s\n", ...
            mat2str(EngineCounts(~Pass)));
end
end
