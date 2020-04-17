function testplotCOV(cov,ST)
    if strcmp(ST,'S')
        %
        % plot the experimental values and the model for the covariance
        % K(r,t=0) as function of spatial lag rLag
        %
        figure;
        h=[];
        leg=[];
        h(length(h)+1)=plot(cov.rLag,cov.Cr,'o');
        leg{length(h)}='Experimental values';
        hold on;

        %
        % plot the spatial component of the covariance model 
        %

        rInt = 50;
        r=[0:rInt:cov.rLag(end)]';
        c1=[r 0*r 0*r];
        c2=[0 0 0];
        CrModel=coord2K(c1,c2,cov.covmodel,cov.covparam);
        h(length(h)+1)=plot(r(:),CrModel,'-r');
        leg{length(h)}=['Exponential model'];
        legend(h,leg);
        xlabel('Spatial lag, r (m)');
        ylabel('c(r,\tau=0)');
        axis([r(1) r(end) 0 1.1*cov.var]);
        title(['Covariance c(r,\tau) for '  cov.tave]);
    else
        %
        % plot the experimental values and the model for the covariance
        % C(r=0,t) as function of temporal lag tLag
        %
        figure;
        h=[];
        leg=[];
        h(length(h)+1)=plot(cov.tLag,cov.Ct,'o');
        leg{length(h)}='Experimental values';
        hold on;

        %
        % plot the temporal component of the covariance model
        %  

        rInt = 0.1;
        tau=[0:rInt:cov.tLag(end)]';
        c1=[0*tau 0*tau tau];
        c2=[0 0 0];
        CtModel=coord2K(c1,c2,cov.covmodel,cov.covparam);
        h(length(h)+1)=plot(tau,CtModel,'-r');
        leg{length(h)}=['Exponential model'];
        xlabel('Time lag, \tau ');
        ylabel('c(r=0,\tau)');
        legend(h,leg);
        axis([tau(1) tau(end) 0 1.1*cov.var]);
    end

end
