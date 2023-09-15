function [coords,turbines,indexes] = extract_features_tc(input_chart)
[l,~]=size(input_chart);
coords=zeros(l,3);
for i=1:l
    coords(i,1)=input_chart{i,1}(1);
    coords(i,2)=input_chart{i,1}(2);
    coords(i,3)=input_chart{i,1}(3);
end
turbines=cell(l,1);
for i=1:l
    turbines{i,1}=input_chart{i,2};
end
indexes=zeros(l,1);
for i=1:l
    indexes(i,1)=input_chart{i,3};
end
end