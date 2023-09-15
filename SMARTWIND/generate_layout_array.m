%GENERATE_LAYOUT_ARRAY is a function created to initialize a layout matrix
%of mxn turbines. If there two arguments as input to the function, it
%returns a mxm array with equal spacing in the relative x and y
%directions. If there are three arguments the turbine array can be rotated
%by angle. If the fourth and fifth arguments are specified there can be a
%mxn array with m different from n and also the spacing in the relative x
%and relative y direction can be different.

function layout = generate_layout_array(columns,spacing_x,angle,rows,...
    spacing_y)
switch nargin
    case 5 
        layout=zeros(columns*rows,3);
        vector_x=linspace(0,(columns-1)*spacing_x,columns);
        vector_y=linspace(0,(rows-1)*spacing_y,rows);
        layout(:,1)=repmat(vector_x',rows,1);
        layout(:,2)=repelem(vector_y',columns);    
        centre=[mean(vector_x) mean(vector_y)];
        for i=1:size(layout,1)
            layout(i,:)=rotation(layout(i,:),centre,encase360(angle-270));
        end
        layout(:,3)=[];
    case 4
        layout=zeros(columns*rows,3);
        vector_x=linspace(0,(columns-1)*spacing_x,columns);
        vector_y=linspace(0,(rows-1)*spacing_x,rows);
        layout(:,1)=repmat(vector_x',rows,1);
        layout(:,2)=repelem(vector_y',columns);    
        centre=[mean(vector_x) mean(vector_y)];
        for i=1:size(layout,1)
            layout(i,:)=rotation(layout(i,:),centre,encase360(angle-270));
        end
        layout(:,3)=[];
    case 3
        layout=zeros(columns^2,3);
        vector_x=linspace(0,(columns-1)*spacing_x,columns);
        vector_y=linspace(0,(columns-1)*spacing_x,columns);
        layout(:,1)=repmat(vector_x',columns,1);
        layout(:,2)=repelem(vector_y',columns);    
        centre=[mean(vector_x) mean(vector_y)];
        for i=1:size(layout,1)
            layout(i,:)=rotation(layout(i,:),centre,encase360(angle-270));
        end
        layout(:,3)=[];
    case 2
        layout=zeros(columns^2,2);
        vector_x=linspace(0,(columns-1)*spacing_x,columns);
        vector_y=linspace(0,(columns-1)*spacing_x,columns);
        layout(:,1)=repmat(vector_x',columns,1);
        layout(:,2)=repelem(vector_y',columns);    
end
end