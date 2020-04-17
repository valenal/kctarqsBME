function dt = dts2date(tk,tIn,tOut)

    fmts.min   = 'yyyymmddHHMM';
    fmts.hour  = 'yyyymmddHH';
    fmts.day   = 'yyyymmdd';
    fmts.month = 'yyyymm';
    fmt = fmts.(tOut);

    if strcmp(tIn,'year')
        dt = 2018;
    elseif strcmp(tIn,'month')
        secInDay = 86400;
        dt = datestr(datetime(( (tk-1)*30.44*24*3600 - secInDay*2) , 'convertfrom','posixtime'),fmt); %hack
        %dt = datestr(datetime(( (tk-1)*30.44*24*3600) , 'convertfrom','posixtime'),fmt);
    elseif strcmp(tIn,'day')
        dt = datestr(datetime(tk*24*3600, 'convertfrom','posixtime'),fmt);
    elseif strcmp(tIn,'hour')
        dt = datestr(datetime(tk*3600, 'convertfrom','posixtime'),fmt);
    elseif strcmp(tIn,'min')
        dt = datestr(datetime(tk*60, 'convertfrom','posixtime'),fmt);
    end

end

