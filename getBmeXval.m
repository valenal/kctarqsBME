function [mae,mse,nrmse,me,r2,r2std]=getBmeXval(obs,go,cs,zs,vs,covmodel,covparam,nhmax,nsmax,dmax,order,options)  
    %ToDo: 
    % 1. Add more statistics (check email) -
    % 2. Keep Stats for eachfold - DONE
    % 3. Crossvalidation in time and space -     

    %write test array to file option is set to off for now
    writeTest2file = '0';
    
    %estimate with fixed only but test at fixed and mobile
    estFxTestFxMb = contains(obs.scn,'BOTH');

    % If needed create the xvals directory
    xvalDir=sprintf('4bmeXval');
    if exist(xvalDir)~=7
        mkdir(xvalDir);
        fid=fopen([xvalDir '/0readme.txt'],'w');
        fprintf(fid, [ 'The files in this folder were created by the function getBmeXval.m. \n']);
        fprintf(fid, [ 'See help estBME.m for an explanation of the file naming scheme. \n']);
        fclose(fid);
    end
   
    switch go.scenario
        case {'L','1'}
            ph  = obs.XY; 
            Z   = obs.vals; %obs
            goh = stmeaninterpstv(go.sMS,go.tME,go.ms,go.mt,ph); %offset
            xh = Z-goh; %residual
        case {'M','MI'}
            ph = obs.XY  ;
            Z = obs.vals; %obs
            goh= obs.CTOOLS; %offset
            xh  = Z-goh; %residual
        case '0'
            ph = obs.XY  ;
            Z  = obs.vals; %obs
            goh= 0*Z; %offset
            xh = Z-goh; %obs
    end

    
    
    %https://www.mathworks.com/help/stats/cvpartition-class.html
    CVO = cvpartition(xh,'k',10);
    %CVO = cvpartition(xh,'LeaveOut');
    
    blank =  zeros(CVO.NumTestSets,1);
    fold = (1:CVO.NumTestSets)'; 
    
    nanCount = zeros(CVO.NumTestSets,1);
    mae = zeros(CVO.NumTestSets,1);
    mse = zeros(CVO.NumTestSets,1);
    nrmse = zeros(CVO.NumTestSets,1);
    me = zeros(CVO.NumTestSets,1);
    ve = zeros(CVO.NumTestSets,1);
    r2 = zeros(CVO.NumTestSets,1);
    vo = zeros(CVO.NumTestSets,1);
    vZ = zeros(CVO.NumTestSets,1);
    
    if estFxTestFxMb
        fxIdx = obs.idMS < 10; %fixed index
        nanCountFX = zeros(CVO.NumTestSets,1);
        maeFX = zeros(CVO.NumTestSets,1);
        mseFX = zeros(CVO.NumTestSets,1);
        nrmseFX = zeros(CVO.NumTestSets,1);
        meFX = zeros(CVO.NumTestSets,1);
        veFX = zeros(CVO.NumTestSets,1);
        r2FX = zeros(CVO.NumTestSets,1);
        voFX = zeros(CVO.NumTestSets,1);
        vZFX = zeros(CVO.NumTestSets,1);
    end
    
    if writeTest2file == '1'
        testArr = zeros(sum(CVO.TestSize),3);
    end
    
    testEnd = 0;
    for i = 1:CVO.NumTestSets
        trIdx = CVO.training(i); % training index
        teIdx = CVO.test(i);     % test index 
        
        if i == 1
            testBeg = 1 ;
        else
            testBeg = testBeg + CVO.TestSize(i-1);
        end
        testEnd = testEnd + CVO.TestSize(i);
        
        pk = ph(teIdx,:);

        %change zs to xs. its hack for now, ask Marc
        %save xk and gok with folds
        [xk,vk]=krigingME(pk,ph(trIdx,:),cs,xh(trIdx,:),zs,vs, ...
            covmodel,covparam,nhmax,nsmax,dmax,order,options);
        
        if go.scenario == '0'
            ZkBMEm=xk;
        else
            ZkBMEm=xk+goh(teIdx,:);
        end        
        
        nanCount(i) = sum(isnan(ZkBMEm));
        mae(i) = mean(abs(ZkBMEm-Z(teIdx)),'all','omitnan');
        mse(i) = mean((ZkBMEm-Z(teIdx)).^2,'all','omitnan');
        nrmse(i) = sqrt(mse(i))/mean(Z(teIdx),'omitnan');
        me(i) = mean(ZkBMEm-Z(teIdx),'all','omitnan');
        ve(i) = var(ZkBMEm-Z(teIdx),'omitnan');
        rcoef = corrcoef(ZkBMEm,Z(teIdx),'rows','complete') ;
        r2(i) = rcoef(1,2)^2;
        vo(i) = var(Z(teIdx),'omitnan') ;
        vZ(i) = var(ZkBMEm,'omitnan') ;
        
        
        if writeTest2file == '1'
            %write test set to array
            testArr(testBeg:testEnd,1) = Z(teIdx);
            testArr(testBeg:testEnd,2) = ZkBMEm;
            testArr(testBeg:testEnd,3) = repmat(i,CVO.TestSize(i),1); 
        end
        
        if estFxTestFxMb
            %intersection of training data and value of fixed data while
            %keeping the test data the same.
            [xk2,vk2]=krigingME(pk,ph(and(trIdx,fxIdx),:),cs, ...
                xh(and(trIdx,fxIdx),:),zs,vs,covmodel,covparam, ...
                nhmax,nsmax,dmax,order,options);
            %add offset
            if go.scenario == '0'
                ZkBMEm2=xk2;
            else
                ZkBMEm2=xk2+goh(teIdx,:);
            end
            
            nanCountFX(i) = sum(isnan(ZkBMEm2));
            maeFX(i) = mean(abs(ZkBMEm2-Z(teIdx)),'all','omitnan');
            mseFX(i) = mean((ZkBMEm2-Z(teIdx)).^2,'all','omitnan');
            nrmseFX(i) = sqrt(mseFX(i))/sum(Z(teIdx),'omitnan');
            meFX(i) = mean(ZkBMEm2-Z(teIdx),'all','omitnan');
            veFX(i) = var(ZkBMEm2-Z(teIdx),'omitnan');
            rcoefFX = corrcoef(ZkBMEm2,Z(teIdx),'rows','complete') ;
            r2FX(i) =  rcoefFX(1,2)^2;
            vo(i) = var(Z(teIdx),'omitnan') ;
            vZ(i) = var(ZkBMEm,'omitnan') ;
            
        end    
        
    end 
    
    %keep information for each fold
    nanCount0 = sum(nanCount);
    mae0 = mean(mae);
    mse0 = mean(mse);
    nrmse0 = mean(nrmse);
    me0  = mean(me);
    ve0  = mean(ve);
    r2std =  std(r2);
    r20    =  mean(r2);
    %stacked r2
    
    outS = array2table([nanCount,mae,me,ve,mse,nrmse,r2,blank,fold],'VariableNames',{'NaNs','MAE','ME','VE','MSE','NRMSE','R2','R2std','Fold'});
    outS0 = array2table([nanCount0,mae0,me0,ve0,mse0,nrmse0,r20,r2std,0],'VariableNames',{'NaNs','MAE','ME','VE','MSE','NRMSE','R2','R2std','Fold'});
    outS = [outS;outS0];
    outS.SCN  =  repmat(obs.scn, size(fold,1)+1, 1);
    outS.TrainSubset = repmat({'None'}, size(fold,1)+1, 1);
    
    if estFxTestFxMb
        nanCount0FX = sum(nanCountFX);
        mae0FX = mean(maeFX);
        mse0FX = mean(mseFX);
        nrmse0FX = mean(nrmseFX);
        me0FX  = mean(meFX);
        ve0FX  = mean(veFX);
        r2stdFX =  std(r2FX);
        r20FX    =  mean(r2FX);
        outSFX = array2table([nanCountFX,maeFX,meFX,veFX,mseFX,nrmseFX,r2FX,blank,fold],'VariableNames',{'NaNs','MAE','ME','VE','MSE','NRMSE','R2','R2std','Fold'});
        outS0FX = array2table([nanCount0FX,mae0FX,me0FX,ve0FX,mse0FX,nrmse0FX,r20FX,r2stdFX,0],'VariableNames',{'NaNs','MAE','ME','VE','MSE','NRMSE','R2','R2std','Fold'});
        outSFX = [outSFX;outS0FX];
        outSFX.SCN  =  repmat(obs.scn, size(fold,1)+1, 1);
        outSFX.TrainSubset = repmat({'None'}, size(fold,1)+1, 1);
        
        outSFX.SCN = repmat(obs.scn, size(fold,1)+1, 1);
        outSFX.TrainSubset = repmat({'Fixed'}, size(fold,1)+1, 1);
        outS = [outS;outSFX]; 
    end
       
    writetable(outS,sprintf('%s/xvalTable_%s.csv',xvalDir,obs.scn));
    
    %write test set array to csv
    if writeTest2file == '1'
        outT = array2table(testArr,'VariableNames',{'Obs','Pred','Fold'});
        writetable(outT,sprintf('%s/testSets_%s.csv',xvalDir,obs.scn));
    end
end
