function plotGlobalOffset(obs,go,goPlot,yrange,tMEplot)
% Todo: 
% calculate statistics for GO
% compate LUR R2 and MSE with and without intercept
%
% obs 
%       structure:
%         obs.name       char    CAP name
%         obs.label      char    CAP name its unit
%         obs.unit       char    CAP unit
%         obs.stateCode  nMSx2   state code of nMS monitoring site
%         obs.countyCode nMSx2   county code of nMS monitoring site
%         obs.siteNumber nMSx2   site number of nMS monitoring site
%         obs.sMS        nMSx2   Longitude-Latitude of nMS monitoring site
%         obs.tME        1xnME   time (in years) of nME monitoring events
%         obs.Z          nMSxnME CAP observed concentration at nMS monitoring
%                                  sites and nME time events
%         obs.logTransf  1x1     log transform indicator: 1- Y=log(Z), 0- Y=Z
%         obs.Y          nMSxnME If logTransfm=1 Y=log(Z) else Y=Z 
%         obs.Yname      char    name of Y
%         obs.Ylabel     char    name of Y and its unit
%       default is obs=7    
% go   scalar specifying the global offset scenario, or structure containing the global offset:
%      scalar:  
%          0 zero, 1 flat, 2 domain wide, 3 regional, 4 local
%      structure:
%        go.logTransf    1x1    0: the global offset go applies to the CAP concentrations   
%                               (not log transformed), 1: the go applies to log(CAP)
%        go.Scenario     1x1    global offset scenario. 0 zero, 1 flat, 
%                               2 domain wide, 3 regional, 4 local
%        go.sMSraw       nMSx2  Long-Lat of nMS monitoring sites
%        go.tMEraw       1xnME  time (in years) of nME monitoring events
%        go.msRaw        nMSx2  raw mean (i.e. time average obs) at the nMS monitoring sites
%        go.mtRaw        1xnME  raw mean (i.e. spatial average obs) at the nME monitoring events
%        go.sMS          nMSdens x 2  Long-Lat of nMSdens densified monitoring sites
%        go.tME          1xnMEdens  time (in years) of nME densified monitoring events
%        go.ms           nMSdens x 2  smoothed mean at the nMSdens densified monitoring sites
%        go.mt           1xnMEdens  smoothed mean at the nMEdens densified monitoring events
%        go.goParam;     1x5    parameters used to obtain the smooth means ms and mt (see stmeanDensified.m).
%        go.densParam;   1x6    parameters used to densify the monitoring sites and events (see stmeanDensified.m).
%      default is go=3
% goPlot scalar indicating how many global offset plots should be made:
%                          0- no plots, 1 - plot of mt and map of ms, 
%                          2 - same as 1 + map of msRaw
%                          3 - same as 2 + plot of mst at specific 
%                          sites, and of mst at specific times.
%                          Default is goPlot=1;
% yrange  2 by 1  yrange input parameter for markerplot or colorplot
%                          if yrange=[] then use the 5 and 95 percentiles of the observations
%                          if yrange=NaN then this option is not used
%                          default is []
%
if isempty(yrange)
  yrangeQuant=[0.05 0.95];
  yrange=quantest(obs.Y(~isnan(obs.Y)),yrangeQuant);
end

% Set spatial domain for the maps
ax=[ 349000 361000 4324000 4331000 ];
ax=[ax(1)-1 ax(2)+1 ax(3)-1 ax(4)+1];

% Time series of the raw and smoothed mean trend
if goPlot>=1
  figure;
  hold on;
  htRaw=plot(go.tMEraw,go.mtRaw,'o-r');
  ht=plot(go.tME,go.mt,'.-k');
  xlabel('Time (years)');
  ylabel(obs.Ylabel);
  title(sprintf('Raw and smoothed temporal mean trend of %s',obs.Yname));
  legend([htRaw ht],'Raw mean trend = spatial average of obsertations','smoothed mean trend');
end

% Map of the Raw spatial mean trend
if goPlot>=2 && ~contains(obs.scn,'goL')
  figure;
  Property={'Marker','MarkerSize','MarkerEdgeColor'};
  Value ={'s',10,[0 0 0]};
  colorplot(go.sMSraw,go.msRaw,redyellow,Property,Value,yrange);
  %caxis(yrange);
  colorbar;
  axis(ax);
  title(sprintf('Raw spatial trend of %s',obs.Ylabel));
  xlabel('X (M)');
  ylabel('Y (M)');
  hold on;
end

% Map of the smoothed spatial mean trend
if goPlot>=2
  figure;
  [xgkm ygkm]=meshgrid(ax(1):100:ax(2),ax(3):100:ax(4));
  [zgkm]=griddata(go.sMS(:,1),go.sMS(:,2),go.ms,xgkm,ygkm);
  zgkm=reshape(zgkm,size(xgkm));
  colormap(redyellow);
  pcolor(xgkm,ygkm,zgkm);
  shading interp;
  colorbar;  
  Property={'Marker','MarkerSize','MarkerEdgeColor'};
  Value ={'o',10,[0 0 0]};
  hold on;
  axis(ax);
  plot(go.sMSraw(:,1),go.sMSraw(:,2),'.k');
  title(sprintf('Smoothed spatial trend of %s',obs.Ylabel));
  xlabel('X (M)');
  ylabel('Y (M)');
end


% Plot time series of the obsertations and global offset at selected monitoring sites
if goPlot>=3
  for i=1:6 % and plot them
    iObsMS=(obs.idMS==i);
    figure;
    hold on;
    hd=plot(obs.XY(iObsMS,3),obs.vals(iObsMS,:),'o');
    ht=plot(obs.XY(iObsMS,3),stmeaninterpstv(go.sMS,go.tME,go.ms,go.mt,obs.XY(iObsMS,:)),'.-');
    xlabel(sprintf('Time (%s)',obs.tave));
    ylabel(obs.Ylabel);
    title(sprintf('Monitoring site %.2d',i));
    legend([hd ht],'observations','global offset');
  end;
end

% Make maps of the data (using colorplot) and global offset at selected
% monitoring event times
if false
  tMEplot=intersect(tMEplot,obs.tME);
  for iMEplot=1:length(tMEplot)
    tk=tMEplot(iMEplot);
    iObsME=find(obs.tME==tk);
    figure;
    hold on;
    [xgkm ygkm]=meshgrid(ax(1):0.02:ax(2),ax(3):0.02:ax(4));
    [zgkm]=stmeaninterp(go.sMS,go.tME,go.ms,go.mt,[xgkm(:) ygkm(:)],tk);
    zgkm=reshape(zgkm,size(xgkm));
    colormap(redyellow);
    pcolor(xgkm,ygkm,zgkm);
    shading interp;
    colorbar;
    Property={'Marker','MarkerSize','MarkerEdgeColor'};
    Value ={'o',10,[0 0 0]};
    axis(ax);
    colorplot(obs.sMS,obs.Y(:,iObsME),redyellow,Property,Value,yrange);
    title([obs.Ylabel ' for ' num2str(tk)]);
    xlabel('Longitude (deg.)');
    ylabel('Latitude (deg.)');
  end
end

