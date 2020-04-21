;Function description: get the station ID that has min distance with the given lon/lat.
undef("Get_Station_ID")
function Get_Station_ID(site_lon, site_lat, station_ll_CH[*][*], station_ID_CH, station_Name_CH)
local Distance
begin
    Distance             = (station_ll_CH(0,:) - site_lat)^2 + (station_ll_CH(1,:) - site_lon)^2
    site_ind             = minind(Distance)  ;-- station ind
    
    site_ID              = station_ID_CH(site_ind)  ;-- station ID
    site_ID@staion_ind   = site_ind
    site_ID@station_lat  = station_ll_CH(0, site_ind)
    site_ID@station_lon  = station_ll_CH(1, site_ind)
    site_ID@station_name = station_Name_CH(site_ind)
    
    return(site_ID)
end


;Function description: get the lon/lat according to the wrfout grid.
;Notice: This function is used to this script.
undef("Get_LonLat_fromGrid")
function Get_LonLat_fromGrid(wrfout_file, wrfout_grid)
local fin_1, xlons, xlats, iSN, iWE
begin
    fin_1    = addfile(wrfout_file, "r")  
    xlons    = fin_1->XLONG(1,:,:)
    xlats    = fin_1->XLAT(1,:,:)
    
    Out_Data = new(dimsizes(wrfout_grid), float)    ;save the lon/lat from wrfout
    do i = 0, dimsizes(wrfout_grid(:,0))-1
        iSN            = wrfout_grid(i, 0)  ;the grid ind at south_north
        iWE            = wrfout_grid(i, 1)  ;the grid ind at west_east
        Out_Data(i, 0) = xlats(iSN, iWE)    ;lat
        Out_Data(i, 1) = xlons(iSN, iWE)    ;lon
    end do

    return(Out_Data)
end

;Get the observed value(Temperature, Wind direction, Wind speed) at single station
undef("Get_Obv_Station")
function Get_Obv_Station(site_ID)
local Distance, Kinds, Months, Days, Hours, \
diri_1, diri_2, suffix, _getvar, nHour, _get_Year_Month, _get_Day, _get_Hour, _get_T, _get_Wind_D, _get_Wind_S, \
Factors, month, day, hour
begin

    diri_1          = "/home/lisi/wrf/namelist/article/verify/meteorology/"
    diri_2          = diri_1 + "china_isd_lite_2016/"  ;file directory
    suffix          = "-99999-2016"

    _getvar         = asciiread(diri_2+site_ID+suffix, -1, "string")
    nHour           = dimsizes(_getvar)
    
    _get_Year_Month = str_get_cols(_getvar, 0, 6)
    _get_Day        = tointeger(str_get_cols(_getvar,  8,  9))
    _get_Hour       = tointeger(str_get_cols(_getvar, 11, 12))
    _get_T          = tofloat(str_get_cols(_getvar, 14, 18))   ;--- UNITS: Degrees Celsius, SCALING FACTOR: 10, MISSING value: -9999
    _get_Wind_D     = tofloat(str_get_cols(_getvar, 31, 36))   
                      ;  The wind angle:
                      ;    a clockwise direction, between true north and the direction from which the wind is blowing.
                      ;    UNITS: Angular Degrees
                      ;    SCALING FACTOR: 1
                      ;    MISSING VALUE: -9999
    _get_Wind_S     = tofloat(str_get_cols(_getvar, 37, 42))   ;--- wind speed, UNITS: m/s, SCALING FACTOR: 10, MISSING VALUE: -9999
    Factors         = (/10.0, 1.0, 10.0/)

    ;;---- Read the station infortmation into the variable "value_obs"
    Kinds     = 3   ; !0 [ 3] : [0] is temperature, [1] is wind direction, [2] is wind speed.
    Months    = 2   ; !1 [ 2] : [0] is 2016.1, [1] is 2016.7
    Days      = 31  ; !2 [31] : the days(31)
    Hours     = 24  ; !3 [24] : the hours
    value_obs = new((/Kinds, Months, Days, Hours/), float, -999.9)

    do i = 0, nHour-1  ;Find the January and July data.
        if (_get_Year_Month(i).eq."2016 01" .or. _get_Year_Month(i).eq."2016 07") then
          day  = _get_Day(i)-1
          hour = _get_Hour(i)

          if (_get_Year_Month(i) .eq. "2016 01") then
            month = 0  ;Set for January(2016.1)
          else
            month = 1  ;Set fot July(2016.7)
          end if

          value_obs(0,month,day,hour) = _get_T(i) / Factors(0)           ;--- Read the temperature
          value_obs(1,month,day,hour) = _get_Wind_D(i)                   ;--- Read the wind direction
          value_obs(2,month,day,hour) = _get_Wind_S(i) / Factors(2)      ;--- Read the wind speed.
        end if
    end do

    ;change 'value_obs' to fixed dimension.
    Out_Data        = new((/2,2,dimsizes(ndtooned(value_obs(0,0,:,:)))/), float, 1e20)
    Out_Data(0,0,:) = ndtooned(value_obs(0,0,:,:))  ;temperature in January
    Out_Data(0,1,:) = ndtooned(value_obs(0,1,:,:))  ;temperature in July
    Out_Data(1,0,:) = ndtooned(value_obs(2,0,:,:))  ;wind speed in January
    Out_Data(1,1,:) = ndtooned(value_obs(2,1,:,:))  ;wind speed in July

    return(Out_Data)
end


;Get the simulated value(Temperature, Wind direction, Wind speed) at single station
undef("Get_Sim_Station")
function Get_Sim_Station(site_ID)
local diri_3, diri_4, filei_2, filei_3, fin_1, fin_2, xlons, xlats, interval, a1D, dsizes_a, inds_wrf, \
T_2m_1, T_2m_2, U_10m_1, U_10m_2, V_10m_1, V_10m_2, WS_10m_1, WS_10m_2, time_length
begin
    ;---open wrfout files.
    diri_3              = "/home/lisi/wrf/model_output/data/2016.1_noMOZBC/d01/"
    diri_4              = "/home/lisi/wrf/model_output/data/2016.7/d01/"
    filei_2             = "wrfout_d01_2016.1_control"
    filei_3             = "wrfout_d01_2016.7_control"
    
    fin_1               = addfile(diri_3+filei_2, "r")
    fin_2               = addfile(diri_4+filei_3, "r")
    
    xlons               = fin_1->XLONG(1,:,:)
    xlats               = fin_1->XLAT(1,:,:)
    
    ;--- find out the nearest grid ind according to the station lon/lat.    
    interval            = (xlons - site_ID@station_lon)^2 + (xlats - site_ID@station_lat)^2
    a1D                 = ndtooned(interval)
    dsizes_a            = dimsizes(interval)
    inds_wrf            = ind_resolve(minind(a1D),dsizes_a)
    ; print(xlons(inds_wrf(0,0),inds_wrf(0,1)))
    ; print(xlats(inds_wrf(0,0),inds_wrf(0,1)))
    
    ;--- read the temperature and wind speed from wrfout.
    T_2m_1              = wrf_user_getvar(fin_1, "T2", -1) - 273.15   ;--- 2m temperature in 2016.1, unit:K
    U_10m_1             = wrf_user_getvar(fin_1, "U10", -1)           ;--- Ua in 2016.1
    V_10m_1             = wrf_user_getvar(fin_1, "V10", -1)           ;--- Va in 2016.1
    WS_10m_1            = (U_10m_1^2 + V_10m_1^2)^0.5                 ;--- wind speed in 2016.1
    T_2m_2              = wrf_user_getvar(fin_2, "T2", -1) - 273.15   ;--- temperature in 2016.7
    U_10m_2             = wrf_user_getvar(fin_2, "U10", -1)           ;--- Ua in 2016.7
    V_10m_2             = wrf_user_getvar(fin_2, "V10", -1)           ;--- Va in 2016.7
    WS_10m_2            = (U_10m_2^2 + V_10m_2^2)^0.5                 ;--- wind speed in 2016.7
     
    ;--- create the output data.
    time_length         = dimsizes(T_2m_1(:,0,0))
    value_wrfout        = new((/2,2,time_length/), float, -999.9)
                          ;dim0[2]: 0=temperature, 1=wind_speed
                          ;dim1[2]: 0=January,     1=July
                          ;dim2[:]: hours
    value_wrfout(0,0,:) = (/  T_2m_1(:, inds_wrf(0,0), inds_wrf(0,1))/)    ;--- 2m temperature in 2016.1
    value_wrfout(0,1,:) = (/  T_2m_2(:, inds_wrf(0,0), inds_wrf(0,1))/)    ;--- 2m temperature in 2016.7
    value_wrfout(1,0,:) = (/WS_10m_1(:, inds_wrf(0,0), inds_wrf(0,1))/)    ;--- 10m wind speed in 2016.1
    value_wrfout(1,1,:) = (/WS_10m_2(:, inds_wrf(0,0), inds_wrf(0,1))/)    ;--- 10m wind speed in 2016.7

    ;--- output
    return(value_wrfout)
end