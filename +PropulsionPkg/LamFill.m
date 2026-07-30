function [Aircraft] = LamFill(Aircraft)
%
% written by Emma Cassidy, emmasmit@umich.edu
% last updated 8/28/2025
% 
% Fill in lambda UPs and DWNs splits in mission history for each
% transmitter
%

%% Setup %%
%%%%%%%%%%%

% make altitude vector 
Profile = Aircraft.Mission.Profile;

Aircraft.Mission.History.SI.Performance.Alt = [];

% loop through segments 
for i = 1 : length(Profile.Segs)

    % get altitude distribution over each segement
    SegAlt = linspace(Profile.AltBeg(i), Profile.AltEnd(i), Profile.SegPts(i));

    % fill altitude in mission history 
    Aircraft.Mission.History.SI.Performance.Alt(Profile.SegBeg(i):Profile.SegEnd(i), 1) = SegAlt;

end

% save altitude for use
Alt = Aircraft.Mission.History.SI.Performance.Alt;
nlen = height(Alt);
TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;
%TrnType(TrnType==2) = [];
ntrans = length(TrnType);

% Start from the segment-level split inputs; this routine expands them into
% per-time-step, per-transmitter arrays used by PropAnalysis and sizing.
LamUps = Aircraft.Specs.Power.LamUps;
LamDwn = Aircraft.Specs.Power.LamDwn;

%% Fill in Lambda Mission Values %%

% check if lambda mission values already given
if isfield(LamUps, 'Miss')

% if no lambda mission filled, fill in based on Lam input
else
% This mapping is currently written for the PHE architecture layout:
% gas turbines, electric motors, and fans.

    % designate space for lambda mission array
    LamUps.Miss = zeros(nlen,ntrans);
    LamDwn.Miss = zeros(nlen,ntrans);

    % get transient types
    iEM = find(TrnType == 0);
    iGT = find(TrnType == 1);
    iFan= find(TrnType == 2);

    % collect mission profile information
    nsegs = length(Profile.Segs);
    
    for i = 1:nsegs
        
        Seg = Profile.Segs(i);
        % check segement type and get correct lambda chars
        if (Seg == 'Takeoff') || (Seg == 'DetailedTakeoff')
            lamseg = 'Tko';
        elseif Seg == 'Climb'
            lamseg = 'Clb';
        elseif Seg == 'Cruise'
            lamseg = 'Crs';
        elseif Seg == 'Descent'
            lamseg = 'Des';
        elseif Seg == 'Landing'
            lamseg = 'Lnd';
        elseif Seg == 'Taxi'|| (Seg == 'EWheelTaxi')
            lamseg = 'Tko';
        end

        % segement length
        npt = Profile.SegEnd(i)-Profile.SegBeg(i)+1;
        
        % Build one split row for this segment; LamUps is assigned directly
        % to electric motors, and LamDwn is balanced between electric motors,
        % gas turbines, and fans for the PHE architecture.
        ups = ones(1,ntrans);
        dwn = ones(1,ntrans);

        ups(iEM) = LamUps.(lamseg);
        % the rest of the ups will be determined later, assumes 1 for now
        dwn(iEM) = LamDwn.(lamseg);

        if ~isempty(iEM)
            dwn(iGT) = dwn(iGT) - dwn(iEM);
        end
        dwn(iFan) = 0.5;
        %{
        if Seg == 'Taxi'
            dwn(iGT)=[1,0];
            dwn(iFan)=[1,0];
        end
        %}
        % Propagate the segment split row through all mission points in the segment.
        LamUps.Miss(Profile.SegBeg(i):Profile.SegEnd(i), :) = repmat(ups,npt,1);
        LamDwn.Miss(Profile.SegBeg(i):Profile.SegEnd(i), :) = repmat(dwn,npt,1);
    
        %{
        if Profile.SegBeg(i) == 11
            LamDwn.Miss(11,[3,4]) = [0,0];
            LamDwn.Miss(11,[1,2]) = [1,1];

            LamUps.Miss(11,[3,4]) = [0,0];
        end
        %}
    end


end
    Aircraft.Specs.Power.LamUps = LamUps;
    Aircraft.Specs.Power.LamDwn = LamDwn;
    Aircraft.Mission.History.SI.Power.LamUps = LamUps.Miss;
    Aircraft.Mission.History.SI.Power.LamDwn = LamDwn.Miss;

end
