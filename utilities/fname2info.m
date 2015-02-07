function [rig, exp_date] = fname2info( fname )
%Get date and rig from the file name of Symphony
%   Detailed explanation goes here
    if nargin == 0
        fname = '/Users/dtakeshi/rawData/012715Ac1.h5';
    end
    [file_path, file_name, ext]=fileparts(fname);
    rig = file_name(end-2);
    str = file_name(1:end-3);
    if length(str)==6
        yr = str2num(str(5:6))+2000;%Asuume no symphony before 2000:)
        mth = str2num(str(1:2));
        dt = str2num(str(3:4)); 
    end
    exp_date = [yr, mth, dt];
end

