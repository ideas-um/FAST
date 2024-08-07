function [Aircraft] = LamVSalt(Aircraft)

% lamtsps example = {[.05, .01], {"Takeoff", [0, 500]}} 
% means: tko 5% battery all the way through, then 1% up to 500 feet

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

   % initialize power split array
   npoints = length(Alt);
   Aircraft.Mission.History.SI.Power.(lams(i)) = zeros(npoints,1);
   
   if length(Aircraft.Specs.Power.(lams(i)).Split) == npoints
       Aircraft.Mission.History.SI.Power.(lams(i)) = Aircraft.Specs.Power.(lams(i)).Split;

   % check if a power split is designated
   elseif iscell(lam)

       % iterate through number of split segements
       for j = 1:length(lam{1})

           % power split values inputed by user
           split = lam{1}(j);
           % segements to put power splits over
           seg = lam{2}{j};

           % if gave alt range, fill inbetween
           if isnumeric(seg)
               % find beginning and ending index of altitude vector
               BegDif = ((seg(1) - Alt) < 0);
               EndDif = ((seg(2) - Alt) < 0);
               SegBeg = find(BegDif, 1) - 1;
               SegEnd = find(EndDif, 1) - 1;

               % eventually change that if the new segement index is lower
               % than the last one, dont override start at the next
               % biggest index that pasts the alt requirement
               
           % otherwise find end or beginning of segement
           else
               SegID = find(strcmp(Profile.Segs, seg));
               SegBeg = Profile.SegBeg(SegID);
               SegEnd = Profile.SegEnd(SegID);
           end
        
           % if split is an integer: segement is constant, if 2 values : linear
           splitType = length(split);
           npoints = SegEnd - SegBeg + 1;
           if splitType == 1
                Aircraft.Mission.History.SI.Power.(lams(i))(SegBeg:SegEnd) = linspace(split, split, npoints);
           else
                Aircraft.Mission.History.SI.Power.(lams(i))(SegBeg:SegEnd) = linspace(split(1), split(2), npoints);
           end
       end
   end
   Aircraft.Specs.Power.(lams(i)).Split = Aircraft.Mission.History.SI.Power.(lams(i));
   if max(Aircraft.Mission.History.SI.Power.(lams(i))) > Aircraft.Specs.Power.(lams(i)).SLS
        error("ERROR - a %s power split is greater than given %s SLS", lams(i), lams(i));
   end
end
end


