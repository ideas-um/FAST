function OutputFile = MakeUnoptimizedSequenceEightPanel(CheckpointFile, ...
        Technology_Whkg, OutputFile)
%MAKEUNOPTIMIZEDSEQUENCEEIGHTPANEL Plot conventional and unoptimized HEA only.

D = load(CheckpointFile, "Sequence", "MissionResults", ...
    "ChargeHistories", "FlightResults");
Cases = ["Conventional","Unoptimized"];
Labels = ["Conventional","Unoptimized HEA"];
Colors = [0.25 0.25 0.25; 0.4660 0.6740 0.1880];
Styles = [":" "--"];
for k = 1:numel(Cases)
    Timeline.(Cases(k)) = BuildTimeline(D.MissionResults, ...
        D.Sequence, Cases(k));
end
SOC = BuildSOCTimeline(D.MissionResults, D.ChargeHistories, ...
    D.Sequence, "Unoptimized");
Reference = Timeline.Unoptimized;

Fig = figure("Visible", "off", "Color", "w", ...
    "Position", [30 30 1800 1400]);
L = tiledlayout(Fig, 4, 2, "TileSpacing", "compact", ...
    "Padding", "compact");

PlotPanel(nexttile(L), Timeline, Cases, Labels, Colors, Styles, ...
    "Time_h", "Altitude_ft", 1/1000, "Altitude (kft)", ...
    "Mission altitude", Reference);
PlotPanel(nexttile(L), Timeline, Cases, Labels, Colors, Styles, ...
    "Time_h", "Speed_kts", 1, "True airspeed (kt)", ...
    "Mission speed", Reference);

Ax = nexttile(L); hold(Ax, "on");
PlotThinned(Ax, SOC.Time_h, SOC.SOC_pct, Styles(2), ...
    "LineWidth", 1.6, "Color", Colors(2,:), ...
    "DisplayName", Labels(2));
Decorate(Ax, Reference, "Battery SOC (%)", ...
    "Unoptimized HEA SOC with ground charging");
ylim(Ax, [0 105]); legend(Ax, "Location", "best");

PlotPanel(nexttile(L), Timeline, Cases, Labels, Colors, Styles, ...
    "FuelTime_h", "CumulativeFuel_kg", 1, ...
    "Cumulative fuel burn (kg)", "Main-mission fuel burn", Reference);
PlotPanel(nexttile(L), Timeline, Cases, Labels, Colors, Styles, ...
    "Time_h", "Preq_MW", 1, "Required power (MW)", ...
    "Required propulsion power", Reference);

Ax = nexttile(L); hold(Ax, "on");
C = Timeline.Unoptimized;
PlotThinned(Ax, C.Time_h, C.MotorUtilization, Styles(2), ...
    "LineWidth", 1.5, "Color", Colors(2,:), ...
    "DisplayName", Labels(2));
Decorate(Ax, Reference, "EM output / uncapped rating", ...
    "Electric-machine utilization");
ylim(Ax, [-0.03 1.05]); legend(Ax, "Location", "best");

PlotPanel(nexttile(L), Timeline, Cases, Labels, Colors, Styles, ...
    "Time_h", "MDotFuel_kgs", 1, "Fuel flow (kg/s)", ...
    "Total fuel mass flow", Reference);

Ax = nexttile(L); hold(Ax, "on");
F = D.FlightResults;
Conv = sortrows(F(string(F.CaseName)=="Conventional",:), "Flight");
Unopt = sortrows(F(string(F.CaseName)=="Unoptimized",:), "Flight");
n = min(height(Conv), height(Unopt));
FlightEnd_h = Reference.FlightEnd_h(1:n);
Saving_kg = cumsum(Conv.FuelBurn_kg(1:n) - Unopt.FuelBurn_kg(1:n));
stairs(Ax, [0; FlightEnd_h(:)], [0; Saving_kg(:)], ...
    "LineWidth", 1.8, "Color", Colors(2,:), ...
    "Marker", "o", "DisplayName", Labels(2));
Decorate(Ax, Reference, "Fuel saved vs conventional (kg)", ...
    "Exact cumulative saving at flight endpoints (higher is better)");
yline(Ax, 0, ":", "HandleVisibility", "off");
legend(Ax, "Location", "best");

for Ax = findall(Fig, "Type", "axes")'
    xlabel(Ax, "Elapsed sequence time including ground time (h)");
    StyleAxes(Ax);
end
S = sgtitle(L, sprintf("Sequence 8: fixed original HEA weight, " + ...
    "%d Wh/kg battery - unoptimized off-design operation", ...
    Technology_Whkg));
S.Color = "k";
OutputDir = fileparts(OutputFile);
if ~isfolder(OutputDir), mkdir(OutputDir); end
exportgraphics(Fig, OutputFile, "ContentType", "vector", ...
    "BackgroundColor", "white");
close(Fig);
end


function T = BuildTimeline(MissionResults, Sequence, CaseName)
nFlight = height(Sequence);
T = EmptyTimeline;
TimeOffset_s = 0; FuelOffset_kg = 0;
T.FlightStart_h = zeros(nFlight,1);
T.FlightEnd_h = zeros(nFlight,1);
for k = 1:nFlight
    R = MissionResults(k).(CaseName);
    H = R.MissionHistory.SI;
    Last = R.MainMissionEndIndex;
    LocalTime_s = H.Performance.Time(1:Last);
    LocalTime_s = LocalTime_s - LocalTime_s(1);
    Time_h = (TimeOffset_s + LocalTime_s) / 3600;
    T.FlightStart_h(k) = Time_h(1);
    T.FlightEnd_h(k) = Time_h(end);
    Fuel = FuelOffset_kg + H.Weight.Fburn(1:Last);
    nSrc = numel(R.PropArch.SrcType);
    iEM = find(R.PropArch.TrnType == 0);
    TrueLamUps = GetTrueLamUps(R,H,Last,nSrc);
    if isempty(iEM)
        Motor = nan(Last,1);
    else
        Motor = mean(TrueLamUps(:,iEM),2,"omitnan");
    end
    T.Time_h = [T.Time_h; Time_h(:); NaN];
    T.Altitude_ft = [T.Altitude_ft; H.Performance.Alt(1:Last)/0.3048; NaN];
    T.Speed_kts = [T.Speed_kts; H.Performance.TAS(1:Last)*1.943844; NaN];
    T.Preq_MW = [T.Preq_MW; H.Power.Preq(1:Last,end)/1e6; NaN];
    T.MDotFuel_kgs = [T.MDotFuel_kgs; ...
        sum(H.Propulsion.MDotFuel(1:Last,:),2); NaN];
    T.MotorUtilization = [T.MotorUtilization; Motor(:); NaN];
    T.FuelTime_h = [T.FuelTime_h; Time_h(:)];
    T.CumulativeFuel_kg = [T.CumulativeFuel_kg; Fuel(:)];
    FuelOffset_kg = Fuel(end);
    TimeOffset_s = TimeOffset_s + LocalTime_s(end);
    if k < nFlight
        Ground_s = Sequence.GROUND_TIME(k+1)*60;
        T.GroundStart_h(end+1,1) = TimeOffset_s/3600;
        T.GroundEnd_h(end+1,1) = (TimeOffset_s+Ground_s)/3600;
        T.FuelTime_h = [T.FuelTime_h; TimeOffset_s/3600; ...
            (TimeOffset_s+Ground_s)/3600];
        T.CumulativeFuel_kg = [T.CumulativeFuel_kg; FuelOffset_kg; FuelOffset_kg];
        TimeOffset_s = TimeOffset_s + Ground_s;
    end
end
end


function T = EmptyTimeline
for F = ["Time_h","Altitude_ft","Speed_kts","Preq_MW", ...
        "MDotFuel_kgs","MotorUtilization","FuelTime_h", ...
        "CumulativeFuel_kg"]
    T.(F) = [];
end
T.FlightStart_h=[]; T.FlightEnd_h=[];
T.GroundStart_h=[]; T.GroundEnd_h=[];
end


function V = GetTrueLamUps(R,H,Last,nSrc)
if isfield(R,"TrueLamUps"), A=R.TrueLamUps;
elseif isfield(R,"LamUpsFullRatedUtilization"), A=R.LamUpsFullRatedUtilization;
else
    Pout=H.Power.Pout(1:Last,:); Pav=H.Power.Pav(1:Last,:);
    A=zeros(size(Pout)); Valid=isfinite(Pout)&isfinite(Pav)&abs(Pav)>1e-9;
    A(Valid)=Pout(Valid)./Pav(Valid);
    Col=nSrc+(1:numel(R.PropArch.TrnType));
    A(:,Col)=A(:,Col).*R.LamUpsCommand(1:Last,:);
    A=min(max(A,0),1);
end
V=A(1:Last,nSrc+(1:numel(R.PropArch.TrnType)));
end


function T = BuildSOCTimeline(MissionResults,ChargeHistories,Sequence,CaseName)
T.Time_h=[]; T.SOC_pct=[]; Offset_s=0;
for k=1:height(Sequence)
    R=MissionResults(k).(CaseName); H=R.MissionHistory.SI;
    Last=R.MainMissionEndIndex; Batt=find(R.PropArch.SrcType==0,1);
    Ft=H.Performance.Time(1:Last); Ft=Ft-Ft(1);
    T.Time_h=[T.Time_h;(Offset_s+Ft(:))/3600];
    T.SOC_pct=[T.SOC_pct;H.Power.SOC(1:Last,Batt)];
    Offset_s=Offset_s+Ft(end);
    if k<height(Sequence)
        if isscalar(ChargeHistories)&&iscell(ChargeHistories.(CaseName))
            C=ChargeHistories.(CaseName){k};
        else
            C=ChargeHistories(k).(CaseName);
        end
        if isfield(C,"Time_s")&&isfield(C,"SOC")&&~isempty(C.Time_s)
            T.Time_h=[T.Time_h;(Offset_s+C.Time_s(:))/3600];
            T.SOC_pct=[T.SOC_pct;C.SOC(:)];
        end
        Offset_s=Offset_s+Sequence.GROUND_TIME(k+1)*60;
        if isfield(C,"SOCEnd")
            T.Time_h=[T.Time_h;Offset_s/3600]; T.SOC_pct=[T.SOC_pct;C.SOCEnd];
        end
    end
end
end


function PlotPanel(Ax,T,Cases,Labels,Colors,Styles,XF,YF,Scale,YL,TitleText,Ref)
hold(Ax,"on");
for k=1:numel(Cases)
    C=T.(Cases(k)); PlotThinned(Ax,C.(XF),Scale*C.(YF),Styles(k), ...
        "LineWidth",1.4,"Color",Colors(k,:),"DisplayName",Labels(k));
end
Decorate(Ax,Ref,YL,TitleText); legend(Ax,"Location","best");
end


function Decorate(Ax,Ref,YL,TitleText)
for k=1:numel(Ref.GroundStart_h)
    xregion(Ax,Ref.GroundStart_h(k),Ref.GroundEnd_h(k), ...
        "FaceColor",[.82 .82 .82],"FaceAlpha",.18, ...
        "EdgeColor",[.55 .55 .55],"HandleVisibility","off");
end
for k=2:numel(Ref.FlightStart_h)
    xline(Ax,Ref.FlightStart_h(k),":",sprintf("F%d",k), ...
        "HandleVisibility","off","LabelVerticalAlignment","bottom");
end
ylabel(Ax,YL); title(Ax,TitleText); grid(Ax,"on"); box(Ax,"on");
end


function PlotThinned(Ax,X,Y,varargin)
n=numel(X); MaxPoints=2500;
if n>MaxPoints
    Keep=unique([1;n;round(linspace(1,n,MaxPoints))'; ...
        find(~isfinite(X)|~isfinite(Y))]); X=X(Keep); Y=Y(Keep);
end
plot(Ax,X,Y,varargin{:});
end


function StyleAxes(Ax)
set(Ax,"Color","w","XColor","k","YColor","k", ...
    "GridColor",[.72 .72 .72]);
Ax.Title.Color="k"; Ax.XLabel.Color="k"; Ax.YLabel.Color="k";
if ~isempty(Ax.Legend), set(Ax.Legend,"Color","w","TextColor","k"); end
end
