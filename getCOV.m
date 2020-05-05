function cov=getCOV(obs,go,covPlot)
    if nargin<3, covPlot=0; end;

   % If needed create the covariance directory
    covDir='3covariance';
    if exist(covDir)~=7
        mkdir(covDir);
        fid=fopen([covDir '/0readme.txt'],'w');
        fprintf(fid, [ 'The files in this folder were created by the function getCOV.m. \n']);
        fprintf(fid, [ 'See help getCAPcov.m for an explanation of the file naming scheme. \n']);
        fclose(fid);
    end 

    % set the cov filename
    covFile=sprintf('%scov_%save_go%s.mat',obs.name,obs.tave,go.scenario);
    
    %if false
    if exist([covDir '/' covFile])==2
        load([covDir '/' covFile]); % loads cov (the covariance) if it was already estimated
    else                          % else estimate the cov and save it
        switch go.scenario
            case {'0','C'}
                [X,sMS,tME] = valstv2stg(obs.XY,obs.vals);
            case {'M','MI'}
                [X,sMS,tME] = valstv2stg(obs.XY,obs.vals-obs.CTOOLS);
            otherwise
                % remove the S/T mean from the data
                X=go.obsValsSTG-stmeaninterp(go.sMS,go.tME,go.ms,go.mt,go.sMSraw,go.tMEraw);
                sMS = go.sMSraw;
                tME = go.tMEraw;
        end

        % Set up the spatial and temporal lags
        if obs.tave == 'Y'
            rLag =   [0 100 200 300 400 500 600 700 ];           % spatial lags in degrees
            rLagTol= [0  50  50 100 100 200 400 500 ];  % tolerance for spatial lags
        else
            rLag =   [0 50 75 100 150 200 250 300 400 500 600 700 1000:500:2000 ]; % spatial lags in meters
            rLagTol= [0 45 70  95 100 100 100 100 100 200 400 500 500 500 500 ]; % tolerance for spatial lags
        end
        
        if strcmp(obs.tave,'60s') || obs.tave == 'H'
            tLag = [0:1:20]   ; % the time lags in tA
            tLagTol= 0.1*ones(size(tLag)) ; % tolerance for time lags
        else
            tLag = [0:1:10]   ; % the time lags in tA
            tLagTol= 0.1*ones(size(tLag)) ; % tolerance for time lags
        end

        % calculate experimental covariance values
        [Cr npr]=stcov(X,sMS,tME,X,sMS,tME,rLag,rLagTol,0,0.1,{'coord2dist'},'kron');  % estimate C(r,t=0)
        [Ct npt]=stcov(X,sMS,tME,X,sMS,tME,0,0.001,tLag,tLagTol,{'coord2dist'},'kron');% estimate C(r=0,t)
        v=var(X(~isnan(X)));

        % Set the parameter of the covariance model
        switch obs.name 
        case 'BOTH00'
            switch obs.tave
                case '60s'
                switch go.scenario
                    case '0', c01=v*0.50; ar1=500; at1=1;  c02=v*0.35; ar2=1000; at2=1; c03=v*0.15; ar3=50000; at3=500;
                    case 'L', c01=v*0.80; ar1=800; at1=2;  c02=v*0.20; ar2=5000; at2=10000;
                end
                case 'H'
                switch go.scenario
                    case '0', c01=v*0.80; ar1=350; at1=3;  c02=v*0.20; ar2=30000; at2=25;
                    case '1', c01=v*0.80; ar1=350; at1=3;  c02=v*0.20; ar2=30000; at2=25;
                    case 'M', c01=v*0.85; ar1=150; at1=5;  c02=v*0.15; ar2=15000; at2=50;
                    case 'L', c01=v*0.50; ar1=350; at1=1;  c02=v*0.25; ar2=350; at2=10; c03=v*0.25; ar3=50000; at3=100;             
                end
                case 'D'
                switch go.scenario
                    case '0', c01=v*0.85; ar1=400; at1=1;  c02=v*0.15; ar2=15000; at2=50;
                    case '1', c01=v*0.85; ar1=400; at1=1;  c02=v*0.15; ar2=15000; at2=50;
                    case 'M', c01=v*0.85; ar1=400; at1=1;  c02=v*0.15; ar2=15000; at2=50;
                    case 'L', c01=v*0.80; ar1=350; at1=1;  c02=v*0.20; ar2=15000; at2=1000;
                end
                case 'M'
                switch go.scenario
                    case '0', c01=v*0.90; ar1=300; at1=1;  c02=v*0.10; ar2=10000; at2=5;
                    case '1', c01=v*0.90; ar1=200; at1=1;  c02=v*0.10; ar2=10000; at2=5;
                    case {'M','MI'}, c01=v*0.90; ar1=300; at1=1;  c02=v*0.10; ar2=10000; at2=5;
                    case 'C', c01=v*0.90; ar1=300; at1=1;  c02=v*0.10; ar2=10000; at2=5;
                    case 'L', c01=v*0.60; ar1=250; at1=1;  c02=v*0.20; ar2=250; at2=1; c03=v*0.20; ar3=4000; at3=100;
                end
                case 'Y'
                switch go.scenario
                    case '0', c01=v*0.90; ar1=200; at1=2;  c02=v*0.10; ar2=10000; at2=50; 
                    case '1', c01=v*0.90; ar1=200; at1=2;  c02=v*0.10; ar2=10000; at2=50; 
                    case {'M','MI'}, c01=v*0.90; ar1=200; at1=2;  c02=v*0.10; ar2=10000; at2=50; 
                    case 'C', c01=v*0.90; ar1=200; at1=2;  c02=v*0.10; ar2=10000; at2=50; 
                    case 'L', c01=v*0.80; ar1=300; at1=2;  c02=v*0.20; ar2=1000; at2=50; 
                end
            end

        case 'Fixed' % ask Marc about weird covariance in L, use with GO
            switch obs.tave
                case '60s'
                switch go.scenario
                    case '0', c01=v*0.60; ar1=400; at1=4;  c02=v*0.25; ar2=400; at2=5000; c03=v*0.15; ar3=5000; at3=5000; 
                    case 'L', c01=v*0.60; ar1=400; at1=4;  c02=v*0.25; ar2=400; at2=5000; c03=v*0.15; ar3=5000; at3=5000; 
                end
                case 'H'
                switch go.scenario
                    case '0', c01=v*0.55; ar1=1200; at1=10;  c02=v*0.45; ar2=30000; at2=25;
                    case '1', c01=v*0.55; ar1=1200; at1=10;  c02=v*0.45; ar2=30000; at2=25;
                    case 'L', c01=v*0.50; ar1=1500; at1=13;  c02=v*0.40; ar2=10000; at2=13; c03=v*0.10; ar3=10000; at3=10000;
                end
                case 'D'
                switch go.scenario
                    case '0', c01=v*0.85; ar1=2000; at1=3;  c02=v*0.15; ar2=30000; at2=50;
                    case '1', c01=v*0.85; ar1=2000; at1=3;  c02=v*0.15; ar2=30000; at2=50;
                    case 'L', c01=v*0.50; ar1=1000; at1=2;  c02=v*0.30; ar2=10000; at2=2; c03=v*0.20; ar3=10000; at3=10000;
                end
                case 'M'
                switch go.scenario
                    case '0', c01=v*0.90; ar1=300; at1=4;  c02=v*0.10; ar2=10000; at2=50;
                    case '1', c01=v*0.90; ar1=300; at1=4;  c02=v*0.10; ar2=10000; at2=50;
                    case 'L', c01=v*0.90; ar1=500; at1=3;  c02=v*0.10; ar2=3000; at2=1000;
                end
                case 'Y'
                switch go.scenario
                    case '0', c01=v*0.90; ar1=200; at1=2;  c02=v*0.10; ar2=10000; at2=50; 
                    case {'1','C'}, c01=v*0.90; ar1=200; at1=2;  c02=v*0.10; ar2=10000; at2=50;
                    case 'L', c01=v*0.90; ar1=200; at1=2;  c02=v*0.10; ar2=10000; at2=50;
                end
            end
        end
        

        cov.name=obs.name;
        cov.tave=obs.tave;
        cov.sdat=obs.sdat;
        cov.goScenario=go.scenario;
        cov.rLag=rLag;
        cov.Cr=Cr;
        cov.npr=npr;
        cov.tLag=tLag;
        cov.Ct=Ct;
        cov.npt=npt;
        cov.var=v;
        if exist('c03','var')
          cov.covmodel={'exponentialC/exponentialC','exponentialC/exponentialC','exponentialC/exponentialC'};
          cov.covparam={[c01 ar1 at1],[c02 ar2 at2],[c03 ar3 at3]};
        else
          cov.covmodel={'exponentialC/exponentialC','exponentialC/exponentialC'};
          cov.covparam={[c01 ar1 at1],[c02 ar2 at2]};
        end
        
        save([covDir '/' covFile],'cov');

    end % if exist([covDir '\' covFile])==2

    if covPlot>=1
        plotCOV(cov,covPlot); 
    end

    %testplotCOV(cov,'T')
    %c01=v*0.30; ar1=2000; at1=2;  c02=v*0.70; ar2=30000; at2=1000; cov.covparam={[c01 ar1 at1],[c02 ar2 at2]}; drawCurve(cov,'-g','T')
    
end

