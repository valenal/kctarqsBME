function bmeKrig(tA,goScenario,oname,tnum,eks)
    %tA = 'Y'; %Y,M,D,H,60s
    %goScenario = 'M'; %0,1,M,MI,L
    %oname = 'BOTH00'; %Fixed,Mobile,BOTH00
    %tnum = 1 ; which time step to run in episode
    %eks  = 1 ; temporal range of exponential smoothing function (optional)

    run('/nas/longleaf/home/valenal/matlab/BMELIB2.0c_noMex/startup.m')


    tnum=str2double(tnum);

    softDat = '0'; %0,1
    runBME  = 1;
    plotgo =  0;
    plotcov = 1;
    plotbme = 1;
    %gtag = '40m_10min10'; %hardcoded
    %rmOL = 'True';        %hardcoded


    %%%%%%%%%% get OBS %%%%%%%%%%
    inD = '/proj/ie/proj/KC-TRAQS/utils/valenal/DataFusion/BME_KCTRAQS/INPUTS';
    inF = sprintf('%s/fixed_mobile40m_CTOOLS_%s.csv',inD,tA); 

    dat   = readtable(inF);
    if strcmp(oname,'Fixed')
        dat = dat(dat.RecID < 10 , :);
    elseif strcmp(oname,'Mobile')
        dat = dat(dat.RecID > 10 , :);
    elseif strcmp(oname,'BOTH00')
        % do nothing for now
    else
        error('Not a data option for "oname" varaible')
    end

    gridC = [dat.x,dat.y,dat.dts];
    idMS  = dat.RecID;
    switch goScenario
        case {'M','MI'} %CTOOLS Model or CTOOLS Inverse Model
            obs.CTOOLS = dat.ALL;%ALL = CTOOLS
    end

    obs.XY   = gridC;
    obs.idMS = idMS;
    obs.vals = dat.obs;
    obs.name = oname;
    obs.tave = tA;
    obs.sdat = softDat;
    obs.eks  = str2double(eks);
    obs.Ylabel= 'BC (ug/m3)';
    obs.Yname = 'BC';
    %%%%%%%%%% get OBS %%%%%%%%%%

    %%%% get the global offset %%%%
    switch goScenario
        case '0'
            go.scenario = goScenario;
            obs.scn = sprintf('%s_%save_%sSD_go%s',obs.name,obs.tave,obs.sdat,goScenario);
        case {'M','MI'}  % CTOOLS, CTOOLSInv
            go.scenario = goScenario;
            obs.scn = sprintf('%s_%save_%sSD_go%s',obs.name,obs.tave,obs.sdat,goScenario);
        case 'C' %constant GO
            go.scenario = goScenario;
            go.gMean = mean(obs.vals);
            obs.vals = obs.vals - go.gMean;
            obs.scn = sprintf('%s_%save_%sSD_go%s',obs.name,obs.tave,obs.sdat,goScenario);
        otherwise
            if  goScenario == 'L'
                obs.scn = sprintf('%s_%save_%sSD_go%s_eks%s', ...
                    obs.name,obs.tave,obs.sdat,goScenario,eks);
            else %1 constant GO
                obs.scn = sprintf('%s_%save_%sSD_go%s', ...
                    obs.name,obs.tave,obs.sdat,goScenario);
            end
            go = getGlobalOffset(obs,goScenario,plotgo);
    end
    %%%% get the global offset %%%%


    %%%%% get the covariance %%%%%%
    cov=getCOV(obs,go,plotcov);
    %%%%% get the covariance %%%%%%


    %%%%%% estBME %%%%%%%%%
    switch obs.tave
        case 'Y', tkVecs = [48];
        case 'M', tkVecs = 574:586;
        case 'D', tkVecs = 17458:17835;
        case 'H', tkVecs = [418931:419630,421955:422606];
        otherwise,error('time average not implemented')
    end

    tkVec = tkVecs(tnum);

    if runBME %run BME
        estBME(obs,go,cov,tkVec,plotbme,1);
    end
    %%%%%% estBME %%%%%%%%%

end %func bmeKrig
