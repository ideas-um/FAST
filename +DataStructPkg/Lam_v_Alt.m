function [Aircraft] = Lam_v_Alt(Aircraft)

% wriiten by: Emma Cassidy, emmasmit@umich.edu
% last modified:
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

% type of prop architecture 
lams = ["LamTS", "LamTSPS", "LamPSPS", "LamPSES"];

for i = 1:4
   % get lambda type from ac struct
   lam = Aircraft.Specs.Power.(lams(i)).Split;

   % get alt range from ac struct
   altLam = Aircraft.Specs.Power.(lams(i)).Alt;

   % sls lambda
   lamSLS = Aircraft.Specs.Power.(lams(i)).SLS;

   % initialize power split array
   npoints = length(Alt);
   %Aircraft.Mission.History.SI.Power.(lams(i)) = zeros(npoints,1);
   
   % if split is already an array make mission hist equal to it
   if length(Aircraft.Specs.Power.(lams(i)).Split) == npoints
       Aircraft.Mission.History.SI.Power.(lams(i)) = Aircraft.Specs.Power.(lams(i)).Split;

   % check if an HEA is wanted 
   elseif lamSLS ~= 0

       % iterate through number of split segements
       for j = 1:length(lam)
           
           % only one split given
           if isscalar(lam)
               split = lam;
               seg = altLam;

           % multiple splits given    
           else
               split = lam{j};
               seg = altLam{j};
           end

           % convert feet to meters
           seg = UnitConversionPkg.ConvLength(seg, 'ft', 'm');

           % check if split designated for start of flight
           if seg(2) == 0
               SegBeg = 1; SegEnd = 9;
           
           else
                % find beginning and ending index of altitude vector
               BegDif = ((seg(1) - Alt) < 0);
               EndDif = ((seg(2) - Alt) < 0);
               SegBeg = find(BegDif, 1) - 1;
               SegEnd = find(EndDif, 1) - 1;
           end

               % eventually change that if the new segement index is lower
               % than the last one, dont override start at the next
               % biggest index that pasts the alt requirement

           npoints = SegEnd - SegBeg + 1;
           Aircraft.Mission.History.SI.Power.(lams(i))(SegBeg:SegEnd) = linspace(split, split, npoints);

       end
     Aircraft.Specs.Power.(lams(i)).Split = Aircraft.Mission.History.SI.Power.(lams(i));
   end

   % add some check if power required excceeds power avaliable
   
end
end


