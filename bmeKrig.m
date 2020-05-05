function bmeKrig(tA,goScenario,oname,tnum,eks)
    %tA = 'Y'; %Y,M,D,H,60s
    %goScenario = 'M'; %0,1,M,MI,L
    %oname = 'BOTH00'; %Fixed,Mobile,BOTH00 
    %tnum = 1 ; which time step to run in episode
    %eks  = 1 ; temporal range of exponential smoothing function (optional)

    if nargin<1, tA='M'; end
    if nargin<2, goScenario='L'; end
    if nargin<3, oname='BOTH00'; end
    if nargin<4, tnum='6'; end
    if nargin<5, eks='1.5'; end
    
    if exist('krigingME')~=2
      run('../BMELIB2.0c_noMex/startup.m')
    end
    % run('/nas/longleaf/home/valenal/matlab/BMELIB2.0c_noMex/startup.m')
    
    %git update
    
    tnum=str2double(tnum);

    if contains(oname, 'BOTH')
        softDat = str2num(strrep(oname,'BOTH','')); %0,1,2,3 (none,mobile,ctools both)
    else
        softDat = 0;
    end
    
    runBME  = 1;
    plotgo =  0;
    plotcov = 0;
    plotbme = 1;
    %gtag = '40m_10min10'; %hardcoded
    %rmOL = 'True';        %hardcoded


    %%%%%%%%%% get OBS %%%%%%%%%%
    inD = 'INPUTS';
    % inD = '/proj/ie/proj/KC-TRAQS/utils/valenal/DataFusion/BME_KCTRAQS/INPUTS';
    inF = sprintf('%s/fixed_mobile40m_CTOOLS_%s.csv',inD,tA); 

    dat   = readtable(inF);
    
    switch oname
        case 'Fixed',  dat = dat(dat.RecID < 10 , :);
        case 'Mobile', dat = dat(dat.RecID > 10 , :);
        case {'BOTH01','BOTH03'}
            datS = dat(dat.RecID > 10 , :);
            dat =  dat(dat.RecID < 10 , :);
        case 'BOTH00', % do nothing for now
        otherwise error('Not a data option for "oname" varaible')
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
    obs.sdat = softDat; %0,1,2,3 (none,mobile,ctools,both)
    obs.eks  = str2double(eks);
    obs.Ylabel= 'BC (ug/m3)';
    obs.Yname = 'BC';
    obs.cluster = dat.GroupID;
    obs.month = dat.month;
    
    switch obs.tave
        case 'Y', tkVecs = [48];
        case 'M', tkVecs = 574:586;
        case 'D', tkVecs = 17458:17835;
        case 'H', tkVecs = [418931:419630,421955:422606];
        otherwise,error('time average not implemented')
    end

    tkVec = tkVecs(tnum);    
    
    if obs.sdat == 1 %mobile
        obs.sdxy   = [datS.x,datS.y,datS.dts];
        obs.sdmean = datS.obs;
        obs.sdvar  = datS.smvar;
    elseif obs.sdat == 2 %CTOOLS
        dt = getdts(tkVec,obs.tave);
        sdC = readtable(sprintf('%s/gridSite_ALL_%save.csv',inD,obs.tave));
        sdC = sdC(sdC.date==str2double(dt),:) ; 
        obs.sdxy   = [sdC.x,sdC.y,datS.dts]; 
        obs.sdmean = sdC.EC25;
        obs.sdvar = 0 ; %fix this !!
    elseif obs.sdat == 3 %mobile and CTOOLS
        %do nothing for now
    end
    %%%%%%%%%% get OBS %%%%%%%%%%

    %%%% get the global offset %%%%
    switch goScenario
        case '0'
            go.scenario = goScenario;
            obs.scn = sprintf('%s_%save_%iSD_go%s',obs.name,obs.tave,obs.sdat,goScenario);
        case {'M','MI'}  % CTOOLS, CTOOLSInv
            go.scenario = goScenario;
            obs.scn = sprintf('%s_%save_%iSD_go%s',obs.name,obs.tave,obs.sdat,goScenario);
        case 'C' %constant GO
            go.scenario = goScenario;
            go.gMean = mean(obs.vals);
            obs.vals = obs.vals - go.gMean;
            obs.scn = sprintf('%s_%save_%iSD_go%s',obs.name,obs.tave,obs.sdat,goScenario);
        otherwise
            if  goScenario == 'L'
                obs.scn = sprintf('%s_%save_%iSD_go%s_eks%s', ...
                    obs.name,obs.tave,obs.sdat,goScenario,eks);
            else %1 constant GO
                obs.scn = sprintf('%s_%save_%iSD_go%s', ...
                    obs.name,obs.tave,obs.sdat,goScenario);
            end
            go = getGlobalOffset(obs,goScenario,plotgo);
    end
    %%%% get the global offset %%%%


    %%%%% get the covariance %%%%%%
    cov=getCOV(obs,go,plotcov);
    %%%%% get the covariance %%%%%%


    %%%%%% estBME %%%%%%%%%
    if runBME %run BME
        estBME(obs,go,cov,tkVec,plotbme,1);
    end
    %%%%%% estBME %%%%%%%%%

end %func bmeKrig
