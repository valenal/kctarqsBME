function [mae,mse,nrmse,me,r2,r2std]=getBmeXval(obs,go,cs,zs,vs,covmodel,covparam,nhmax,nsmax,dmax,order,options)  
    %ToDo: 
    % 1. Add more statistics (check email) - DONE
    % 2. Keep Stats for eachfold - DONE
    % 3. Crossvalidation in time and space - DONE   

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

    groupType = '2fold'; %k,cluster,month,2fold
    switch groupType
        case {'cluster','month','2fold'}
            if strcmp(groupType,'2fold')
                grp = obs.cluster;
                grp = int8(grp < 5);
            else
                grp = obs.(groupType);
            end
            CVO.uniqueGroup = unique(grp);
            CVO.NumTestSets = size(CVO.uniqueGroup,1);
            CVO.TestSize = histc(grp,CVO.uniqueGroup);
        case 'k', CVO = cvpartition(xh,'k',10);
        case 'LeaveOut', CVO = cvpartition(xh,'LeaveOut');

    end
    
    blank =  zeros(CVO.NumTestSets,1);
    fold = (1:CVO.NumTestSets)'; 
    
    nanCount = zeros(CVO.NumTestSets,1);
    mae = zeros(CVO.NumTestSets,1);
    mse = zeros(CVO.NumTestSets,1);
    nrmse = zeros(CVO.NumTestSets,1);
    me = zeros(CVO.NumTestSets,1);
    ve = zeros(CVO.NumTestSets,1);
    r2 = zeros(CVO.NumTestSets,1);
    
    if estFxTestFxMb
        fxIdx = obs.idMS < 10; %fixed index
        nanCountFX = zeros(CVO.NumTestSets,1);
        maeFX = zeros(CVO.NumTestSets,1);
        mseFX = zeros(CVO.NumTestSets,1);
        nrmseFX = zeros(CVO.NumTestSets,1);
        meFX = zeros(CVO.NumTestSets,1);
        veFX = zeros(CVO.NumTestSets,1);
        r2FX = zeros(CVO.NumTestSets,1);
    end
    

    %write test set to array
    testArr = zeros(sum(CVO.TestSize),3);
    if estFxTestFxMb
        testArr0 = zeros(sum(CVO.TestSize),1);
    end

    
    testEnd = 0;
    for i = 1:CVO.NumTestSets
        
        switch groupType
            case {'cluster','month','2fold'}
                grpNum = CVO.uniqueGroup(i);
                trIdx = grpNum ~= grp; % training index
                teIdx = grpNum == grp;     % test index 
            otherwise
                trIdx = CVO.training(i); % training index
                teIdx = CVO.test(i);     % test index 
        end
        
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
        
      
        %write test set to array
        testArr(testBeg:testEnd,1) = Z(teIdx);
        testArr(testBeg:testEnd,2) = ZkBMEm;
        testArr(testBeg:testEnd,3) = repmat(i,CVO.TestSize(i),1);

        
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
            
            %test set array
            testArr0(testBeg:testEnd,1) = ZkBMEm2;
            
        end    
        
    end 
    
    nanCount0 = sum(nanCount);
    mae0 = mean(mae);
    mse0 = mean(mse);
    nrmse0 = mean(nrmse);
    me0  = mean(me);
    ve0  = mean(ve);
    r2std =  std(r2);
    r20   =  mean(r2);
    rstk0 = corrcoef(testArr(:,2),testArr(:,1),'rows','complete') ;
    r2stk0 =  rstk0(1,2)^2;
    
    mseb = mean((testArr(:,2)-testArr(:,1)).^2,'all','omitnan');
    meb = mean((testArr(:,2)-testArr(:,1)),'all','omitnan');
    vo = var(testArr(:,1),'omitnan') ;
    vZ = var(testArr(:,2),'omitnan') ;
    r2chk= ( (vo+vZ-(mseb-meb^2))/(2*sqrt(vo)*sqrt(vZ)) )^2;
    %[b,bint,r,rint,stats] =regress(testArr(:,1),[testArr(:,2), 1+zeros(sum(CVO.TestSize),1)] );
    
    outS = array2table([nanCount,mae,me,ve,mse,nrmse,r2,blank,blank,fold],'VariableNames',{'NaNs','MAE','ME','VE','MSE','NRMSE','R2','R2std','R2stk','Fold'});
    outS0 = array2table([nanCount0,mae0,me0,ve0,mse0,nrmse0,r20,r2std,r2stk0,0],'VariableNames',{'NaNs','MAE','ME','VE','MSE','NRMSE','R2','R2std','R2stk','Fold'});
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
        rstk0FX = corrcoef(testArr0(:,1),testArr(:,1),'rows','complete') ;
        r2stk0FX =  rstk0FX(1,2)^2;
        outSFX = array2table([nanCountFX,maeFX,meFX,veFX,mseFX,nrmseFX,r2FX,blank,blank,fold],'VariableNames',{'NaNs','MAE','ME','VE','MSE','NRMSE','R2','R2std','R2stk','Fold'});
        outS0FX = array2table([nanCount0FX,mae0FX,me0FX,ve0FX,mse0FX,nrmse0FX,r20FX,r2stdFX,r2stk0FX,0],'VariableNames',{'NaNs','MAE','ME','VE','MSE','NRMSE','R2','R2std','R2stk','Fold'});
        outSFX = [outSFX;outS0FX];
        outSFX.SCN  =  repmat(obs.scn, size(fold,1)+1, 1);
        outSFX.TrainSubset = repmat({'None'}, size(fold,1)+1, 1);
        
        outSFX.SCN = repmat(obs.scn, size(fold,1)+1, 1);
        outSFX.TrainSubset = repmat({'Fixed'}, size(fold,1)+1, 1);
        outS = [outS;outSFX]; 
    end
       
    writetable(outS,sprintf('%s/xvalTable_%s_%s.csv',xvalDir,obs.scn,groupType));
    
    %write test set array to csv
    if writeTest2file == '1'
        if estFxTestFxMb
            outT = array2table([testArr,testArr0],'VariableNames',{'Obs','Pred','Fold','Pred2'});
        else
            outT = array2table(testArr,'VariableNames',{'Obs','Pred','Fold'});
        end
        writetable(outT,sprintf('%s/testSets_%s_%s.csv',xvalDir,obs.scn,groupType));
    end
end
