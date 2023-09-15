%GENERATE_RANDOM_LAYOUT_ARRAY is a function that returns a random
%disposition of turbines in an area constrained between zero and x_max and
%y_max. The distance constraint is useful to cancel the risk that 2
%turbines are too close between each other.

function layout = generate_random_layout_array(n_turbs,x_max,y_max,...
    distance_constraint)
   rng default
   layout=zeros(n_turbs,2);
   layout(:,1)=x_max*rand(n_turbs,1);
   layout(:,2)=y_max*rand(n_turbs,1);
   for i=2:n_turbs
       distance_matrix=zeros(1,i-1);
       for j=1:i-1
           distance_matrix(j)=sqrt((layout(i,1)-layout(j,1))^2+...
               (layout(i,2)-layout(j,2))^2);
       end
       while any(distance_matrix<distance_constraint)
             layout(i,1)=x_max*rand(1);
             layout(i,2)=y_max*rand(1);
             for j=1:i-1
                 distance_matrix(j)=sqrt((layout(i,1)-layout(j,1))^2 ...
                     +(layout(i,2)-layout(j,2))^2);
             end   
       end
   end
end