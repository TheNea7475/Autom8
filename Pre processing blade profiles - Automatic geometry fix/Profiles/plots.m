clear
close all

for i=1:20
    filename=sprintf('Profile%d.txt',i);
    xx=importfile(filename);
    plot(xx(:,1),xx(:,2),'r')
    axis([0 1 -0.5 0.5])
    grid minor
    pause(1)
    saveas(gcf,'Profile'+string(i)+'.png');
end