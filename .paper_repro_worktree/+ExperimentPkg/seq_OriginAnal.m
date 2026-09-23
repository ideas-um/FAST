clc;
clear;
% analyze sequences
load("+ExperimentPkg\Sequences.mat")
org = strings(0);
place = string(0);

for i = 1: length(tables)
    seq = tables{i};
    for j = 1: height(seq)
       str =  string(seq.ORIGIN{j});
       str2 = string(seq.ORIGIN_CITY_NAME{j});
       org(end+1) = str;
       place(end+1) = str2;
    end

end