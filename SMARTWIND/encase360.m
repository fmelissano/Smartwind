function [output_angle] = encase360(input_angle)
if input_angle<0
    output_angle=input_angle+360;
elseif input_angle>=360
    output_angle=input_angle-360;
else 
    output_angle=input_angle;
end
end