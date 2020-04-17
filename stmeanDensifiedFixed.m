function stmeanDensifiedFixed(eks,tsI,tsO)
    run('/nas/longleaf/home/valenal/matlab/BMELIB2.0c_noMex/startup.m')

    if strcmp(tsI,'min')
        fx  = readtable('/proj/ie/proj/KC-TRAQS/utils/valenal/preProcFS/fixedSites_60s_wDTS.csv');
        ts.min  = 1;
        ts.hour = 60;
        ts.day = 60*24;
        ts.month = 30*24*60;

        ats.hour1 = 60;
        ats.hour10 = 600;
        ats.day1   = 60*24;
        ats.day10  = 600*24;
        ats.month1 = 30*24*60;
        ats.month48 = 30*24*60*48;
    elseif strcmp(tsI,'hour')
        fx  = readtable('/proj/ie/proj/KC-TRAQS/utils/valenal/postProc/FSDAT/fs_obs_ModSRC_H.csv');
        ts.min  = 1/60;
        ts.hour = 1;
        ts.day = 24;
        ts.month = 730;

        ats.hour1 = 1;
        ats.hour10 = 10;
        ats.day1   = 24;
        ats.day10  = 240;
        ats.month1 = 730;
        ats.month48 = 730*48;
    elseif strcmp(tsI,'day')
        fx  = readtable('/proj/ie/proj/KC-TRAQS/utils/valenal/postProc/FSDAT/fs_obs_ModSRC_D.csv');
        ts.min = 1/1440;
        ts.hour = 1/24;
        ts.day = 1;
        ts.month = 30.4;

        ats.day1  = 1;
        ats.day10  = 10;
        ats.month1 = 30;
        ats.month48 = 30*48;
    elseif strcmp(tsI,'month')
        fx  = readtable('/proj/ie/proj/KC-TRAQS/utils/valenal/postProc/FSDAT/fs_obs_ModSRC_M.csv');
        ts.min = 1/43830;
        ts.hour = 1/730;
        ts.day = 1/30.4;
        ts.month = 1;

        ats.day1 = 1/30;
        ats.day10 = 1/3;
        ats.month1 = 1;
        ats.month48 = 48;

    end

    %at=10;    % exponential kernel smoothing range of 10 minutes
    at = ats.(eks);
    tWindow=at*2; % time window of 20 days
    tMEtimeStep = ts.(tsO);

    if strcmp(tsI,'min')
        obs.XY   =  [fx.site,fx.site,fx.dts];
    else
        obs.XY   =  [fx.x,fx.y,fx.dts];
    end

    obs.vals =  [fx.obs];
    idx=~isnan(obs.vals);
    obs.XY=obs.XY(idx,:);
    obs.vals=obs.vals(idx,:);

    %dts = fx.dts(idx);
    %dt  = fx.date(idx);
    %dates = array2table(unique([dt,dts],'rows'),'VariableNames',{'dates','dts'});

    [Zh,sMS,tME] = valstv2stg(obs.XY,obs.vals);
    idMS=[1:6]';

    kernParam=[10 1000 tWindow at 0];
    densParam=[0 0 0 0 1 tMEtimeStep];
    axS      =[0 0 0 0];

    [ms,mss,mt,mts,sMSd,tMEd]=stmeanDensified(Zh,sMS,idMS,tME,kernParam,densParam,axS);
    
    dates = str2num(dts2date(tMEd, tsI,tsO));
    array = [dates,mts'];
    [C,ia,idx] = unique(array(:,1),'stable');
    val = accumarray(idx,array(:,2),[],@mean);
    outT = [C val];

    outT = array2table(outT,'VariableNames',{'date',eks});

    writetable(outT,sprintf('./OUTPUT/eks_%s_%s_%s.csv',eks,tsI,tsO));
end

