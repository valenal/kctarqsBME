function estBME(obs,go,cov,tkVec,BMEsPlot,estimateAtGrid)
    
    % If needed create the covariance directory
    bmeDir=sprintf('5bmeOutput/%s',obs.scn);
    if exist(bmeDir)~=7
        mkdir(bmeDir);
        fid=fopen([bmeDir '/0readme.txt'],'w');
        fprintf(fid, [ 'The files in this folder were created by the function estBME.m. \n']);
        fprintf(fid, [ 'See help estBME.m for an explanation of the file naming scheme. \n']);
        fclose(fid);
    end

    inpD = '/proj/ie/proj/KC-TRAQS/utils/valenal/DataFusion/BME_KCTRAQS/INPUTS/';
    if estimateAtGrid
        pGrid = readtable(sprintf('%s/GridSite.csv',inpD));
        if go.scenario == 'M' %CTOOLS
            gok = readtable(sprintf('%s/gridSite_ALL_%save.csv',inpD,obs.tave));
        elseif go.scenario == 'MI' %CTOOLS Inverse
            gok = readtable(sprintf('/proj/ie/proj/KC-TRAQS/utils/valenal/postProc/gridDATInv/CTOOLS_gridInv_%save.csv',obs.tave));
        end
    else
        pGrid = gridC;
    end

    c01=cov.covparam{1}(1);
    ar1=cov.covparam{1}(2);
    at1=cov.covparam{1}(3);
    c02=cov.covparam{2}(1);
    ar2=cov.covparam{2}(2);
    at2=cov.covparam{2}(3);
    stmetric=(c01*ar1/at1+c02*ar2/at2)/(c01+c02);  % variance weighted metric average

    % set the BME paramaters
    nhmax=100;             % max number of hard data
    nsmax=0;             % max number of soft data
    order=nan;
    %if go.scenario == 'M'| go.scenario == 'MI'
    %    order=nan;
    %else
    %    order=0;            % assume the mean of X=Y-go is known and equal to 0 (Simple Kriging)
    %end
    
    
    %maybe think about a switch
    dmax=[10000 100 stmetric]; % dmax(1) spatial search radius, dmax(2) temporal search radius, dmax(3) space/time metric
    maxpts=500000;        % number of function eval for integration
    rEps=0.05;           % Relative numerical error allowable
    nMom=2;              % Calculate the mean and variance
    options=BMEoptions;
    options(1)=0;
    options(3)=maxpts;
    options(4)=rEps;
    options(8)=nMom;
   
    ph = obs.XY;
    switch go.scenario
        case '0'
            xh = obs.vals
        case {'M','MI'}
            xh = obs.vals-obs.CTOOLS;
        otherwise
            %remove the S/T mean from the data, 
            xh = obs.vals-stmeaninterpstv(go.sMS,go.tME,go.ms,go.mt,ph);
    end
    idx=~isnan(xh);
    ph=ph(idx,:);
    xh=xh(idx);

    if obs.sdat == '0'
        softpdftype=1;
    else
        softpdftype=2;
        % xs = obs.sdmean-stmeaninterpstv(go.sMS,go.tME,go.ms,go.mt,ph);
    end

    cs=[]; % matrix of coordinates for the soft data locations,with the same convention as for ck.
    xs=[]; % xs vector of values for the mean of the soft data at the coordinates specified in cs.
    vs=[]; % vs vector of values for the variance of the soft data at the coordinates specified in cs.
    nl=[];
    limi=[];
    probdens=[];
    
    %fix global offset is in STG 
    [mae,mse,nrmse,me,r2,r2std]= getBmeXval(obs,go,cs,xs,vs,cov.covmodel,cov.covparam,nhmax,nsmax,dmax,order,options);

    for i=1:length(tkVec)
        tk=tkVec(i);
        
        % get date string in dt
        if obs.tave == 'Y'
            dt = 2018;
        elseif obs.tave == 'M'
            mth = mod(tk,12);
            yr = (1970+fix(tk/12));

            if mth == 00 
                yr = yr - 1;
                mth = 12;
            end
            dt = yr*100+mth;
        elseif obs.tave == 'D'
            dt = datestr(datetime(tk*24*3600, 'convertfrom','posixtime'),'yyyymmdd');
        elseif obs.tave == 'H'
            dt = datestr(datetime(tk*3600, 'convertfrom','posixtime'),'yyyymmddHH');
        elseif obs.tave == '60s'
            dt = datestr(datetime(tk*60, 'convertfrom','posixtime'),'yyyymmddHHMM');
        end

        pk  = [pGrid.xLCC,pGrid.yLCC, tk*ones(size(pGrid,1))];
    
        %BMELIB2.0c_noMex/bmehrlib/krigingME.m 
        [zk,vk]=krigingME(pk,ph,cs,xh,zs,vs,cov.covmodel,cov.covparam,nhmax,nsmax,dmax,order,options);
        
        if go.scenario == '0'
            ZkBMEm=zk;
        elseif go.scenario == 'C'
            ZkBMEm=zk+go.gMean;
        elseif go.scenario == 'M'|| strcmp(go.scenario,'MI')
            ZkBMEm=zk+gok(gok.date==str2double(dt),:).EC25;
        else
            % Obtain ZkBMEm by adding the global offset to Xk
            gok=stmeaninterp(go.sMS,go.tME,go.ms,go.mt,pk(:,1:2),tk);
            ZkBMEm=zk+gok;
        end


        %summary(mat2dataset(XkBMEm))
        dtstr = convertCharsToStrings(dt);
        outT = array2table([transpose(1:size(pk,1)),pk(:,1:2),repmat(dtstr, ...
        size(ZkBMEm,1),1),ZkBMEm,vk],'VariableNames',{'RecID','xLCC','yLCC','date','BC','var'});
        writetable(outT,sprintf('%s/bmeTable_%s_%s.csv',bmeDir,dtstr,obs.scn));

        if BMEsPlot
            f = figure('visible','off');
            [ck1,ck2,zg]=col2mat(pk(:,1:2),ZkBMEm);
            %[ck1,ck2,zg]=col2mat(pk(:,1:2),log(gok(gok.date==dt,:).EC25));
            %[ck1,ck2,zg]=col2mat(pk(:,1:2),log(ZkBMEm));
            pcolor(ck1,ck2,zg);
            hold on;
            colormap(jet);
            colorbar;
            shading interp;
            title(sprintf('BME - Mean BC (ug/m3) -  %save - %i',obs.tave,dt));
            xlabel('x');
            ylabel('y');
            caxis([0, 2]);
            axis equal;

        pngfilename=sprintf('plot_%i_%s.png',dt,obs.scn);
        %if exist([bmeDir '/' pngfilename])~=2
        saveas(f,sprintf('%s/%s',bmeDir,pngfilename))
        %end

        %BMELIB2.0c_noMex/bmeprobalib/BMEprobaMomentsXvalidation.m
        %[momentsXval,info,MSE,MAE,ME]=BMEprobaMomentsXvalidation(ckOption,ch,cs,zh,softpdftype,nl,limi,probdens,covmodel,covparam,nhmax,nsmax,dmax,order,options);

        end %plotIT
    end % for i=1:length(tkVec)


end
