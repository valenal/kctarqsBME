function go=getGlobalOffset(obs,goScenario,goPlot)
% getGlobalOffset - estimates the global offset 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Input parameters.  Change these parameters to modify what this program is doing 

    %    Resolution of global offset grid
    inclvoronoi=1;     % 1 to include the voronoi vertices 
    inclgrid=1;        % 1 to include a grid, 0 otherwise
    nxpix=40;          % Number of pixels in the x-direction for the go grid
    nypix=25;          % Number of pixels in the y-direction for the go grid 
    densifytME=1;      % 1 to densify tME, 0 otherwise 
    tMEtimeStep=0.2;   % time step to densify tME  
    axMS=[ 349000 361000 4324000 4331000 ];  % [longmin lonmeax latmin latmax] of the grid for sMS
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % If needed create the go directory
    goDir='2globalOffset';
    if exist(goDir)~=7
        mkdir(goDir);
        fid=fopen([goDir '/0readme.txt'],'w');
        fprintf(fid, [ 'The files in this folder were created by the function getCAPglobalOffset.m. \n']);
        fprintf(fid, [ 'See help getCAPglobalOffset.m for an explanation of the file naming scheme. \n']);
        fclose(fid);
    end

   % set the go filename
    goFile=sprintf('%s.mat',obs.scn);

    % if the go file exists then read it, else estimate the go and save it
    if false
    %if exist([goDir '/' goFile])==2
        load([goDir '/' goFile]); % loads go (the global offset) if it was already estimated
    else                        % else estimate go and save it 
        % Set up parameters of the global offset
        % goParam 1 by 5 kernel parameters to smooth the spatial and temporal average
        % p(1)=dNeib  distance (radius) of spatial neighborhood
        % p(2)=ar     spatial range of exponential smoothing function
        % p(3)=tNeib  time (radius) of temporal neighborhood
        % p(4)=at     temporal range of exponential smoothing function
        % p(5)=tloop  is an optional input used for temporal smoothing.
        % When tloop>0, the measuring events are looped in a cycle of duration tloop.
        

        switch goScenario
            case '0'  % no GO ; not used
              goParam=[NaN NaN NaN NaN 0];
              densParam=[inclvoronoi inclgrid nxpix nypix densifytME tMEtimeStep];
              datXY = obs.XY;
              datvals = obs.vals;
            case '1'
              goParam=[200000 100000 200000 100000 0];
              densParam=[inclvoronoi inclgrid nxpix nypix densifytME tMEtimeStep];
              datXY = obs.XY;
              datvals = obs.vals;
            case 'L'
              at = obs.eks;
              tWindow = at*2;
              datXY = obs.XY(obs.idMS < 10 , :); %subset to Fixed Monitors
              datvals = obs.vals(obs.idMS < 10 , :); %subset to Fixed Monitors
              switch obs.tave
                case '60s'
                    if at < 1500
                        tWindow = at*50000;
                    end
                    goParam=[10 1000 tWindow at 0];
                    densParam=[0 0 0 0 densifytME 1];
                    axMS=[ 0 0 0 0 ];
                case 'H'
                    if at < 11
                        tWindow = at*40;
                    end
                    goParam=[10 1000 tWindow at 0];
                    densParam=[0 0 0 0 densifytME 0.5];
                    axMS=[ 0 0 0 0 ];
                case 'D'
                    goParam=[10 1000 tWindow at 0];
                    densParam=[0 0 0 0 densifytME tMEtimeStep];
                    axMS=[ 0 0 0 0 ];
                case 'M'
                    goParam=[10 1000 tWindow at 0];
                    densParam=[0 0 0 0 densifytME tMEtimeStep];
                    axMS=[ 0 0 0 0 ];
                case 'Y'
                    goParam=[10 1000 tWindow at 0];
                    densParam=[0 0 0 0 densifytME tMEtimeStep];
                    axMS=[ 0 0 0 0 ];
              end
        end
        
        [X,sMS,tME] = valstv2stg(datXY,datvals);
        % calculate the S/T mean and remove it from the data
        %[msRaw,mssd,mtRaw,mtsd,sMSd,tMEd]=stmeanDensified(obs.Y,obs.sMS,obs.idMS,obs.tME,goParam,densParam,axMS);
        [msRaw,mssd,mtRaw,mtsd,sMSd,tMEd]=stmeanDensified(X,sMS,(1:size(X,1))',tME,goParam,densParam,axMS);
        
        if goScenario=='0' % no GO ; not used
            mssd=zeros(size(mssd));
            mtsd=zeros(size(mtsd));
        elseif goScenario=='L'
            %meanS = readtable('./INPUTS/LUR_Fixed_Mobile_meanS.csv');
            %meanS = meanS(unique(obs.idMS),:) ;
            [X,sMS,tME] = valstv2stg(obs.XY,obs.vals); % return these to be full subset
            meanS = readtable('./INPUTS/LUR_Grid_meanS.csv');
            sMSd = table2array(meanS(:,2:3));
            
            msRaw= meanS.lur;
            mssd = meanS.lur;
             
            %sum(isnan(mtsd))+sum(isnan(mtsd))% ask Marc about timewindow increase
            mtsd = mtsd(~isnan(mtsd));% ask Marc about this
            tMEd = tMEd(~isnan(mtsd));% ask Marc about this
            
            %note to self
            %meanST = stmeaninterp(sMSd,tMEd,mssd,mtsd,sMS,tME); 
            %stmeaninterp(go.sMS,go.tME,go.ms,go.mt,go.sMSraw,go.tMEraw);
            
        end

        %go.logTransf=obs.logTransf;
        go.scenario=goScenario;
        go.obsValsSTG = X;
        go.sMSraw=sMS;
        go.tMEraw=tME;
        go.msRaw=msRaw;
        go.mtRaw=mtRaw;
        go.sMS=sMSd;
        go.tME=tMEd;
        go.ms=mssd;
        go.mt=mtsd;
        go.goParam=goParam;
        go.densParam=densParam;
        rcoef = corrcoef(stmeaninterpstv(go.sMS,go.tME,go.ms,go.mt,obs.XY),obs.vals);
        go.r2 = rcoef(1,2)^2;
        save([goDir '/' goFile],'go');

        if goPlot>=1
            plotGlobalOffset(obs,go,goPlot,nan);
        end
    end   

end
