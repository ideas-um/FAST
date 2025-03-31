function [] = InitializeMotorDB()



[~,~,RawData] = xlsread(fullfile("+DatabasePkg", "+ElectricMotorPkg", "RawMotorData.xlsx"));


for ii = 4:size(RawData,1)
    for jj = 2:size(RawData,2)
        name = string((RawData{ii,1})) + "_KV" + string((RawData{ii,3}));
        ElectricMotors.(name).(RawData{2,jj}) =  RawData{ii,jj};

    end
end

for jj = 2:size(RawData,2)
    ElectricMotorUnitReference.(RawData{2,jj}) = RawData{3,jj};
end

save(fullfile("+DatabasePkg", "+ElectricMotorPkg", "IDEAS_EM_DB.mat"),'ElectricMotors','ElectricMotorUnitReference')

disp('Electric Motor Database has successfully been initialized.')
end

