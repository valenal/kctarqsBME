function drawCurve(cov,clr,ST)
%c01=v*0.90; ar1=200; at1=2;  c02=v*0.10; ar2=10000; at2=50;
%cov.covparam={[c01 ar1 at1],[c02 ar2 at2]};
%drawCurve(cov,ST)

    h=[];
    if strcmp(ST,'S')
        %
        % plot the spatial component of the covariance model 
        %
        rInt = 50;
        r=[0:rInt:cov.rLag(end)]';
        c1=[r 0*r 0*r];
        c2=[0 0 0];
        CrModel=coord2K(c1,c2,cov.covmodel,cov.covparam);
        h(length(h)+1)=plot(r(:),CrModel,sprintf('%s',clr));
    else
        %
        % plot the temporal component of the covariance model
        %  
        rInt = 0.1;
        tau=[0:rInt:cov.tLag(end)]';
        c1=[0*tau 0*tau tau];
        c2=[0 0 0];
        CtModel=coord2K(c1,c2,cov.covmodel,cov.covparam);
        h(length(h)+1)=plot(tau,CtModel,sprintf('%s',clr));
    end

end
