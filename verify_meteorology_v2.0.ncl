;target:       verify the wrfout about the meteorology: Temperature, wind speed, wind direction.
;created time: 2019/6/10
;changed time: 2020/3/25
;change the output csv files

;Function description: get the xy-line resource.
undef("get_res_lines")
function get_res_lines(ResIn[1]:logical)
begin
    ResOut = ResIn
    ResOut@gsnCenterStringFontHeightF  = 0.025                ;-- the font size of gsnCenterString
    ResOut@tiXAxisString               = "Date (UTC)"
    ResOut@tiXAxisFontHeightF          = 0.015                ;-- default is 0.025
    ResOut@tiYAxisFontHeightF          = 0.015                ;-- default is 0.025
    ;## Set the present mode
    ; ResOut@xyMarkLineModes             = (/"Lines", "Markers"/) ;--- Sim is lines, Obs is markers
    ResOut@xyMarkLineModes             = (/"Lines", "Lines"/) ;--- Sim is lines, Obs is markers
    ResOut@xyDashPatterns              = (/0, 1/)                    ;--- solid line
    ResOut@xyLineThicknessF            = 1.0
    ResOut@xyLineColors                = (/"black", "red"/)
    ResOut@xyMarker                    = 1                    ;--- marker
    ResOut@xyMarkerSizeF               = 0.012
    ResOut@xyMarkerColor               = "red"
    ResOut@xyExplicitLegendLabels      = (/"Sim", "Obs"/)

    Max_Hours                          = 721
    ResOut@trXMaxF                     = tofloat(Max_Hours)         ;--- a maximum X coordinate value

    ;--- Set the bottom X-axis
    ResOut@tmXBMode                    = "Explicit"           ;--- manually set the value and label in X-axis Bottom
    ResOut@tmXBValues                  = ispan(7, 721, 48)
    ResOut@tmXBLabels                  = sprinti("%02i", ispan(2, 31, 2)) + " Jan"
    ResOut@tmXBLabelAngleF             = 50.
    ResOut@tmXBLabelJust               = "CenterRight"        ;--- the position of label for major tickmark
    ResOut@tmXBLabelFontHeightF        = 0.012                ;--- size of XB label
    ResOut@tmXBLabelDeltaF             = -0.5                 ;--- move the XB label up(refer to P99 in books)
    ResOut@tmXBMinorOn                 = False                ;--- close the XB minor tickmark
    ;--- Set the top  X-axis
    ResOut@tmXTOn                      = False                ;--- close the XT elements(major and minor tickmark, label)
    ;--- Set the left Y-axis
    ResOut@tmYLLabelFontHeightF        = 0.015                ;--- size of YL label
    ResOut@tmYLLabelDeltaF             = -0.6                 ;--- move the YL label right(refer to P99 in books)
    ;--- Set the right Y-axis
    ResOut@tmYROn                      = False                ;--- close the XT elements(major and minor tickmark, label)

    ResOut@vpWidthF                    = 1.0
    ResOut@vpHeightF                   = 0.3

    ResOut@pmLegendDisplayMode         = "Always"             ;-- display legend
    ResOut@pmLegendWidthF              = 0.12                 ;-- define legend width
    ResOut@pmLegendHeightF             = 0.05                 ;-- define legend height
    ResOut@pmLegendOrthogonalPosF      = -1.3                 ;-- move legend upward
    ResOut@pmLegendParallelPosF        = 0.5                  ;-- move legend right

    ;--------------return the resulted res
    return(ResOut)
end

;Function description: get the xy-line resource.
undef("get_res_lines_Day")
function get_res_lines_Day(ResIn[1]:logical)
begin
    ResOut = ResIn

    ;delete not right attributes.
    if (isatt(ResIn, "trXMaxF")) then
        delete(ResOut@trXMaxF)
    end if
    if (isatt(ResIn, "tmXBValues")) then
      delete_VarAtts(ResOut, (/"tmXBValues"/))
    end if
    if (isatt(ResIn, "tmXBLabels")) then
      delete_VarAtts(ResOut, (/"tmXBLabels"/))
    end if

    ResOut@tmXBValues                  = ispan(1, 30, 2)
    ResOut@tmXBLabels                  = sprinti("%02i", ispan(2, 31, 2)) + " Jan"

    return(ResOut)
end

;Function description: get the xy-scatter resource.
undef("get_res_scatter")
function get_res_scatter(ResIn[1]:logical)
begin
    ResOut = ResIn
    ;--- resource of Scatters
    ResOut                               = ResIn
    ResOut@xyMarkLineMode                = "Markers"
    ResOut@xyMarkers                     = 6                ;--- choose type of marker  
    ResOut@xyMarkerColor                 = "steelblue3"            ;--- Marker color
    ResOut@xyMarkerSizeF                 = 0.008               ;--- Marker size (default 0.01)
    ; ResOut@gsnCenterStringFontHeightF    = 0.025              ;--- the font size of gsnCenterString
    ResOut@tiXAxisString                 = "Observation"
    ResOut@tiYAxisString                 = "Simulation"
    ; ResOut@tiXAxisOffsetYF               = 0.1

    ;--- Set the top  X-axis
    ResOut@tmXTOn                      = False                ;--- close the XT elements(major and minor tickmark, label)
    ;--- Set the right Y-axis
    ResOut@tmYROn                      = False                ;--- close the YR elements(major and minor tickmark, label)

    ;--------------return the resulted res
    return(ResOut)
end


;Function description: get the station ID that has min distance with the given lon/lat.
undef("Get_Station_ID")
function Get_Station_ID(site_lon, site_lat, station_ll_CH[*][*], station_ID_CH)
local Distance
begin
    Distance            = (station_ll_CH(0,:) - site_lat)^2 + (station_ll_CH(1,:) - site_lon)^2
    site_ind            = minind(Distance)  ;-- station ind
    
    site_ID             = station_ID_CH(site_ind)  ;-- station ID
    site_ID@staion_ind  = site_ind
    site_ID@station_lat = station_ll_CH(0, site_ind)
    site_ID@station_lon = station_ll_CH(1, site_ind)
    
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


;Overlay the 5:1 lines on the base plot.
undef("add_scale_line")
procedure add_scale_line(wks, base_plot:graphic, ResIn:logical, scale)
local a
begin
    Min                        = ResIn@trXMinF
    Max                        = ResIn@trXMaxF
    
    Rate                       = scale
    rates                      = (/1./Rate, 1., 1*Rate/)
    
    res_lines                  = True
    res_lines@gsnDraw          = False
    res_lines@gsnFrame         = False
    res_lines@gsnMaximize      = True
    ;Set top X-Axis
    res_lines@tmXTOn           = False
    ;Set Right Y-Axis
    res_lines@tmYROn           = False
    
    res_lines@xyMarkLineMode   = "Lines"
    res_lines@xyDashPattern    = 0                  ;--- solid line
    res_lines@xyLineColor      = "black"
    res_lines@xyLineThicknessF = 1.0

    data_x = (/Min, Max/)

    plots_line = new(3, graphic)

    do i = 0, 2
      data_y        = data_x * rates(i)
      plots_line(i) = gsn_csm_xy(wks, data_x, data_y, res_lines)  ;scale line

      overlay(base_plot, plots_line(i))                           ;add the scale line on the base_plot
    end do
end


begin
  ;===| Step 1.0 Set the file directory and name |===
    diri_1  = "/home/lisi/wrf/namelist/article/verify/meteorology/"
    diri_2  = diri_1 + "china_isd_lite_2016/"
    diri_3  = "/home/lisi/wrf/model_output/data/2016.1_noMOZBC/d01/"
    diri_4  = "/home/lisi/wrf/model_output/data/2016.7/d01/"
    filei_1 = "isd-history.txt"
    filei_2 = "wrfout_d01_2016.1_control"
    filei_3 = "wrfout_d01_2016.7_control"
    suffix  = "-99999-2016"

  ;===| Step 1.1 Read the sites id and latitude and longtitude. |===
    _getvar         = asciiread(diri_1+filei_1, -1, "string")   ;-- _getvar(29732)
    _getvar        := _getvar(22:)                              ;--- discard the first 22 rows(file description)
    station_ID      = str_get_cols(_getvar,  0,  5)             ;-- station ID. May contain a letter in the first position.
    station_name    = str_get_cols(_getvar, 13, 42)             ;-- station name
    station_country = str_get_cols(_getvar, 43, 46)             ;-- country ID
    station_lat     = str_get_cols(_getvar, 57, 63)             ;-- Latitude in thousandths of decimal degrees
    station_lon     = str_get_cols(_getvar, 65, 72)             ;-- Longitude in thousandths of decimal degrees
    station_elev    = str_get_cols(_getvar, 74, 80)             ;-- Elevation in meters

  ;===| Step 1.2 Converting strings(station_lat, station_lon) to numbers |===
    ;station_lat
    station_lat_num = new(dimsizes(station_lat), float, 1e20)  ;--- missing value is 1e20
    ;station_lon
    station_lon_num = new(dimsizes(station_lon), float, 1e20)
    do i = 0, dimsizes(station_lat)-1   ;station_lat and station_lon have the same size.

      ;;tranlate the latitude string ('+/-') to numeric value
      sign = str_get_cols(station_lat(i), 0, 0)
      if (sign.eq."+") then
        station_lat_num(i) = tofloat(str_get_cols(station_lat(i), 1, 6))
      else if (sign.eq."-") then
        station_lat_num(i) = 0.0 - tofloat(str_get_cols(station_lat(i), 1, 6)) 
      else
        station_lat_num(i) = 1e20
      end if
      end if

      ;;tranlate the longitude string ('+/-') to numeric value
      sign = str_get_cols(station_lon(i), 0, 0)
      if (sign.eq."+") then
        station_lon_num(i) = tofloat(str_get_cols(station_lon(i), 1, 6))
      else if (sign.eq."-") then
        station_lon_num(i) = 0.0 - tofloat(str_get_cols(station_lon(i), 1, 6)) 
      else
        station_lon_num(i) = 1e20
      end if
      end if

    end do

  ;===| Step 1.3-Match the ID_CH with lat and lon |===
    station_ID_CH        = systemfunc("ls "+diri_2)
    station_ID_CH       := str_get_cols(station_ID_CH, 0, 5)
    station_ll_CH        = new((/2, dimsizes(station_ID_CH)/), float, 1e20)   ;--- station_ll_CH(0,:) is for lat, station_ll_CH(1,:) is for lon
    station_Elev_CH      = new(dimsizes(station_ID_CH), string, "no Elevation")
    station_Name_CH      = new(dimsizes(station_ID_CH), string, "no Name")

    do i = 0, dimsizes(station_ID_CH)-1
        do j = 0, dimsizes(station_ID)-1
          if (station_ID_CH(i) .eq. station_ID(j)) then
            station_ll_CH(0,i) = station_lat_num(j)  ;latitude
            station_ll_CH(1,i) = station_lon_num(j)  ;longtitude
            station_Elev_CH(i) = station_elev(j)
            station_Name_CH(i) = station_name(j)
            break
          end if
        end do
    end do


  ;===| Step 2.0-Select the station to verify |===
    sites_name = (/"Beijing","Chengde","Hinggan","Siping","Guyuan"/)
    sites_grid = (/(/18,55/),(/21,57/),(/30,62/),(/17,44/),(/9,36/)/)  ;--- from sleect_sites.ncl, except 1th(/21,56/), 4th(/23,49/)
    sites_lonlat = Get_LonLat_fromGrid(diri_3+filei_2, sites_grid)
    sites_lon  = sites_lonlat(:, 1)
    sites_lat  = sites_lonlat(:, 0)
    ; sites_lon  = (/ 116.366,    117.9664,  126.555,  109.8119,      105.18/)
    ; sites_lat  = (/ 39.8673,     40.9161,  43.8875,   39.5989,     37.0172/)
    nSites     = dimsizes(sites_name)


  ;===| Step 3.0-Read the right time data for simulation and observed |===
    time_length = 721
    value_Obv   = new((/nSites,2,2,time_length/), float, 1e20)
    value_Sim   = new((/nSites,2,2,time_length/), float, 1e20)
    do Nber = 0, 4
        site_ID               = Get_Station_ID(sites_lon(Nber), sites_lat(Nber), station_ll_CH, station_ID_CH)  ;Get the station ID among the CHina station.
        Obv                   = Get_Obv_Station(site_ID)  ;---obversation
        Sim                   = Get_Sim_Station(site_ID)  ;---simulation
        
        Time_s                = 18                              ;--- start time: 01-18:00:00 
        Time_e                = Time_s+time_length-1            ;--- end time:   31-18:00:00
        value_Obv(Nber,:,:,:) = Obv(:,:,Time_s:Time_e)
        value_Sim(Nber,:,:,:) = Sim(:,:,Time_s:)
    end do

    time       = ispan(1, time_length, 1)
    time@units = "hours since 2016-01-01 00:00:0.0"    

  ;===| Step 3.1-Calculate the day-average wind speed |===
    iKind   = 1   ;choose the wind speed
    nDay    = 30  ;2th, 3th, 4th, ......31th
    nMonth  = 2
    Wsp_Day_Obv = new((/nSites, nMonth, nDay/), float, 1e20)
    Wsp_Day_Sim = new((/nSites, nMonth, nDay/), float, 1e20)

    do iDay = 0, nDay-1
        ; 7  - 7+23
        ; 7+1*24 - 7+1*24+23
        ; 7+2*24 - 7+2*24+23
        ; 7+3*24
        ; ...
        ; 7+29*24 - 721
        Hour_s = 6+iDay*24  ;18,19,20,21,22,23  0 ------: 7th
        if (iDay.eq.29) then
            Hour_e = 720           ;last day isn't enough 24h
        else
            Hour_e = Hour_s + 23   ;a day is 24h
        end if

        ;calculate the day average wind speed.
        Wsp_Day_Obv(:,:,iDay) = dim_avg_n( value_Obv(:,iKind,:,Hour_s:Hour_e), 2 ) 
        Wsp_Day_Sim(:,:,iDay) = dim_avg_n( value_Sim(:,iKind,:,Hour_s:Hour_e), 2 ) 
    end do


  ;===| Step 4.0-Set the wks and resource for plots |===
    ; ; plots: total stations: January[temperature, windspeed]
    ; ;                        July   [temperature, windspeed]
    ; ;            5 stations: January[temperature, windspeed]
    ; ;                        July   [temperature, windspeed]
    ; type                   = "eps"
    ; ; type                   = "png"
    
    ; ; ;5 stations lines.
    ; ; wks_Jan_Line           = gsn_open_wks(type, "Jan_Line")
    ; ; wks_July_Line          = gsn_open_wks(type, "July_Line")
    ; ; plots_Jan_Line         = new(10, graphic)    ;--- save plots in January
    ; ; plots_July_Line        = new(10, graphic)    ;--- save plots in July
    
    ; ; ;total station scatters.
    ; ; wks_Temp_Scatter_All   = gsn_open_wks(type, "Temp_Scatter_All")
    ; ; wks_Wsp_Scatter_All    = gsn_open_wks(type, "Wsp_Scatter_All")
    ; ; plots_Temp_Scatter_All = new(2, graphic)
    ; ; plots_Wsp_Scatter_All  = new(2, graphic)
    
    ; ; ;5 stations scatters.
    ; ; wks_Temp_Scatter       = gsn_open_wks(type, "Temp_Scatter")
    ; ; wks_Wsp_Scatter        = gsn_open_wks(type, "Wsp_Scatter")
    ; ; plots_Temp_Scatter     = new(10, graphic)
    ; ; plots_Wsp_Scatter      = new(10, graphic)

    ; ;lines, scatters, all scatters only for wind speed on day.
    ; ;5 station lines.
    ; wks_Wsp_Day_Line = gsn_open_wks(type, "Wsp_Day_Line")
    ; plots_Wsp_Day_Line = new(10, graphic)
    ; ;5 stations scatters.
    ; wks_Wsp_Day_Scatter = gsn_open_wks(type, "Wsp_Day_Scatter")
    ; plots_Wsp_Day_Scatter = new(10, graphic)
    ; ;total stations scatters.
    ; wks_Wsp_Day_Scatter_All = gsn_open_wks(type, "Wsp_Day_Scatter_All")
    ; plots_Wsp_Day_Scatter_All = new(2, graphic)


    ; res             = True
    ; res@gsnDraw     = False
    ; res@gsnFrame    = False
    ; res@gsnMaximize = True

  ;===| Step 4.1-Draw the xy-Line plots for 5 stations|===
    ; Res_Line        = get_res_lines(res)
    ; do Nber = 0, 4
    ;     Res_Line@gsnCenterString  = sites_name(Nber)
        
    ;     ;temperature in 2016.1
    ;     Res_Line@tiYAxisString    = "Temperature ("+"~S~o~N~"+"C)"
    ;     Res_Line@tmXBLabels       = sprinti("%02i", ispan(2, 31, 2)) + " Jan"
    ;     plots_Jan_Line(Nber*2)    = gsn_csm_xy(wks_Jan_Line, time, (/value_Sim(Nber,0,0,:),  value_Obv(Nber,0,0,:)/), Res_Line)
        
    ;     ;temperature in 2016.7
    ;     Res_Line@tmXBLabels       = sprinti("%02i", ispan(2, 31, 2)) + " July"
    ;     plots_July_Line(Nber*2)   = gsn_csm_xy(wks_July_Line, time, (/value_Sim(Nber,0,1,:),  value_Obv(Nber,0,1,:)/), Res_Line)
        
    ;     ;wind speed in 2016.1
    ;     Res_Line@tiYAxisString    = "Wind Speed (m/s)"
    ;     Res_Line@tmXBLabels       = sprinti("%02i", ispan(2, 31, 2)) + " Jan"
    ;     plots_Jan_Line(Nber*2+1)  = gsn_csm_xy(wks_Jan_Line, time, (/value_Sim(Nber,1,0,:),  value_Obv(Nber,1,0,:)/), Res_Line)
        
    ;     ;wind speed in 2016.7
    ;     Res_Line@tmXBLabels       = sprinti("%02i", ispan(2, 31, 2)) + " July"
    ;     plots_July_Line(Nber*2+1) = gsn_csm_xy(wks_July_Line, time, (/value_Sim(Nber,1,1,:),  value_Obv(Nber,1,1,:)/), Res_Line)
    ; end do

  ;===| Step 4.2-Draw the xy-Scatters plots for total station|===
    ; Res_Scatter_All                 = get_res_scatter(res)
    
    ; ;temperature
    ; ;January
    ; x_data                          = ndtooned(value_Obv(:,0,0,:))
    ; y_data                          = ndtooned(value_Sim(:,0,0,:))
    ; Res_Scatter_All@gsnCenterString = "Temperature ("+"~S~o~N~"+"C) in January"
    ; Res_Scatter_All@trXMinF         = -30
    ; Res_Scatter_All@trXMaxF         =  10
    ; Res_Scatter_All@trYMinF         = -30
    ; Res_Scatter_All@trYMaxF         =  10
    ; plots_Temp_Scatter_All(0)       = gsn_csm_xy(wks_Temp_Scatter_All, x_data, y_data, Res_Scatter_All)
    ; add_scale_line(wks_Temp_Scatter_All, plots_Temp_Scatter_All(0), Res_Scatter_All, 2)
    ; ;July
    ; x_data                          = ndtooned(value_Obv(:,0,1,:))
    ; y_data                          = ndtooned(value_Sim(:,0,1,:))
    ; Res_Scatter_All@gsnCenterString = "Temperature ("+"~S~o~N~"+"C) in July"
    ; Res_Scatter_All@trXMinF         =   5
    ; Res_Scatter_All@trXMaxF         =  40
    ; Res_Scatter_All@trYMinF         =   5
    ; Res_Scatter_All@trYMaxF         =  40
    ; plots_Temp_Scatter_All(1)       = gsn_csm_xy(wks_Temp_Scatter_All, x_data, y_data, Res_Scatter_All)    
    ; add_scale_line(wks_Temp_Scatter_All, plots_Temp_Scatter_All(1), Res_Scatter_All, 2)
    
    ; ;windspeed at Jaunary and July
    ; ;January
    ; x_data                          = ndtooned(value_Obv(:,1,0,:))
    ; y_data                          = ndtooned(value_Sim(:,1,0,:))
    ; Res_Scatter_All@gsnCenterString = "Wind Speed (m/s) in January"
    ; Res_Scatter_All@trXMinF         =   0
    ; Res_Scatter_All@trXMaxF         =  15
    ; Res_Scatter_All@trYMinF         =   0
    ; Res_Scatter_All@trYMaxF         =  15
    ; plots_Wsp_Scatter_All(0)        = gsn_csm_xy(wks_Wsp_Scatter_All, x_data, y_data, Res_Scatter_All)
    ; add_scale_line(wks_Wsp_Scatter_All, plots_Wsp_Scatter_All(0), Res_Scatter_All, 5)
    ; ;July
    ; Res_Scatter_All@gsnCenterString = "Wind Speed (m/s) in July"
    ; x_data                          = ndtooned(value_Obv(:,1,1,:))
    ; y_data                          = ndtooned(value_Sim(:,1,1,:))
    ; plots_Wsp_Scatter_All(1)        = gsn_csm_xy(wks_Wsp_Scatter_All, x_data, y_data, Res_Scatter_All)
    ; add_scale_line(wks_Wsp_Scatter_All, plots_Wsp_Scatter_All(1), Res_Scatter_All, 5)

  ;===| Step 4.3-Draw the xy-Scatters plots for 5 stations|===
    ; Res_Scatter = get_res_scatter(res)
    ; do Nber = 0, 4
    ;     Res_Scatter@gsnCenterString  = sites_name(Nber)
        
    ;     ;temperature in 2016.1
    ;     ; Res_Scatter@tiYAxisString  = "Temperature ("+"~S~o~N~"+"C)"
    ;     plots_Temp_Scatter(Nber)   = gsn_csm_xy(wks_Temp_Scatter, value_Obv(Nber,0,0,:),  value_Sim(Nber,0,0,:), Res_Scatter)
    ;     ;temperature in 2016.7
    ;     plots_Temp_Scatter(Nber+5) = gsn_csm_xy(wks_Temp_Scatter, value_Obv(Nber,0,1,:),  value_Sim(Nber,0,1,:), Res_Scatter)
        
    ;     ;wind speed in 2016.1
    ;     ; Res_Scatter@tiYAxisString  = "Wind Speed (m/s)"
    ;     plots_Wsp_Scatter(Nber)    = gsn_csm_xy(wks_Wsp_Scatter, value_Obv(Nber,1,0,:), value_Sim(Nber,1,0,:), Res_Scatter)
    ;     ;wind speed in 2016.7
    ;     plots_Wsp_Scatter(Nber+5)  = gsn_csm_xy(wks_Wsp_Scatter, value_Obv(Nber,1,1,:), value_Sim(Nber,1,1,:), Res_Scatter)
    ; end do

  ;===| Step 4.4-Draw the wind speed for Day|===
  ;===| Step 4.4.1-Draw the xy-Line Day plots for 5 stations|===
    ; time_Day                     = ispan(1, 30, 1)
    ; Res_Line_Day                 = get_res_lines_Day(get_res_lines(res))
    ; ; Res_Line_Day@xyMarkLineModes = (/"Lines", "Lines"/) ;--- Sim is lines, Obs is markers
    ; do Nber = 0, 4
    ;     Res_Line_Day@gsnCenterString = sites_name(Nber)
        
    ;     ;wind speed in 2016.1
    ;     Res_Line_Day@tiYAxisString   = "Wind Speed (m/s)"
    ;     Res_Line_Day@tmXBLabels      = sprinti("%02i", ispan(2, 31, 2)) + " Jan"
    ;     plots_Wsp_Day_Line(Nber*2)     = gsn_csm_xy(wks_Wsp_Day_Line, time_Day, (/Wsp_Day_Sim(Nber,0,:),  Wsp_Day_Obv(Nber,0,:)/), Res_Line_Day)
        
    ;     ;wind speed in 2016.7
    ;     Res_Line_Day@tmXBLabels      = sprinti("%02i", ispan(2, 31, 2)) + " July"
    ;     plots_Wsp_Day_Line(Nber*2+1)   = gsn_csm_xy(wks_Wsp_Day_Line, time_Day, (/Wsp_Day_Sim(Nber,1,:),  Wsp_Day_Obv(Nber,1,:)/), Res_Line_Day)
    ; end do    

  ;===| Step 4.4.2-Draw the xy-Scatter Day plots for 5 stations|===
    ; Res_Scatter_Day               = get_res_scatter(res)
    ; Res_Scatter_Day@xyMarkerSizeF = 0.01               ;--- Marker size (default 0.01)
    ; Res_Scatter_Day@trXMinF       =   0
    ; Res_Scatter_Day@trXMaxF       =  10
    ; Res_Scatter_Day@trYMinF       =   0
    ; Res_Scatter_Day@trYMaxF       =  10
    ; do Nber = 0, 4
    ;     Res_Scatter_Day@gsnCenterString  = sites_name(Nber)      
    ;     ;wind speed in 2016.1
    ;     plots_Wsp_Day_Scatter(Nber)     = gsn_csm_xy(wks_Wsp_Day_Scatter, Wsp_Day_Sim(Nber,0,:),  Wsp_Day_Obv(Nber,0,:), Res_Scatter_Day)
    ;     ;wind speed in 2016.7
    ;     plots_Wsp_Day_Scatter(Nber+5)   = gsn_csm_xy(wks_Wsp_Day_Scatter, Wsp_Day_Sim(Nber,1,:),  Wsp_Day_Obv(Nber,1,:), Res_Scatter_Day)
    ; end do
    ; print("jsdfjsdfds=========")

  ;===| Step 4.4.3-Draw the xy-Scatter Day plots for all stations|===
    ; ;windspeed at Jaunary and July
    ; ;January
    ; Res_Scatter_Day@gsnCenterString = "Wind Speed (m/s) in January"
    ; Res_Scatter_Day@trXMinF         =   0
    ; Res_Scatter_Day@trXMaxF         =  15
    ; Res_Scatter_Day@trYMinF         =   0
    ; Res_Scatter_Day@trYMaxF         =  15
    ; x_data_Day                          = ndtooned(Wsp_Day_Obv(:,0,:))
    ; y_data_Day                          = ndtooned(Wsp_Day_Sim(:,0,:))
    ; plots_Wsp_Day_Scatter_All(0)        = gsn_csm_xy(wks_Wsp_Day_Scatter_All, x_data_Day, y_data_Day, Res_Scatter_Day)
    ; add_scale_line(wks_Wsp_Day_Scatter_All, plots_Wsp_Day_Scatter_All(0), Res_Scatter_Day, 5)
    ; ;July
    ; Res_Scatter_Day@gsnCenterString = "Wind Speed (m/s) in July"
    ; x_data_Day                          = ndtooned(Wsp_Day_Obv(:,1,:))
    ; y_data_Day                          = ndtooned(Wsp_Day_Sim(:,1,:))
    ; plots_Wsp_Day_Scatter_All(1)        = gsn_csm_xy(wks_Wsp_Day_Scatter_All, x_data_Day, y_data_Day, Res_Scatter_Day)
    ; add_scale_line(wks_Wsp_Day_Scatter_All, plots_Wsp_Day_Scatter_All(1), Res_Scatter_Day, 5)


  ;===| Step 5.0-Draw the panels |===
    ; pres                                    = True
    ; pres@gsnPanelFigureStrings              = (/"(a)","(b)","(c)","(d)","(e)","(f)","(g)","(h)","(i)","(j)","(k)","(l)"/)
    ; pres@gsnPanelFigureStrings              = (/"a","b","c","d","e","f","g","h","i","j","k","l"/)
    ; pres@gsnPanelFigureStringsJust          = "TopLeft"
    ; pres@gsnPanelFigureStringsPerimOn       = False
    ; ; pres@gsnPanelFigureStringsFontHeightF = 0.008
    ; pres@gsnPanelCenter                     = True
    ; pres@gsnMaximize                        = True

    ; ; ;the lines
    ; ; gsn_panel(wks_Jan_Line,  plots_Jan_Line,  (/5,2/), pres)
    ; ; gsn_panel(wks_July_Line, plots_July_Line, (/5,2/), pres)

    ; ; ;the all scatters
    ; ; gsn_panel(wks_Temp_Scatter_All, plots_Temp_Scatter_All, (/1,2/), pres)
    ; ; gsn_panel(wks_Wsp_Scatter_All, plots_Wsp_Scatter_All, (/1,2/), pres)

    ; ; ;the 5 station scatters
    ; ; gsn_panel(wks_Temp_Scatter,  plots_Temp_Scatter,  (/2,5/), pres)
    ; ; gsn_panel(wks_Wsp_Scatter, plots_Wsp_Scatter, (/2,5/), pres)

    ; ;the lines_Day
    ; gsn_panel(wks_Wsp_Day_Line, plots_Wsp_Day_Line, (/5,2/), pres)
    ; ;the 5 station scatters_Day
    ; gsn_panel(wks_Wsp_Day_Scatter,  plots_Wsp_Day_Scatter,  (/2,5/), pres)
    ; ;the all station scatters_Day
    ; gsn_panel(wks_Wsp_Day_Scatter_All,  plots_Wsp_Day_Scatter_All,  (/1,2/), pres)


  ;===| Step 6.0-Calculate the statistics for: station, month, kind |===
    nStation  = nSites + 1  ; + 1 is the total sites.
    nMonth    = 2           ; 0-January, 1-July
    nKind     = 2           ; 0-temperature, 1-windspeed

    N     = new((/nStation, nKind, nMonth/), integer)  ;--- the number of observation
    R     = new((/nStation, nKind, nMonth/), float)    ;--- the correlation coefficient
    MB    = new((/nStation, nKind, nMonth/), float)    ;--- the mean bias
    MGE   = new((/nStation, nKind, nMonth/), float)    ;--- the mean gross error
    NMB   = new((/nStation, nKind, nMonth/), float)    ;--- the normalised mean bias
    NMGE  = new((/nStation, nKind, nMonth/), float)    ;--- the normalised mean gross error
    FAC2  = new((/nStation, nKind, nMonth/), float)    ;--- A count of the fraction of points within 0.5 and 2 times,  0.5 ≤ Si/Oi ≤ 2.0
    FAC5  = new((/nStation, nKind, nMonth/), float)    ;--- A count of the fraction of points within 0.2 and 5 times,  0.2 ≤ Si/Oi ≤ 5.0
    FAC10 = new((/nStation, nKind, nMonth/), float)    ;--- A count of the fraction of points within 0.1 and 10 times, 0.1 ≤ Si/Oi ≤ 10.0

    do iStation = 0, nSites  ;--- 0-5
      do iKind = 0, 1
        do iMonth = 0, 1
            if (iStation.eq.nSites) then   ;total 5 stations
                delete(tmp_Sim)
                delete(tmp_Obs)
                delete(Frac)
                delete(tmp2_Obs)
                tmp_Sim                        = ndtooned( value_Sim(:, iKind, iMonth, :) ) 
                tmp_Obs                        = ndtooned( value_Obv(:, iKind, iMonth, :) )
            else
                tmp_Sim                        = value_Sim(iStation, iKind, iMonth, :)
                tmp_Obs                        = value_Obv(iStation, iKind, iMonth, :)
            end if

            tmp2_Obs                       = where(tmp_Obs.eq.0., tmp_Obs@_FillValue, tmp_Obs)
            ; tmp_Obs                        = where(tmp_Obs.eq.0., tmp_Obs@_FillValue, tmp_Obs)
            Frac                           = tmp_Sim / tmp2_Obs
            N(iStation,     iKind, iMonth) = num(.not.ismissing(tmp_Obs))
            R(iStation,     iKind, iMonth) = escorc(tmp_Sim, tmp_Obs)
            MB(iStation,    iKind, iMonth) = avg(tmp_Sim-tmp_Obs)
            MGE(iStation,   iKind, iMonth) = avg( abs(tmp_Sim-tmp_Obs) )
            NMB(iStation,   iKind, iMonth) = sum( tmp_Sim- tmp_Obs ) / sum( tmp_Obs )
            NMGE(iStation,  iKind, iMonth) = sum( abs(tmp_Sim-tmp_Obs) ) / sum( tmp_Obs )
            FAC2(iStation,  iKind, iMonth) = tofloat(num((Frac.ge.0.5) .and. (Frac.le.2.0)))  / tofloat(dimsizes(Frac))
            FAC5(iStation,  iKind, iMonth) = tofloat(num((Frac.ge.0.2) .and. (Frac.le.5.0)))  / tofloat(dimsizes(Frac))
            FAC10(iStation, iKind, iMonth) = tofloat(num((Frac.ge.0.1) .and. (Frac.le.10.0))) / tofloat(dimsizes(Frac))
        end do
      end do
    end do

    ; Convert to percentage
    percentage = 100.0
    NMB        = NMB * percentage
    NMGE       = NMGE * percentage
    FAC2       = FAC2 * percentage
    FAC5       = FAC5  * percentage
    FAC10      = FAC10 * percentage

  ;===| Step 6.1 Write the metric to csv |======
    CsvNames =  (/ (/"temperature(January).csv", "temperature(July).csv"/), \
                   (/"windspeed(January).csv",   "windspeed(July).csv"/)  /)
    fmt_str = "%04i, %7.3f, %7.3f, %7.3f, %7.3f, %7.3f, %7.3f, %7.3f, %7.3f"

    do iKind = 0, nKind-1
      do iMonth = 0, nMonth-1
        if (isfile(CsvNames(iKind, iMonth))) then
            system("rm -rf " + CsvNames(iKind, iMonth))
        end if

        write_table(CsvNames(iKind, iMonth), "w", [/N(:, iKind, iMonth), R(:, iKind, iMonth), MB(:, iKind, iMonth), \
                                                    MGE(:, iKind, iMonth), NMB(:, iKind, iMonth), NMGE(:, iKind, iMonth), \
                                                    FAC2(:, iKind, iMonth), FAC5(:, iKind, iMonth), \
                                                    FAC10(:, iKind, iMonth)/], fmt_str)        
      end do
    end do


  ;===| Step 7.0-Calculate the statistics for: station, month, kind _Day |===
    nStation  = nSites + 1  ; + 1 is the total sites.
    nMonth    = 2           ; 0-January, 1-July

    N_Day     = new((/nStation, nMonth/), integer)  ;--- the number of observation
    R_Day     = new((/nStation, nMonth/), float)    ;--- the correlation coefficient
    MB_Day    = new((/nStation, nMonth/), float)    ;--- the mean bias
    MGE_Day   = new((/nStation, nMonth/), float)    ;--- the mean gross error
    NMB_Day   = new((/nStation, nMonth/), float)    ;--- the normalised mean bias
    NMGE_Day  = new((/nStation, nMonth/), float)    ;--- the normalised mean gross error
    FAC2_Day  = new((/nStation, nMonth/), float)    ;--- A count of the fraction of points within 0.5 and 2 times, 0.5 ≤ Si/Oi ≤ 2.0
    FAC5_Day  = new((/nStation, nMonth/), float)    ;--- A count of the fraction of points within 0.2 and 5 times, 0.2 ≤ Si/Oi ≤ 5.0
    FAC10_Day = new((/nStation, nMonth/), float)    ;--- A count of the fraction of points within 0.1 and 10 times, 0.1 ≤ Si/Oi ≤ 10.0

    delete(tmp_Sim)
    delete(tmp_Obs)
    ; delete(tmp2_Obs)
    delete(Frac)
    do iStation = 0, nSites  ;--- 0-5
      do iMonth = 0, 1
          if (iStation.eq.nSites) then   ;total 5 stations
              delete(tmp_Sim)
              delete(tmp_Obs)
              delete(Frac)
              ; delete(tmp2_Obs)
              tmp_Sim                        = ndtooned( Wsp_Day_Sim(:, iMonth, :) ) 
              tmp_Obs                        = ndtooned( Wsp_Day_Obv(:, iMonth, :) )
          else
              tmp_Sim                        = Wsp_Day_Sim(iStation, iMonth, :)
              tmp_Obs                        = Wsp_Day_Obv(iStation, iMonth, :)
          end if

          ; tmp2_Obs                    = where(tmp_Obs.eq.0., tmp_Obs@_FillValue, tmp_Obs)
          ; tmp_Obs                     = where(tmp_Obs.eq.0., tmp_Obs@_FillValue, tmp_Obs)
          Frac                        = tmp_Sim / tmp_Obs
          N_Day(iStation,     iMonth) = num(.not.ismissing(tmp_Obs))
          R_Day(iStation,     iMonth) = escorc(tmp_Sim, tmp_Obs)
          MB_Day(iStation,    iMonth) = avg(tmp_Sim-tmp_Obs)
          MGE_Day(iStation,   iMonth) = avg( abs(tmp_Sim-tmp_Obs) )
          NMB_Day(iStation,   iMonth) = sum( tmp_Sim-tmp_Obs ) / sum( tmp_Obs )
          NMGE_Day(iStation,  iMonth) = sum( abs(tmp_Sim-tmp_Obs) ) / sum( tmp_Obs )
          FAC2_Day(iStation,  iMonth) = tofloat(num((Frac.ge.0.5) .and. (Frac.le.2.0)))  / tofloat(dimsizes(Frac))
          FAC5_Day(iStation,  iMonth) = tofloat(num((Frac.ge.0.2) .and. (Frac.le.5.0)))  / tofloat(dimsizes(Frac))
          FAC10_Day(iStation, iMonth) = tofloat(num((Frac.ge.0.1) .and. (Frac.le.10.0))) / tofloat(dimsizes(Frac))
      end do
    end do

    ; Convert to percentage
    percentage = 100.0
    NMB_Day    = NMB_Day * percentage
    NMGE_Day   = NMGE_Day * percentage
    FAC2_Day   = FAC2_Day * percentage
    FAC5_Day   = FAC5_Day  * percentage
    FAC10_Day  = FAC10_Day * percentage

  ;===| Step 7.1 Write the metric to csv _Day |======
    CsvNames_Day = (/"windspeed(January)_day.csv",   "windspeed(July)_day.csv"/)
    fmt_str = "%04i, %7.3f, %7.3f, %7.3f, %7.3f, %7.3f, %7.3f, %7.3f, %7.3f"

    do iMonth = 0, nMonth-1
      if (isfile(CsvNames_Day(iMonth))) then
          system("rm -rf " + CsvNames_Day(iMonth))
      end if

      write_table(CsvNames_Day(iMonth), "w", [/N_Day(:, iMonth),   R_Day(:, iMonth),    MB_Day(:, iMonth), \
                                               MGE_Day(:, iMonth),  NMB_Day(:, iMonth), NMGE_Day(:, iMonth), \
                                               FAC2_Day(:, iMonth), FAC5_Day(:, iMonth), \
                                               FAC10_Day(:, iMonth)/], fmt_str)        
    end do


  ;===| Step 8.0 Write out monthly wind speed |======
    ; Wsp_Month_Sim = dim_avg_n(Wsp_Day_Sim, 2)
    ; Wsp_Month_Obv = dim_avg_n(Wsp_Day_Obv, 2)

    ; MB_Month      = Wsp_Month_Sim - Wsp_Month_Obv    ;--- the mean bias
    ; NMB_Month     = MB_Month / Wsp_Month_Obv         ;--- the normalised mean bias

    ; CsvNames_Month = (/"windspeed(January)_month.csv",   "windspeed(July)_month.csv"/)
    ; fmt_str = "%7.3f, %7.3f, %7.3f, %7.3f"

    ; do iMonth = 0, nMonth-1
    ;   if (isfile(CsvNames_Month(iMonth))) then
    ;       system("rm -rf " + CsvNames_Month(iMonth))
    ;   end if

    ;   write_table(CsvNames_Month(iMonth), "w", [/Wsp_Month_Sim(:, iMonth),   Wsp_Month_Obv(:, iMonth), \
    ;                                            MB_Month(:, iMonth),  NMB_Month(:, iMonth)/], fmt_str)        
    ; end do

  print("     !!!-------| successful |-----------!!!      ")
end