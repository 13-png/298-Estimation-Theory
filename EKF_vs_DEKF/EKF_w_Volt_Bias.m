%% MAE 298 Estimation Project Matlab Script

%% Extended Kalman Filter: DP Model_ Third Order Truth 

clear all, clc
% Import Battery Parameters 
% BatteryParams    

C1 = 1000; 
C2 = 2500; 
R1 = .015; 
R2 = .0015; 
% R0 = .02402; 
R0=0.001;
alpha = .65; 
Cbat = 5*3600; 


Tau1 = C1*R1; 
Tau2 = C2*R2; 

dt = .1; 

% System Dynamics

% Linear State Dynamics: Dual Polarity Model 

% Continuous Time Model: 
A_c = [0       0         0 ; ...
     0  (-1/(R1*C1))   0 ;... 
     0       0    (-1/(R2*C2))]; 
B_c = [(-1/Cbat); (1/C1); (1/C2)]; 
C_c = [alpha -1 -1 ];
D_c = [-R0]; 

sys = ss(A_c,B_c,C_c,D_c); 

sys_d= c2d(sys,dt);

% Discrete Time Model: 

Ad = [1      0        0 ; ...
     0 exp(-dt/Tau1) 0 ; ...
     0      0   exp(-dt/Tau2)]; 
Bd = [(-dt/Cbat); (R1)*(1-exp(-dt/Tau1)); (R2)*(1-exp(-dt/Tau2))]; 
Cd = C_c; 
Dd = D_c; 



% Import Kalman Parameters
% KalmanParams


wk_mean = 0; 
Q = 2.5*10^-7;

vk_mean = 0; 
R = 1*10^-4;

A_ek = 1 ;
E_ek = 1; 
F_ek = 1; 

% 
% Q = 1; 
% R = 10000;

% Load Battery Measurements 
load('OCV_table.mat')
load('OCV_slope_table.mat')
% load('ThreeRCModel_Validation_Data.mat')
load('C:\Users\felip\Documents\298-Estimation-Theory\EKF_vs_DEKF\DataFiles\Sim_Truth_ThirdOrder_with_Bias.mat')

% Initial Conditions: 
P(1) = 0;           % Covariance 
x1(1) = .98;        % SOC - Battery Fully Charged 
x2(1) = 0;          % Vc1
x3(1) = 0;          % Vc2

x1_hat(1) = x1(1); 

for k = 2:1:length(t)
    
    x1(k) = Ad(1,1)*x1(k-1) + Bd(1,1)*I(k-1); % soc
    x2(k) = Ad(2,2)*x2(k-1) + Bd(2,1)*I(k-1); % Vc1
    x3(k) = Ad(3,3)*x3(k-1) + Bd(3,1)*I(k-1); % Vc2
    
    % Model Prediction: 
    x1_hat_prev = Ad(1,1)*x1_hat(k-1) + Bd(1,1)*I(k-1);
    
    if(x1_hat_prev >1)
        x1_hat_prev = 1; 
    end 
%     
    C_ek = interp1(soc_intpts_OCV_slope', OCV_slope_intpts, x1_hat_prev);

    P_prev = A_ek*P(k-1)*A_ek'+ E_ek*Q*E_ek';
    
   % Measurement Update: 
   V_hat(k) = interp1(soc_intpts_OCV',OCV_intpts,x1_hat_prev) - I(k)*R0 - x2(k) - x3(k);
    
   L = P_prev*C_ek'*inv(C_ek*P_prev*C_ek'+ F_ek*R*F_ek');
    
    x1_hat(k) = x1_hat_prev + L*(V(k)-V_hat(k));
    P(k) = P_prev - L*C_ek*P_prev;
    
end 



figure(1);
hold on 
plot(t,SOC_act)
plot(t,x1_hat)
plot(t,x1)
title('Extended Kalman Filter SOC Estimation'); 
xlabel('Time (seconds)'); 
ylabel('State of Charge (SOC)'); 
legend('SOC_{act}','SOC_{est}','SOC_{OL}');
grid on;

figure(2);
plot(t,V,t,V_hat)
title('Extended Kalman Filter SOC Estimation'); 
xlabel('Time (seconds)'); 
ylabel('Terminal Voltage (V)'); 
legend('V_{act}','V_{est}');
grid on;


%% Observability & Controlability Analysis: 

O = obsv(Ad,Cd);

rank(O)

% Observability Matrix is of Full Rank: System is fully Observable  

Cm = ctrb(Ad,Bd);

rank(Cm)

% Controlability Matrix is of Full Rank: System is fully Controlable





