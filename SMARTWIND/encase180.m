function [output_angle] = encase180(input_angle)
if input_angle<=-180
    output_angle=input_angle+360;
elseif input_angle>180
    output_angle=input_angle-360;
else 
    output_angle=input_angle;
end
end