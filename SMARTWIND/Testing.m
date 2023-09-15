%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_1%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface();
% swi.windfield.wake.velocity_model='Jensen';
% swi.windfield.wake.deflection_model='Jimenez';
% swi.windfield.enable_wfr='yes';
% swi.windfield.resolution=[250 150 50];
% swi.calculate_nowake();
% a=swi.get_farm_power;
% swi.calculate_wake();
% b=swi.get_farm_power;
% efficiency=b/a;
% c=swi.get_turbines_power;
% d=swi.get_turbines_velocity;
% e=swi.get_turbines_turbulence;
% figure
% swi.show_horplane(90);
% disp(c)
% disp(d)
% disp(e)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_2%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface();
% swi.windfield.wake.velocity_model='Gauss';
% swi.windfield.wake.deflection_model='Gauss';
% swi.windfield.enable_wfr='yes';
% swi.windfield.resolution=[500 300 100];
% swi.calculate_wake();
% figure
% swi.show_horplane(90);
% figure
% swi.show_verplane(10);
% figure
% swi.show_crossplane(630);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_3%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface();
% swi.windfield.wind_direction=330;
% swi.windfield.enable_wfr='yes';
% swi.windfield.resolution=[250 150 50];
% swi.calculate_wake();
% figure
% swi.show_horplane(90);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_4%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface();
% swi.set_yaw_angles([-10 0 -25 0]);
% swi.windfield.enable_wfr='yes';
% swi.windfield.resolution=[250 150 50];
% swi.calculate_wake();
% figure
% swi.show_horplane(90);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_5%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface();
% swi.windfield.resolution=[250 150 50];
% matrix=zeros(26,2);
% for i=1:26
%     matrix(i,1)=i-1;
%     swi.set_yaw_angles([1-i 0 1-i 0]);
%     swi.calculate_wake();
%     matrix(i,2)=swi.get_farm_power;
% end
% plot(matrix(:,1),matrix(:,2));
% xlabel('Turbine 1 and Turbine 3 Yaw Angles')
% ylabel('Farm Power')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_6%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface;
% a=swi.windfield.turbinechart.turbines{1,1}.rotor_diameter;
% layout=generate_layout_array(4,4*a);
% swi.set_layout(layout);
% swi.windfield.enable_wfr='yes';
% swi.windfield.resolution=[250 150 50];
% swi.calculate_wake();
% figure
% swi.show_horplane(90);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_7%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface;
% swi.exclude_turbines([3,2]);
% swi.windfield.enable_wfr='yes';
% swi.windfield.resolution=[250 150 50];
% swi.calculate_wake();
% figure
% swi.show_horplane(90);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_8%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface();
% swi.load_winddata_o3();
% figure
% swi.plot_wspeeds();
% figure
% swi.plot_wdirections();
% figure
% swi.plot_windrose();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_9%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface();
% swi.load_winddata_o3();
% swi.calculate_aep_nowake();
% swi.calculate_aep_baseline();
% swi.report_energies();
% figure
% swi.plot_aep_wspeeds();
% figure
% swi.plot_aep_wdirections();
% figure
% swi.plot_eff_wdirections(6);
% figure
% swi.plot_eff_wdirections(10);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_10%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface();
% rng("default")
% layout=generate_random_layout_array(8,1400,1400,500);
% swi.set_layout(layout);
% tic
% swi.yaw_optimization_gb();
% toc
% p1=swi.get_farm_power();
% y1=swi.get_yaw_angles();
% swi.reset_farm_keep_layout();
% swi.yaw_optimization_ga();
% p2=swi.get_farm_power();
% y2=swi.get_yaw_angles();
% swi.reset_farm_keep_layout();
% tic
% swi.yaw_optimization_sq();
% toc
% p3=swi.get_farm_power();
% y3=swi.get_yaw_angles();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_11%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface();
% rng("default")
% layout=generate_random_layout_array(8,1400,1400,500);
% swi.set_layout(layout);
% swi.ya_options=6;
% swi.yaw_optimization_miga();
% p4=swi.get_farm_power();
% y4=swi.get_yaw_angles();
% swi.reset_farm_keep_layout();
% swi.ya_options=6;
% swi.yaw_optimization_sq();
% p5=swi.get_farm_power();
% y5=swi.get_yaw_angles();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_12%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface();
% rng("default")
% layout=generate_random_layout_array(8,1400,1400,500);
% swi.set_layout(layout);
% swi.exclude_turbines([4,6]);
% swi.yaw_optimization_sq();
% p=swi.get_farm_power();
% y=swi.get_yaw_angles();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TEST_13%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% swi=SmartWindInterface();
% swi.load_winddata_o3();
% swi.ya_options=2;
% swi.calculate_aep_optimized();
% swi.report_energies_opt();
% figure()
% swi.plot_gain_wdirections(5);
% figure()
% swi.plot_gain_wdirections(7);
% figure()
% swi.plot_gain_wdirections(9);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%







