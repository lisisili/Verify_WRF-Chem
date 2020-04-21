;target:       verify the wrfout about the meteorology: Temperature, wind speed, wind direction.
;created time: 2019/6/10
;changed time: 2020/3/25
;change the output csv files

loadscript("/home/lisi/program/ncl/wrfout/run/plot_resource.ncl")
loadscript("/home/lisi/program/ncl/wrfout/run/get_data.ncl")
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
      _getvar         = asciiread(diri_1+filei_1, -1, "string")  ;-- _getvar(29732)
      getvar          = _getvar(22:)                             ;--- discard the first 22 rows(file description)
      station_ID      = str_get_cols(getvar,  0,  5)             ;-- station ID. May contain a letter in the first position.
      station_name    = str_get_cols(getvar, 13, 42)             ;-- station name
      station_country = str_get_cols(getvar, 43, 46)             ;-- country ID
      station_lat     = str_get_cols(getvar, 57, 63)             ;-- Latitude in thousandths of decimal degrees
      station_lon     = str_get_cols(getvar, 65, 72)             ;-- Longitude in thousandths of decimal degrees
      station_elev    = str_get_cols(getvar, 74, 80)             ;-- Elevation in meters

  ;===| Step 1.2 Converting strings(station_lat, station_lon) to numbers |===
      ;station_lat
      station_lat_num = new(dimsizes(station_lat), float, 1e20)  ;--- missing value is 1e20
      ;station_lon
      station_lon_num = new(dimsizes(station_lon), float, 1e20)
      do i = 0, dimsizes(station_lat)-1   ;station_lat and station_lon have the same size.
          ;;tranlate the latitude string (suffix: '+/-') to numeric value
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
      delete(_getvar)
      _getvar              = systemfunc("ls "+diri_2)
      station_ID_CH        = str_get_cols(_getvar, 0, 5)
      station_ll_CH        = new((/2, dimsizes(station_ID_CH)/), float, 1e20)      ;--- (0,:)-lat, (1,:)-lon for station_ID_CH
      station_Elev_CH      = new(dimsizes(station_ID_CH), string, "no Elevation")  ;--- elevation for station_ID_CH
      station_Name_CH      = new(dimsizes(station_ID_CH), string, "no Name")       ;--- name for station_ID_CH

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

      ; print the warning when the sites data can't match the ID and lon/lat from sites infortmation.
      if (any(ismissing(station_ll_CH))) then
        print("Warning: station_ll_CH value has missing value")
      end if


  ;===| Step 2.0-Select the station to verify |===
      sites_name = (/"Tangshan","Qinglong","Hequ","Changling","Pingliang"/)
      sites_grid = (/(/18,55/),(/21,57/),(/17,44/),(/30,62/),(/9,36/)/)  ;--- from sleect_sites.ncl, except 1th(/21,56/), 4th(/23,49/)
      do i = 0, dimsizes(sites_grid(:,0))-1
        sites_grid(i,0) = sites_grid(i,0) - 1
        sites_grid(i,1) = sites_grid(i,1) + 1
      end do
      sites_grid = sites_grid + 1
      sites_lonlat = Get_LonLat_fromGrid(diri_3+filei_2, sites_grid)
      print(sites_lonlat)
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
          site_ID               = Get_Station_ID(sites_lon(Nber), sites_lat(Nber), station_ll_CH, station_ID_CH, station_Name_CH)  ;Get the station ID among the CHina station.
          print(site_ID)
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
      ; plots: total stations: January[temperature, windspeed]
      ;                        July   [temperature, windspeed]
      ;            5 stations: January[temperature, windspeed]
      ;                        July   [temperature, windspeed]

      type                      = "eps"
      ; type                      = "png"
      
      ;5 stations lines.
      wks_Temp_Line             = gsn_open_wks(type, "Temp_Line")
      wks_Wsp_Line              = gsn_open_wks(type, "Wsp_Line")
      plots_Temp_Line           = new(10, graphic)    ;--- save plots in January
      plots_Wsp_Line            = new(10, graphic)    ;--- save plots in July
      
      ;total station scatters.
      wks_Temp_Scatter_All      = gsn_open_wks(type, "Temp_Scatter_All")
      wks_Wsp_Scatter_All       = gsn_open_wks(type, "Wsp_Scatter_All")
      plots_Temp_Scatter_All    = new(2, graphic)
      plots_Wsp_Scatter_All     = new(2, graphic)
      
      ;5 stations scatters.
      wks_Temp_Scatter          = gsn_open_wks(type, "Temp_Scatter")
      wks_Wsp_Scatter           = gsn_open_wks(type, "Wsp_Scatter")
      plots_Temp_Scatter        = new(10, graphic)
      plots_Wsp_Scatter         = new(10, graphic)
      
      ;daily windspeed
      ;5 station lines.
      wks_Wsp_Day_Line          = gsn_open_wks(type, "Wsp_Day_Line")
      plots_Wsp_Day_Line        = new(10, graphic)
      ;5 stations scatters.
      wks_Wsp_Day_Scatter       = gsn_open_wks(type, "Wsp_Day_Scatter")
      plots_Wsp_Day_Scatter     = new(10, graphic)
      ;total stations scatters.
      wks_Wsp_Day_Scatter_All   = gsn_open_wks(type, "Wsp_Day_Scatter_All")
      plots_Wsp_Day_Scatter_All = new(2, graphic)


      res             = True
      res@gsnDraw     = False
      res@gsnFrame    = False
      res@gsnMaximize = True

  ;===| Step 4.1-Draw the xy-Line plots for 5 stations|===
      Res_Line        = get_res_lines(res)
      do Nber = 0, 4
          Res_Line@gsnCenterString  = sites_name(Nber)
          
          ;temperature in 2016.1
          Res_Line@tiYAxisString    = "Temperature ("+"~S~o~N~"+"C)"
          Res_Line@tmXBLabels       = sprinti("%02i", ispan(2, 31, 2)) + " Jan"
          plots_Temp_Line(Nber*2)    = gsn_csm_xy(wks_Temp_Line, time, (/value_Sim(Nber,0,0,:),  value_Obv(Nber,0,0,:)/), Res_Line)
          
          ;temperature in 2016.7
          Res_Line@tmXBLabels       = sprinti("%02i", ispan(2, 31, 2)) + " July"
          plots_Temp_Line(Nber*2+1)  = gsn_csm_xy(wks_Temp_Line, time, (/value_Sim(Nber,0,1,:),  value_Obv(Nber,0,1,:)/), Res_Line)

          ;wind speed in 2016.1
          Res_Line@tiYAxisString    = "Wind Speed (m/s)"
          Res_Line@tmXBLabels       = sprinti("%02i", ispan(2, 31, 2)) + " Jan"
          plots_Wsp_Line(Nber*2)   = gsn_csm_xy(wks_Wsp_Line, time, (/value_Sim(Nber,1,0,:),  value_Obv(Nber,1,0,:)/), Res_Line)
          
          ;wind speed in 2016.7
          Res_Line@tmXBLabels       = sprinti("%02i", ispan(2, 31, 2)) + " July"
          plots_Wsp_Line(Nber*2+1) = gsn_csm_xy(wks_Wsp_Line, time, (/value_Sim(Nber,1,1,:),  value_Obv(Nber,1,1,:)/), Res_Line)
      end do

  ;===| Step 4.2-Draw the xy-Scatters plots for total station|===
      Res_Scatter_All                 = get_res_scatter(res)
      
      ;temperature
      ;January
      x_data                          = ndtooned(value_Obv(:2,0,0,:))
      y_data                          = ndtooned(value_Sim(:2,0,0,:))
      Res_Scatter_All@gsnCenterString = "Temperature ("+"~S~o~N~"+"C) in January"
      Res_Scatter_All@trXMinF         = -30
      Res_Scatter_All@trXMaxF         =  10
      Res_Scatter_All@trYMinF         = -30
      Res_Scatter_All@trYMaxF         =  10
      plots_Temp_Scatter_All(0)       = gsn_csm_xy(wks_Temp_Scatter_All, x_data, y_data, Res_Scatter_All)
      add_scale_line(wks_Temp_Scatter_All, plots_Temp_Scatter_All(0), Res_Scatter_All, 2)
      ;July
      x_data                          = ndtooned(value_Obv(:2,0,1,:))
      y_data                          = ndtooned(value_Sim(:2,0,1,:))
      Res_Scatter_All@gsnCenterString = "Temperature ("+"~S~o~N~"+"C) in July"
      Res_Scatter_All@trXMinF         =   5
      Res_Scatter_All@trXMaxF         =  40
      Res_Scatter_All@trYMinF         =   5
      Res_Scatter_All@trYMaxF         =  40
      plots_Temp_Scatter_All(1)       = gsn_csm_xy(wks_Temp_Scatter_All, x_data, y_data, Res_Scatter_All)    
      add_scale_line(wks_Temp_Scatter_All, plots_Temp_Scatter_All(1), Res_Scatter_All, 2)
      
      ;windspeed at Jaunary and July
      ;January
      x_data                          = ndtooned(value_Obv(:2,1,0,:))
      y_data                          = ndtooned(value_Sim(:2,1,0,:))
      Res_Scatter_All@gsnCenterString = "Wind Speed (m/s) in January"
      Res_Scatter_All@trXMinF         =   0
      Res_Scatter_All@trXMaxF         =  15
      Res_Scatter_All@trYMinF         =   0
      Res_Scatter_All@trYMaxF         =  15
      plots_Wsp_Scatter_All(0)        = gsn_csm_xy(wks_Wsp_Scatter_All, x_data, y_data, Res_Scatter_All)
      add_scale_line(wks_Wsp_Scatter_All, plots_Wsp_Scatter_All(0), Res_Scatter_All, 5)
      ;July
      Res_Scatter_All@gsnCenterString = "Wind Speed (m/s) in July"
      x_data                          = ndtooned(value_Obv(:2,1,1,:))
      y_data                          = ndtooned(value_Sim(:2,1,1,:))
      plots_Wsp_Scatter_All(1)        = gsn_csm_xy(wks_Wsp_Scatter_All, x_data, y_data, Res_Scatter_All)
      add_scale_line(wks_Wsp_Scatter_All, plots_Wsp_Scatter_All(1), Res_Scatter_All, 5)

  ;===| Step 4.3-Draw the xy-Scatters plots for 5 stations|===
      Res_Scatter = get_res_scatter(res)
      do Nber = 0, 4
          Res_Scatter@gsnCenterString  = sites_name(Nber)
          
          ;temperature in 2016.1
          ; Res_Scatter@tiYAxisString  = "Temperature ("+"~S~o~N~"+"C)"
          plots_Temp_Scatter(Nber)   = gsn_csm_xy(wks_Temp_Scatter, value_Obv(Nber,0,0,:),  value_Sim(Nber,0,0,:), Res_Scatter)
          ;temperature in 2016.7
          plots_Temp_Scatter(Nber+5) = gsn_csm_xy(wks_Temp_Scatter, value_Obv(Nber,0,1,:),  value_Sim(Nber,0,1,:), Res_Scatter)
          
          ;wind speed in 2016.1
          ; Res_Scatter@tiYAxisString  = "Wind Speed (m/s)"
          plots_Wsp_Scatter(Nber)    = gsn_csm_xy(wks_Wsp_Scatter, value_Obv(Nber,1,0,:), value_Sim(Nber,1,0,:), Res_Scatter)
          ;wind speed in 2016.7
          plots_Wsp_Scatter(Nber+5)  = gsn_csm_xy(wks_Wsp_Scatter, value_Obv(Nber,1,1,:), value_Sim(Nber,1,1,:), Res_Scatter)
      end do

  ;===| Step 4.4-Draw the wind speed for Day|===
  ;===| Step 4.4.1-Draw the xy-Line Day plots for 5 stations|===
      time_Day                     = ispan(1, 30, 1)
      Res_Line_Day                 = get_res_lines_Day(get_res_lines(res))
      ; Res_Line_Day@xyMarkLineModes = (/"Lines", "Lines"/) ;--- Sim is lines, Obs is markers
      do Nber = 0, 4
          Res_Line_Day@gsnCenterString = sites_name(Nber)
          
          ;wind speed in 2016.1
          Res_Line_Day@tiYAxisString   = "Wind Speed (m/s)"
          Res_Line_Day@tmXBLabels      = sprinti("%02i", ispan(2, 31, 2)) + " Jan"
          plots_Wsp_Day_Line(Nber*2)     = gsn_csm_xy(wks_Wsp_Day_Line, time_Day, (/Wsp_Day_Sim(Nber,0,:),  Wsp_Day_Obv(Nber,0,:)/), Res_Line_Day)
          
          ;wind speed in 2016.7
          Res_Line_Day@tmXBLabels      = sprinti("%02i", ispan(2, 31, 2)) + " July"
          plots_Wsp_Day_Line(Nber*2+1)   = gsn_csm_xy(wks_Wsp_Day_Line, time_Day, (/Wsp_Day_Sim(Nber,1,:),  Wsp_Day_Obv(Nber,1,:)/), Res_Line_Day)
      end do    

  ;===| Step 4.4.2-Draw the xy-Scatter Day plots for 5 stations|===
      Res_Scatter_Day               = get_res_scatter(res)
      Res_Scatter_Day@xyMarkerSizeF = 0.01               ;--- Marker size (default 0.01)
      Res_Scatter_Day@trXMinF       =   0
      Res_Scatter_Day@trXMaxF       =  10
      Res_Scatter_Day@trYMinF       =   0
      Res_Scatter_Day@trYMaxF       =  10
      do Nber = 0, 4
          Res_Scatter_Day@gsnCenterString  = sites_name(Nber)      
          ;wind speed in 2016.1
          plots_Wsp_Day_Scatter(Nber)     = gsn_csm_xy(wks_Wsp_Day_Scatter, Wsp_Day_Sim(Nber,0,:),  Wsp_Day_Obv(Nber,0,:), Res_Scatter_Day)
          ;wind speed in 2016.7
          plots_Wsp_Day_Scatter(Nber+5)   = gsn_csm_xy(wks_Wsp_Day_Scatter, Wsp_Day_Sim(Nber,1,:),  Wsp_Day_Obv(Nber,1,:), Res_Scatter_Day)
      end do

  ;===| Step 4.4.3-Draw the xy-Scatter Day plots for all stations|===
      ;windspeed at Jaunary and July
      ;January
      Res_Scatter_Day@gsnCenterString = "Wind Speed (m/s) in January"
      Res_Scatter_Day@trXMinF         =   0
      Res_Scatter_Day@trXMaxF         =  15
      Res_Scatter_Day@trYMinF         =   0
      Res_Scatter_Day@trYMaxF         =  15
      x_data_Day                          = ndtooned(Wsp_Day_Obv(:2,0,:))
      y_data_Day                          = ndtooned(Wsp_Day_Sim(:2,0,:))
      plots_Wsp_Day_Scatter_All(0)        = gsn_csm_xy(wks_Wsp_Day_Scatter_All, x_data_Day, y_data_Day, Res_Scatter_Day)
      add_scale_line(wks_Wsp_Day_Scatter_All, plots_Wsp_Day_Scatter_All(0), Res_Scatter_Day, 5)
      ;July
      Res_Scatter_Day@gsnCenterString = "Wind Speed (m/s) in July"
      x_data_Day                          = ndtooned(Wsp_Day_Obv(:2,1,:))
      y_data_Day                          = ndtooned(Wsp_Day_Sim(:2,1,:))
      plots_Wsp_Day_Scatter_All(1)        = gsn_csm_xy(wks_Wsp_Day_Scatter_All, x_data_Day, y_data_Day, Res_Scatter_Day)
      add_scale_line(wks_Wsp_Day_Scatter_All, plots_Wsp_Day_Scatter_All(1), Res_Scatter_Day, 5)


  ;===| Step 5.0-Draw the panels |===
      pres                                    = True
      pres@gsnPanelFigureStrings              = (/"(a)","(b)","(c)","(d)","(e)","(f)","(g)","(h)","(i)","(j)","(k)","(l)"/)
      pres@gsnPanelFigureStrings              = (/"a","b","c","d","e","f","g","h","i","j","k","l"/)
      pres@gsnPanelFigureStringsJust          = "TopLeft"
      pres@gsnPanelFigureStringsPerimOn       = False
      ; pres@gsnPanelFigureStringsFontHeightF = 0.008
      pres@gsnPanelCenter                     = True
      pres@gsnMaximize                        = True

      ;the lines
      gsn_panel(wks_Temp_Line,  plots_Temp_Line,  (/5,2/), pres)
      gsn_panel(wks_Wsp_Line, plots_Wsp_Line, (/5,2/), pres)

      ;the all scatters
      gsn_panel(wks_Temp_Scatter_All, plots_Temp_Scatter_All, (/1,2/), pres)
      gsn_panel(wks_Wsp_Scatter_All, plots_Wsp_Scatter_All, (/1,2/), pres)

      ;the 5 station scatters
      gsn_panel(wks_Temp_Scatter,  plots_Temp_Scatter,  (/2,5/), pres)
      gsn_panel(wks_Wsp_Scatter, plots_Wsp_Scatter, (/2,5/), pres)

      ;the lines_Day
      gsn_panel(wks_Wsp_Day_Line, plots_Wsp_Day_Line, (/5,2/), pres)
      ;the 5 station scatters_Day
      gsn_panel(wks_Wsp_Day_Scatter,  plots_Wsp_Day_Scatter,  (/2,5/), pres)
      ;the all station scatters_Day
      gsn_panel(wks_Wsp_Day_Scatter_All,  plots_Wsp_Day_Scatter_All,  (/1,2/), pres)


  ;===| Step 6.0-Calculate the statistics for: station, month, kind |===
      nStation = nSites + 1  ; + 1 is the total sites.
      nMonth   = 2           ; 0-January, 1-July
      nKind    = 2           ; 0-temperature, 1-windspeed
      
      N        = new((/nStation, nKind, nMonth/), integer)  ;--- the number of observation
      R        = new((/nStation, nKind, nMonth/), float)    ;--- the correlation coefficient
      MB       = new((/nStation, nKind, nMonth/), float)    ;--- the mean bias
      MGE      = new((/nStation, nKind, nMonth/), float)    ;--- the mean gross error
      NMB      = new((/nStation, nKind, nMonth/), float)    ;--- the normalised mean bias
      NMGE     = new((/nStation, nKind, nMonth/), float)    ;--- the normalised mean gross error
      FAC2     = new((/nStation, nKind, nMonth/), float)    ;--- A count of the fraction of points within 0.5 and 2 times,  0.5 ≤ Si/Oi ≤ 2.0
      FAC5     = new((/nStation, nKind, nMonth/), float)    ;--- A count of the fraction of points within 0.2 and 5 times,  0.2 ≤ Si/Oi ≤ 5.0
      FAC10    = new((/nStation, nKind, nMonth/), float)    ;--- A count of the fraction of points within 0.1 and 10 times, 0.1 ≤ Si/Oi ≤ 10.0

      do iStation = 0, nSites  ;--- 0-5
        do iKind = 0, 1
          do iMonth = 0, 1
              if (iStation.eq.nSites) then   ;total 5 stations
                  delete(tmp_Sim)
                  delete(tmp_Obs)
                  delete(Frac)
                  delete(tmp2_Obs)
                  tmp_Sim                        = ndtooned( value_Sim(:2, iKind, iMonth, :) ) 
                  tmp_Obs                        = ndtooned( value_Obv(:2, iKind, iMonth, :) )
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
                tmp_Sim                        = ndtooned( Wsp_Day_Sim(:2, iMonth, :) ) 
                tmp_Obs                        = ndtooned( Wsp_Day_Obv(:2, iMonth, :) )
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

  print("     !!!-------| successful |-----------!!!      ")
end