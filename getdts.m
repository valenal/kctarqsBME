function dt = getdts(tk,tave) 
    % get date string in dt
    if tave == 'Y'
        dt = 2018;
    elseif tave == 'M'
        mth = mod(tk,12);
        yr = (1970+fix(tk/12));
        
        if mth == 00
            yr = yr - 1;
            mth = 12;
        end
        dt = yr*100+mth;
    elseif tave == 'D'
        dt = datestr(datetime(tk*24*3600, 'convertfrom','posixtime'),'yyyymmdd');
    elseif tave == 'H'
        dt = datestr(datetime(tk*3600, 'convertfrom','posixtime'),'yyyymmddHH');
    elseif tave == '60s'
        dt = datestr(datetime(tk*60, 'convertfrom','posixtime'),'yyyymmddHHMM');
    end

end 