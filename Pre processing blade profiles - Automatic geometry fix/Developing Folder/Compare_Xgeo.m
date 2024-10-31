%%Plot Database

INPUT=strcat(cd,'\Pre processing blade profiles - Automatic geometry fix\Tmotor_Vfine.mat');
load(INPUT);
XO=Database.grid.PAD; % Geometric Matrix --> |r/R|c/R|beta(deg)|x25(mm)|z25(mm)|
Xgeo=sortrows([[XO.RadialPosition]' [XO.Chord]' [XO.Twist]' [XO.x25]' [XO.y25]'],1);
load('X_Tmotor_russel.mat')
load('X_Tmotor_andrea.mat')
load('X_TmotorAIAA.mat')
R=0.1905;

figure
plot(Xgeo(:,1),Xgeo(:,2),'b')
hold on
plot(X_Tmotor_russel(:,1),X_Tmotor_russel(:,2),'r')
hold on
plot(X_OPT1_iter3(:,1),X_OPT1_iter3(:,2),'k')
hold on
plot(X_AIAA(:,1),X_AIAA(:,2),'m')
legend('Autom8','Russel (2017)','Manavella (2021)','Carreño (2022)')
grid minor

figure
plot(Xgeo(:,1),Xgeo(:,3),'b')
hold on
plot(X_Tmotor_russel(:,1),X_Tmotor_russel(:,3),'r')
hold on
plot(X_OPT1_iter3(:,1),X_OPT1_iter3(:,3),'k')
hold on
plot(X_AIAA(:,1),X_AIAA(:,3),'m')
legend('Autom8','Russel (2017)','Manavella (2021)','Carreño (2022)')
grid minor