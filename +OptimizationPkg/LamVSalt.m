function [Aircraft] = LamVSalt(Aircraft)

% lamtsps example = Aircraft.Specs.Power.LamTSPS.Split = .05
%                   Aircraft.SPecs.Power.LamTSPS.Alt = [0,5000]
% means: 5% split from 0 to 5000 ft

% adaptive power management

%-----------------------------------------------------------------------------
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

% fill lambda split vector
% what type of splits is ac struct asking for 
lams = ["LamTS", "LamTSPS", "LamPSPS", "LamPSES"];
for i = 1:4
   % get lambda type from ac struct
   lam = Aircraft.Specs.Power.(lams(i)).Split;

   % get alt range
   altLam = Aircraft.Specs.Power.(lams(i)).Alt;

   % initialize power split array
   npoints = length(Alt);
   Aircraft.Mission.History.SI.Power.(lams(i)) = zeros(npoints,1);
   
   % if split is already an array make mission hist equal to it
   if length(Aircraft.Specs.Power.(lams(i)).Split) == npoints
       Aircraft.Mission.History.SI.Power.(lams(i)) = Aircraft.Specs.Power.(lams(i)).Split;

   % check if a power split v alt is designated
   elseif lam ~= 0
        
       % check to see if designated multiple splits
       if iscell(lam)

           % iterate through number of split segements
           for j = 1:length(lam)

               % power split values inputed by user
               split = lam{j};

               % segements to put power splits over
               seg = altLam{j};

               % convert feet to meters
               seg = UnitConversionPkg.ConvLength(seg, 'ft', 'm');
    
               % find beginning and ending index of altitude vector
               BegDif = ((seg(1) - Alt) < 0);
               EndDif = ((seg(2) - Alt) < 0);
               SegBeg = find(BegDif, 1) - 1;
               SegEnd = find(EndDif, 1) - 1;
    
                   % eventually change that if the new segement index is lower
                   % than the last one, dont override start at the next
                   % biggest index that pasts the alt requirement
    
               npoints = SegEnd - SegBeg + 1;
               Aircraft.Mission.History.SI.Power.(lams(i))(SegBeg:SegEnd) = linspace(split, split, npoints);
           end

       % only one split designated 
       else
         % power split values inputed by user
           split = lam;

           % segements to put power splits over
           seg = altLam;

           % convert feet to meters
           seg = UnitConversionPkg.ConvLength(seg, 'ft', 'm');

           % find beginning and ending index of altitude vector
           BegDif = ((seg(1) - Alt) < 0);
           EndDif = ((seg(2) - Alt) < 0);
           SegBeg = find(BegDif, 1) - 1;
           SegEnd = find(EndDif, 1) - 1;

           npoints = SegEnd - SegBeg + 1;
           Aircraft.Mission.History.SI.Power.(lams(i))(SegBeg:SegEnd) = linspace(split, split, npoints);
       end
   end

   Aircraft.Specs.Power.(lams(i)).Split = Aircraft.Mission.History.SI.Power.(lams(i));
   if max(Aircraft.Mission.History.SI.Power.(lams(i))) > Aircraft.Specs.Power.(lams(i)).SLS
        error("ERROR - a %s power split is greater than given %s SLS", lams(i), lams(i));
   end
end
end


