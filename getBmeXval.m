function [mae,mse,nrmse,me,r2,r2std]=getBmeXval(obs,go,cs,zs,vs,covmodel,covparam,nhmax,nsmax,dmax,order,options)  

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
            xh = obs.vals; %obs
            goh= 0; %offset
            Z  = xh; %obs
    end

    %https://www.mathworks.com/help/stats/cvpartition-class.html
    CVO = cvpartition(xh,'k',10);
    %CVO = cvpartition(xh,'LeaveOut');
    mae = zeros(CVO.NumTestSets,1);
    mse = zeros(CVO.NumTestSets,1);
    nrmse = zeros(CVO.NumTestSets,1);
    me = zeros(CVO.NumTestSets,1);
    ve = zeros(CVO.NumTestSets,1);
    r2 = zeros(CVO.NumTestSets,1);
    for i = 1:CVO.NumTestSets
        trIdx = CVO.training(i); % training index
        teIdx = CVO.test(i);     % test index 
        
        pk = ph(teIdx,:);

        %change zs to xs. its hack for now, ask Marc
        %save xk and gok with folds
        [xk,vk]=krigingME(pk,ph(trIdx,:),cs,xh(trIdx,:),zs,vs, ...
            covmodel,covparam,nhmax,nsmax,dmax,order,options);
        
        %intersection of training data and value of fixed data while
        %keeping the test data the same.
        %[xk,vk]=krigingME(pk,ph(trIdx,:),cs,xh(trIdx,:),zs,vs, ...
        %    covmodel,covparam,nhmax,nsmax,dmax,order,options);
        
        xk(isnan(xk))=0;%ask Marc. instead remove values 
        
        %add offset
        if go.scenario == '0'
            ZkBMEm=xk;
        else
            ZkBMEm=xk+goh(teIdx,:);
        end
        mae(i) = mean(abs(ZkBMEm-Z(teIdx)),'all');
        mse(i) = mean((ZkBMEm-Z(teIdx)).^2,'all');
        nrmse(i) = sqrt(mse(i))/sum(Z(teIdx));
        me(i) = mean(ZkBMEm-Z(teIdx),'all');
        ve(i) = var(ZkBMEm-Z(teIdx),'omitnan');
        rcoef = corrcoef(ZkBMEm,Z(teIdx)) ;
        r2(i) =  rcoef(1,2)^2;
        
    end 
    
    mae = mean(mae);
    mse = mean(mse);
    nrmse = mean(nrmse);
    me  = mean(me);
    ve  = mean(ve);
    r2std =  std(r2);
    r2    =  mean(r2);
    
    outT = array2table([mae,me,ve,mse,nrmse,r2,r2std],'VariableNames',{'MAE','ME','VE','MSE','NRMSE','R2','R2std'});
    outT.SCN = obs.scn;
    writetable(outT,sprintf('%s/xvalTable_%s.csv',xvalDir,obs.scn));
    
end
