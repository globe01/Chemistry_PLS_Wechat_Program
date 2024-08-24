function [Data] = mncn(Data)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

for i = 1:size(Data,1)
	  Data(i, :) = Data(i, :) - mean(Data);
end

end

