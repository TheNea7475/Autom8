%%Plot Database

INPUT=strcat(cd,'\Pre processing blade profiles - Automatic geometry fix\TU_Delft.mat');
load(INPUT);
XO=Database.grid.PAD; % Geometric Matrix --> |r/R|c/R|beta(deg)|x25(mm)|z25(mm)|
Xgeo=sortrows([[XO.RadialPosition]' [XO.Chord]' [XO.Twist]' [XO.x25]' [XO.y25]'],1);

load('ChordTUDelft.mat')
load('TwistTUDelft.mat')
load('Chord_new.mat')


figure
plot(Xgeo(:,1),Xgeo(:,2),'b')
hold on
plot(ChordTUDelft(:,1),ChordTUDelft(:,2),'r')
legend('Autom8','Casalino (2021)')
grid minor

figure
plot(Xgeo(:,1),Xgeo(:,3),'b')
hold on
plot(TwistTUDelft(:,1),TwistTUDelft(:,2),'r')
legend('Autom8','Casalino (2021)')
grid minor