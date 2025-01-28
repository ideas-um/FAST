function [Aircraft] = PowerCode(Aircraft)

%
% [Aircraft] = PowerCode(Aircraft)
% written by Emma Cassidy, emmasmit@umich.edu
% last updated: 18 sep 2024
%
% Initialize power code for engine and electric motor
% -------------------------------------------------------------------------

% make altitude vector 
Profile = Aircraft.Mission.Profile;

% loop through segments 
for i = 1 : length(Profile.Segs)

    % get altitude distribution over each segement
    SegAlt = linspace(Profile.AltBeg(i), Profile.AltEnd(i), Profile.SegPts(i));

    % fill altitude in mission history 
    Aircraft.Mission.History.SI.Performance.Alt(Profile.SegBeg(i):Profile.SegEnd(i), 1) = SegAlt;

end

Alt = Aircraft.Mission.History.SI.Performance.Alt;

LamSLS = Aircraft.Specs.Power.LamTSPS.SLS;

% initialize power split array
npoints = length(Alt);

%Keep for later to override clear mission for optimization

if length(Aircraft.Specs.Power.PC.EM) == npoints
    Aircraft.Mission.History.SI.Power.PC(:,3) = Aircraft.Specs.Power.PC.EM;
    Aircraft.Mission.History.SI.Power.PC(:,4) = Aircraft.Specs.Power.PC.EM;


elseif LamSLS ~= 0

    PC = Aircraft.Specs.Power.PC.EM.Split;
    % get alt range from ac struct
    altPC = Aircraft.Specs.Power.PC.EM.Alt;

    % make tko PC = 100%
    tkoEnd = Aircraft.Mission.Profile.SegEnd(1);
    Aircraft.Mission.History.SI.Power.PC(1:tkoEnd-1, [3,4]) = 1;

    for j = 1:length(PC)
       
       % only one split given
       if isscalar(PC)
           code = PC;
           seg = altPC;
           % retrun if no altitude range given
           if isscalar(seg)
               return;
           end

       % multiple splits given    
       else
           code = PC{j};
           seg = altPC{j};
       end

       % convert feet to meters
       seg = UnitConversionPkg.ConvLength(seg, 'ft', 'm');

       BegDif = ((seg(1) - Alt) < 0);
       EndDif = ((seg(2) - Alt) < 0);
       SegBeg = find(BegDif, 1) - 1;
       SegEnd = find(EndDif, 1) - 1;
        
       % check if altitude entered is larger than cruise altitude
       % if so climb until start of cruise segment
       if isempty(SegEnd)
            CrsBeg = find(Aircraft.Mission.Profile.Segs == 'Cruise',1);
            SegEnd = Aircraft.Mission.Profile.SegBeg(CrsBeg) - 1;
       end

       npoints = SegEnd - SegBeg + 1;
       Aircraft.Mission.History.SI.Power.PC(SegBeg:SegEnd, [3,4]) = repmat(code, npoints, 2);
    end
    %Aircraft.Specs.Power.PC = Aircraft.Mission.History.SI.Power.PC;
end
end
