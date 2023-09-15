function [vector_prime]= rotation(point,centre,angle)
x1_offset=point(1)-centre(1);
x2_offset=point(2)-centre(2);
x1_prime=x1_offset*cosd(angle)-x2_offset*sind(angle)+centre(1);
x2_prime=x2_offset*cosd(angle)+x1_offset*sind(angle)+centre(2);
x3_prime=point(3);
vector_prime=[x1_prime,x2_prime,x3_prime];