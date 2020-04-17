function plotcov(cov,covPlot)
% plotCAPcov                   - Plot the S/T covariance
%
% plot of the covariance
%
%  SYNTAX:
%  
%  plotcov(cov,covPlot)
%
%  INPUT :
% 
% cov   structure containing the experimental covariance and the cov model 
%      cov.name       char    hard data used
%      cov.tave       char    time average name
%      cov.sdat       char    soft data used
%      cov.covmodel cell array of char specifying the cov model
%      cov.covparam  cell array of vectors specifying the cov parameters
%      cov.rLag  vector of spatial lags
%      cov.Cr  vector of experiemental cov values for the spatial lags at tau=0
%      cov.npr  number of pairs for Cr
%      cov.tLag  vector of temporal lags
%      cov.Ct  vector of experiemental cov values for the temporal lags at r=0
%      cov.npt  number of pairs for Ct
%      cov.var  experimental variance
%    default: cov=getCAPcov;
% covPlot  scalar to plot cov. 1-2D cov plot, 2-2D and 3D cov plot
%      default is 1
%
%  EXAMPLE : Plot the covariance of PM2.5 using a regional global offset 
% 
%  iva=7;        % Specify yearly PM25 concentrations
%  goScenario=3; % Specify the regional global offset
%  covPlot=1;    % Specify to plot the covariance
%  obs=getCAPobservationalData(iva); % Get the observations
%  go=getCAPglobalOffset(obs,goScenario,0);  % Get the global offset
%  cov=getCAPcov(obs,go,0);    % Get the covariance
%  plotCAPcov(cov,1)           % Plot the covariance

if nargin<1, cov=getcov; end
if nargin<2, covPlot=1; end

if covPlot~=1 & covPlot~=2
  error('covPlot must be equal to 1 or 2');
end

%
% plot the experimental values and the model for the covariance
% K(r,t=0) as function of spatial lag rLag
%
figure;
subplot(2,1,1);
h=[];
leg=[];
h(length(h)+1)=plot(cov.rLag,cov.Cr,'o');
leg{length(h)}='Experimental values';
hold on;

%
% plot the spatial component of the covariance model 
%

rInt = 50;
r=[0:rInt:cov.rLag(end)]';
c1=[r 0*r 0*r];
c2=[0 0 0];
CrModel=coord2K(c1,c2,cov.covmodel,cov.covparam);
h(length(h)+1)=plot(r(:),CrModel,'-r');
leg{length(h)}=['Exponential model'];
legend(h,leg);
xlabel('Spatial lag, r (m)');
ylabel('c(r,\tau=0)');
axis([r(1) r(end) 0 1.1*cov.var]);
title(['Covariance c(r,\tau) for '  cov.tave]);

%
% plot the experimental values and the model for the covariance
% C(r=0,t) as function of temporal lag tLag
%
subplot(2,1,2);
h=[];
leg=[];
h(length(h)+1)=plot(cov.tLag,cov.Ct,'o');
leg{length(h)}='Experimental values';
hold on;

%
% plot the temporal component of the covariance model
%  

rInt = 0.1;
tau=[0:rInt:cov.tLag(end)]';
c1=[0*tau 0*tau tau];
c2=[0 0 0];
CtModel=coord2K(c1,c2,cov.covmodel,cov.covparam);
h(length(h)+1)=plot(tau,CtModel,'-r');
leg{length(h)}=['Exponential model'];
xlabel('Time lag, \tau ');
ylabel('c(r=0,\tau)');
legend(h,leg);
axis([tau(1) tau(end) 0 1.1*cov.var]);

figDir='3covariance';
pgnfilename=sprintf('plot_%scov_%save_go%s.png',cov.name,cov.tave,cov.goScenario);
print([figDir '/' pgnfilename],'-dpng')

if covPlot<2, 
  return
end

% plot S/T covariance 3D
%figure;
%rg=[0:.01:.08 0.1:.02:.5];
%tg=[0:0.2:0.9  1:0.5:10];
%[rmg tmg]=meshgrid(rg,tg);
%[c1,c2,cmg]=col2mat([rmg(:) tmg(:)],coord2K([rmg(:) tmg(:)],[0 0],cov.covmodel,cov.covparam));
%hl=mesh(112*rmg,tmg,cmg);
%shading interp;
%set(gca,'XDir','rev');
%set(gca,'YDir','rev');
%xlabel('Spatial lag r (Km)');
%ylabel('Time lag \tau (years)');
%set(gcf,'PaperPosition',[0 0 10 4]);
%title(['Covariance c_{x}(r,\tau) of ' cov.Yname]);
