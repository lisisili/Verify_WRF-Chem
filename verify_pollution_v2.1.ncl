;target:
;       get series time for PM2.5 and O3 validation.
;created time:  2019/6/6
;update:
;       1. plot the panel.
;       2. add the site id to the title.
;       3. Draw the scatters for all sites.(date:2019/7/10)
;       4. change the selected grids.(date:2019/7/14)
;       5. change the verified station.(date:2020/4/21)


load "/home/lisi/program/ncl/mylib/WRFComman.ncl"

begin
    ;===| 1.0 set files name |=====================
        diri_1   = "/home/lisi/wrf/namelist/article/verify/pollution/ori_file/2016.1/"
        diri_2   = "/home/lisi/wrf/namelist/article/verify/pollution/ori_file/2016.7/"
        diri_3   = "/home/lisi/wrf/model_output/data/2016.1_noMOZBC/d01/"
        diri_4   = "/home/lisi/wrf/model_output/data/2016.7/d01/"
        prefix   = "china_sites_"
        suffix   = ".csv"
        filei_1  = new(31, string)
        filei_2  = new(31, string)
        do i = 1, 31
          if (i.lt.10) then
            date_1 = "2016010" + tostring(i)
            date_2 = "2016070" + tostring(i)
          else
            date_1 = "201601"  + tostring(i)
            date_2 = "201607"  + tostring(i)
          end if
          filei_1(i-1) = prefix + date_1 + suffix
          filei_2(i-1) = prefix + date_2 + suffix
        end do
        filei_3  = "sites.csv"
        filei_4  = "wrfout_d01_2016.1_control"
        filei_5  = "wrfout_d01_2016.7_control"
        delim    = ","

    ;===| 1.1 read the PM2.5 and O3 data both in 2016.1 and 2016.7  |=====================
        Obse = new((/2,2,31,24,1497/), float)
                    ; !0[2]    : [0] is 2016.1, [1] is 2016.7
                    ; !1[2]    : [0] is PM2.5,  [1] is  O3
                    ; !2[31]   : the days(31)
                    ; !3[24]   : the hours
                    ; !4[1497] : the sites number.

        do i = 0, 30
            ;2016.1
            getdata_1 := asciiread(diri_1+filei_1(i), -1, "string")
            nRow       = dimsizes(getdata_1)
            nColumn    = str_fields_count(getdata_1(0), delim)
            do j = 0, nRow-1
                name = str_get_field(getdata_1(j), 3, delim)   ; the 3th column is the varname.
                if (name .eq. "PM2.5") then
                  tmp                = ndtooned( str_split_csv(getdata_1(j), delim, 0) )
                  hour               = tointeger(tmp(1))
                  Obse(0,0,i,hour,:) = tofloat(tmp(3:))
                end if
                if (name .eq. "O3") then
                  tmp                = ndtooned( str_split_csv(getdata_1(j), delim, 0) )
                  hour               = tointeger(tmp(1))
                  Obse(0,1,i,hour,:) = tofloat(tmp(3:))
                end if
            end do

            ; 2016.7
            getdata_2 := asciiread(diri_2+filei_2(i), -1, "string")
            nRow       = dimsizes(getdata_2)
            nColumn    = str_fields_count(getdata_2(0), delim)
            do j = 0, nRow-1
                name = str_get_field(getdata_2(j), 3, delim)   ; the 3th column is the varname.
                if (name .eq. "PM2.5") then
                  tmp                = ndtooned( str_split_csv(getdata_2(j), delim, 0) )
                  hour               = tointeger(tmp(1))
                  Obse(1,0,i,hour,:) = tofloat(tmp(3:))
                end if
                if (name .eq. "O3") then
                  tmp                = ndtooned( str_split_csv(getdata_2(j), delim, 0) )
                  hour               = tointeger(tmp(1))
                  Obse(1,1,i,hour,:) = tofloat(tmp(3:))
                end if
            end do
        end do

    ;===| 1.2 read the sites information: number(id_1, id_2), longititude, latitude |=====================
        getdata_1 := asciiread(diri_1+filei_1(0), -1, "string")
        tmp       := ndtooned(str_split_csv(getdata_1(0), delim, 0))
        id_1       = tmp(3:)

        getdata_1 := asciiread(diri_1+filei_3, -1, "string")
        tmp       := str_split_csv(getdata_1, delim, 0)
        tmp       := tmp(1:,:)  ;discard the 1th row.
        id_2       = tmp(:,0)
        longs      = tofloat( tmp(:,3) )
        lats       = tofloat( tmp(:,4) )

    ;===| 1.3 find out the longititude and latitude of id_1, the longititude and latitude is saved in id_2 |=====================
        nSite     = dimsizes(id_1)
        location  = new((/2,nSite/), float) ;location(0,:) is longititude, location(1,:) is latitude.
        do i = 0, nSite-1
            exist = False
            do j = 0, dimsizes(id_2)-1
                if ( id_1(i).eq.id_2(j) ) then
                  exist         = True
                  location(0,i) = longs(j)
                  location(1,i) = lats(j)
                  break
                end if
            end do
            if (.not.exist) then
              print("the sites "+id_1(i)+" don't have longititude and latitude!")
            end if
        end do

    ;===| Step 1.4 Read the data from wrfout |======
        fin_1                  = addfile(diri_3+filei_4, "r")
        fin_2                  = addfile(diri_4+filei_5, "r")
        nTimes                 = dimsizes(wrf_user_getvar(fin_1, "times", -1))
        start_time             = 19          ;UTC 2016/01/01-19:00:00 --> LT 2016/01/02-03:00:00
        end_time               = nTimes-1-3  ;UTC 2016/01/31-15:00:00 --> LT 2016/01/31-23:00:00
        level                  = 0

        pm25_sm_1              = fin_1->PM2_5_DRY(start_time:end_time,level,:,:)
        pm25_sm_7              = fin_2->PM2_5_DRY(start_time:end_time,level,:,:)
        O3_sm_1                = fin_1->o3(start_time:end_time,level,:,:)
        O3_sm_7                = fin_2->o3(start_time:end_time,level,:,:)
        xlons                  = fin_1->XLONG(1,:,:)
        xlats                  = fin_1->XLAT(1,:,:)
        nEW                    = dimsizes(xlons(0,:))
        nNS                    = dimsizes(xlons(:,0))

    ;===| Step 2.0 Set the verifiy sites information |======
        sites_name   = (/"Tangshan","Qinglong","Hequ","Changling","Pingliang"/)
        sites_grid   = (/(/18,55/),(/21,57/),(/17,44/),(/30,62/),(/9,36/)/)
        
        Data         = new((/5,2,2,2,717/), float)  ;--- data for scatters plots.; 
                        ; !0[5]   : 5 sites
                        ; !1[2]   : [0] in 2016.1,  [1] in 2016.7
                        ; !2[2]   : [0] PM2.5,      [1] O3
                        ; !3[2]   : [0] simulation, [1] is observation
                        ; !4[717] : hours:2016/01/01-19:00:00 ==>2016/01/31-15:00:00 [UTC]

        sites_id     = new(dimsizes(sites_name), string)
        sites_latlon = new((/dimsizes(sites_name),2/), float)

        do site = 0, dimsizes(sites_name)-1
          ;===| Step 2.1 find out the grid of wrfout |======
            south_north = sites_grid(site,0)
            west_east   = sites_grid(site,1)
            ;--- Month:January(M=0), July(M=1);  Kind:PM2.5(K=0), O3(K=1);  Tool: simulation(T=0), observed(T=1)
            
            T = 0                           ;---   [simulation]
              M = 0                         ;---   [January]
                K = 0                       ;---   [PM2.5]
                Data(site, M, K, T, :)    = (/pm25_sm_1(:,south_north,west_east)/)        
                K = 1                       ;---   [O3]
                Data(site, M, K, T, :)    = (/O3_sm_1(:,south_north,west_east)*1000.0/)  ;--- (unit:ppmv)-->(unit:ppbv)
              M = 1                         ;---   [July]
                K = 0                       ;---   [PM2.5]
                Data(site, M, K, T, :)    = (/pm25_sm_7(:,south_north,west_east)/)        
                K = 1                       ;---   [O3]
                Data(site, M, K, T, :)    = (/O3_sm_7(:,south_north,west_east)*1000.0/)  ;--- (unit:ppmv)-->(unit:ppbv)

          ;===| Step 2.2 find out the site of china_sites |======
            interval              := ( location(0,:) - xlons(south_north,west_east) )^2 + ( location(1,:) - xlats(south_north,west_east) )^2
            a1D                   := ndtooned(interval)
            dsizes_a              := dimsizes(interval)
            inds_2                := ind_resolve(minind(a1D),dsizes_a)

            sites_id(site)         = id_2(inds_2(0,0))
            sites_latlon(site,:)   = location(:,inds_2(0,0))
          
          ;===| Step 2.3 Get Data |======
            T = 1                           ;---   [observed]
              M = 0                         ;---   [January]
                K = 0                       ;---   [PM2.5]
                tmp                      := ndtooned( Obse(M,K,:,:,inds_2(0,0)) )
                Data(site, M, K, T, :)    = (/tmp(27:)/)
                K = 1                       ;---   [O3]
                tmp                      := ndtooned( Obse(M,K,:,:,inds_2(0,0)) )
                Data(site, M, K, T, :)    = (/tmp(27:)*22.4/48.0/)                 ;--- (unit:ug/m3)-->(unit:ppbv)
              M = 1                         ;---   [July]
                K = 0                       ;---   [PM2.5]
                tmp                      := ndtooned( Obse(M,K,:,:,inds_2(0,0)) )
                Data(site, M, K, T, :)    = (/tmp(27:)/)
                K = 1                       ;---   [O3]
                tmp                      := ndtooned( Obse(M,K,:,:,inds_2(0,0)) )
                Data(site, M, K, T, :)    = (/tmp(27:)*22.4/48.0/)                 ;--- (unit:ug/m3)-->(unit:ppbv)
        end do

    ;===| Step 3.0 Calculate evaluation metric |======
        nn    = 6
        N     = new((/nn,2/), integer)  ;--- the number
        R     = new((/nn,2/), float)  ;--- the correlation coefficient
        MB    = new((/nn,2/), float)  ;--- the mean bias
        MGE   = new((/nn,2/), float)  ;--- the mean gross error
        NMB   = new((/nn,2/), float)  ;--- the normalised mean bias
        NMGE  = new((/nn,2/), float)  ;--- the normalised mean gross error
        FAC2  = new((/nn,2/), float)  ;--- A count of the fraction of points within 0.5 and 2 times, 0.5 ≤ Si/Oi ≤ 2.0
        FAC5  = new((/nn,2/), float)  ;--- A count of the fraction of points within 0.2 and 5 times, 0.2 ≤ Si/Oi ≤ 5.0
        FAC10 = new((/nn,2/), float)  ;--- A count of the fraction of points within 0.1 and 10 times, 0.1 ≤ Si/Oi ≤ 10.0

        do site = 0, dimsizes(sites_name)-1  ;--- 0-5
          do month = 0, 1
            tmp_Sim            = Data(site,month,0,0,:)
            tmp_Obs            = Data(site,month,0,1,:)
            Frac               = tmp_Sim / tmp_Obs
            
            N(site, month)     = num(.not.ismissing(tmp_Obs))
            R(site, month)     = escorc(tmp_Sim, tmp_Obs)
            MB(site, month)    = avg(tmp_Sim-tmp_Obs)
            MGE(site, month)   = avg( abs(tmp_Sim-tmp_Obs) )
            NMB(site, month)   = sum( tmp_Sim-tmp_Obs ) / sum( tmp_Obs )
            NMGE(site, month)  = sum( abs(tmp_Sim-tmp_Obs) ) / sum( tmp_Obs )
            FAC2(site, month)  = tofloat(num((Frac.ge.0.5) .and. (Frac.le.2.0))) / tofloat(dimsizes(Frac))
            FAC5(site, month)  = tofloat(num((Frac.ge.0.2) .and. (Frac.le.5.0))) / tofloat(dimsizes(Frac))
            FAC10(site, month) = tofloat(num((Frac.ge.0.1) .and. (Frac.le.10.0))) / tofloat(dimsizes(Frac))
          end do
        end do

        do month = 0, 1 ;--- 6
          ; tmp_Sim           := ndtooned(Data(:,month,0,0,:)) 
          tmp_Sim           := ndtooned(Data(:2,month,0,0,:)) 
          ; tmp_Obs           := ndtooned(Data(:,month,0,1,:)) 
          tmp_Obs           := ndtooned(Data(:2,month,0,1,:)) 
          Frac              := tmp_Sim / tmp_Obs

          N(5, month)     = num(.not.ismissing(tmp_Obs))
          R(5, month)     = escorc(tmp_Sim, tmp_Obs)
          MB(5, month)    = avg(tmp_Sim-tmp_Obs)
          MGE(5, month)   = avg( abs(tmp_Sim-tmp_Obs) )
          NMB(5, month)   = sum( tmp_Sim-tmp_Obs ) / sum( tmp_Obs )
          NMGE(5, month)  = sum( abs(tmp_Sim-tmp_Obs) ) / sum( tmp_Obs )
          FAC2(5, month)  = tofloat(num((Frac.ge.0.5) .and. (Frac.le.2.0))) / tofloat(dimsizes(Frac))
          FAC5(5, month)  = tofloat(num((Frac.ge.0.2) .and. (Frac.le.5.0))) / tofloat(dimsizes(Frac))
          FAC10(5, month) = tofloat(num((Frac.ge.0.1) .and. (Frac.le.10.0))) / tofloat(dimsizes(Frac))
        end do

        ; Convert to percentage
        percentage = 100.0
        NMB        = NMB * percentage
        NMGE       = NMGE * percentage
        FAC2       = FAC2 * percentage
        FAC5       = FAC5 * percentage
        FAC10      = FAC10 * percentage

    ;===| Step 3.1 Write the metric to csv |======
        CsvName = "metric1_4.csv"
        system("rm -rf "+CsvName)

        if (isfile(CsvName)) then
            system("rm -rf " + CsvName)
        end if

        fmt_str = "%05i, %7.3f, %7.3f, %7.3f, %7.3f, %7.3f, %7.3f, %7.3f, %7.3f"
        write_table(CsvName, "w", [/"January"/], "%s")
        write_table(CsvName, "a", [/N(:,0), R(:,0), MB(:,0), MGE(:,0), NMB(:,0), NMGE(:,0), FAC2(:,0), FAC5(:,0), FAC10(:,0)/], fmt_str)
        write_table(CsvName, "a", [/"July"/], "%s")
        write_table(CsvName, "a", [/N(:,1), R(:,1), MB(:,1), MGE(:,1), NMB(:,1), NMGE(:,1), FAC2(:,1), FAC5(:,1), FAC10(:,1)/], fmt_str)
        write_table(CsvName, "a", [/"LatLon"/], "%s")
        write_table(CsvName, "a", [/sites_latlon(:,0), sites_latlon(:,1)/], "%7.3f, %7.3f")

    ;===| Step 4.0 Set plot resource |======
        res                                   = True
        res@gsnDraw                           = False
        res@gsnFrame                          = False
        res@gsnMaximize                       = True
        ;Set top X-Axis
        res@tmXTOn                            = False
        ;Set Right Y-Axis
        res@tmYROn                            = False
        
        ;--- resource of Scatters
        res_sca                               = res
        res_sca@xyMarkLineMode                = "Markers"
        res_sca@xyMarkers                     = 6                ;--- choose type of marker  
        res_sca@xyMarkerColor                 = "steelblue3"            ;--- Marker color
        res_sca@xyMarkerSizeF                 = 0.008               ;--- Marker size (default 0.01)
        ; res_sca@gsnCenterStringFontHeightF    = 0.025              ;--- the font size of gsnCenterString
        res_sca@tiXAxisString                 = "Observation"
        res_sca@tiYAxisString                 = "Simulation"
        ; res_sca@tiXAxisOffsetYF               = 0.1

        ;--- resource of Polyline
        res_pl                                = res
        res_pl@xyMarkLineMode                 = "Lines"
        res_pl@xyDashPattern                  = 0                  ;--- solid line
        res_pl@xyLineColor                    = "red"
        res_pl@xyLineThicknessF               = 3.0

        Name  = ReNameUnit("PM2_5_DRY")
        Unit  = Name@units

        ;--- resource of lines.
        res_lines = res
        res_lines@tiXAxisString               = "Date (UTC)"
        ; res_lines@tiYAxisString               = "PM~B~2.5~N~"+"(ug/m~S~3~N~)"    
        res_lines@tiYAxisString               = Name + "("+Unit+")"   
        res_lines@tiXAxisFontHeightF          = 0.015              ;-- default is 0.025
        res_lines@tiYAxisFontHeightF          = 0.015              ;-- default is 0.025
        res_lines@xyMarkers                   = 1                                    ; choose type of marker  
        res_lines@xyMarkerColor               = "black"                              ; Marker color
        res_lines@xyMarkerSizeF               = 0.02                                 ; Marker size (default 0.01)  
        res_lines@xyExplicitLegendLabels      = (/"Sim","Obs"/)
        res_lines@xyDashPatterns              = (/0,0/)                              ; solid line,
        res_lines@xyLineThicknessF            = 1.4
        res_lines@xyLineColors                = (/"sienna2","steelblue3"/)
        res_lines@trXMaxF                     = 717.0
        ;Set the bottom X-axis
        res_lines@tmXBMode                    = "Explicit"
        res_lines@tmXBValues                  = ispan(8, 717, 48)
        res_lines@tmXBLabels                  = sprinti("%02i", ispan(2, 31, 2)) + " Jan"
        res_lines@tmXBLabelAngleF             = 50.0
        res_lines@tmXBLabelJust               = "CenterRight"
        res_lines@tmXBLabelFontHeightF        = 0.012          ; size of XB label
        res_lines@tmXBLabelDeltaF             = -0.6           ; look for P99 in NCL chengdong
        res_lines@tmXBMinorOn                 = False
        ;Set the top X-axis
        res_lines@tmXTOn                      = False
        ;Set the left Y-axis
        res_lines@tmYLLabelFontHeightF        = 0.015          ; size of YL label
        res_lines@tmYLLabelDeltaF             = -0.6           ; look for P99 in NCL chengdong
        ;Set the right Y-axis
        res_lines@tmYROn                      = False          ;--- close the XT elements(major and minor tickmark, label)
        res_lines@vpWidthF                    = 1.0
        res_lines@vpHeightF                   = 0.3
        res_lines@pmLegendDisplayMode         = "Always"       ;-- display legend
        res_lines@pmLegendWidthF              = 0.12           ;-- define legend width
        res_lines@pmLegendHeightF             = 0.05           ;-- define legend height
        res_lines@pmLegendOrthogonalPosF      = -1.3           ;-- move legend upward
        res_lines@pmLegendParallelPosF        = 0.52           ;-- move legend right

        plots_total          = new(2, graphic)  ;total sites scatters
        plots_sites_lines    = new((/5,2/), graphic)
        plots_sites_scatters = new((/5,2/), graphic)
        type                 = "png"
        type                 = "eps"
        wks                  = gsn_open_wks(type, "AllScatters_Fig")
        wks_lines            = gsn_open_wks(type, "SitesLines_Fig")
        wks_scatters         = gsn_open_wks(type, "SitesScatters_Fig")
      
    ;===| Step 4.1 Dram the xy scatters plots |======
        res_sca_all                           = res_sca
        max_1                                 = 300.
        max_2                                 = 300.
        res_sca_all@trXMinF                   = 0.
        res_sca_all@trXMaxF                   = max_1
        res_sca_all@trYMaxF                   = res_sca_all@trXMaxF    
        ; res_sca_all@gsnCenterString           = "PM~B~2.5~N~"+"(ug/m~S~3~N~) in January"
        res_sca_all@xyMarkerSizeF             = 0.004               ;--- Marker size (default 0.01)
        ; data_x_1                              = ndtooned(Data(:,0,0,1,:))
        data_x_1                              = ndtooned(Data(:2,0,0,1,:))
        ; data_y_1                              = ndtooned(Data(:,0,0,0,:))
        data_y_1                              = ndtooned(Data(:2,0,0,0,:))
        plots_total(0)                        = gsn_csm_xy(wks, data_x_1, data_y_1, res_sca_all)
     
        res_sca_all@trXMaxF                   = max_2
        res_sca_all@trYMaxF                   = res_sca_all@trXMaxF     
        ; res_sca_all@gsnCenterString           = "PM~B~2.5~N~"+"(ug/m~S~3~N~) in July"
        ; data_x_2                              = ndtooned(Data(:,1,0,1,:))
        data_x_2                              = ndtooned(Data(:2,1,0,1,:))
        ; data_y_2                              = ndtooned(Data(:,1,0,0,:))
        data_y_2                              = ndtooned(Data(:2,1,0,0,:))
        plots_total(1)                        = gsn_csm_xy(wks, data_x_2, data_y_2, res_sca_all)

        time                                 := ispan(1, 717, 1)
        do site = 0, 4
          do month = 0, 1  ;--- 0 is January, 1 is July
            res_lines@gsnCenterString        = sites_name(site)+"("+"~Z80~"+sites_id(site)+"~N~"+")"    ;-- example: Beijing station(1005A)
            ; if (month.eq.0) then
            ;   res_sca@gsnCenterString          = "PM~B~2.5~N~"+"(ug/m~S~3~N~) at " +\
            ;                                      sites_name(site)+" station("+"~Z80~"+sites_id(site)+"~N~"+") in January"
            ; else
            ;   res_sca@gsnCenterString          = "PM~B~2.5~N~"+"(ug/m~S~3~N~) at " +\
            ;                                      sites_name(site)+" station("+"~Z80~"+sites_id(site)+"~N~"+") in July"
            ; end if

            if (month.eq.0) then
                res_lines@tmXBLabels                  = sprinti("%02i", ispan(2, 31, 2)) + " Jan"
            else
                res_lines@tmXBLabels                  = sprinti("%02i", ispan(2, 31, 2)) + " July"
            end if


            plots_sites_lines(site,month)    = gsn_csm_xy(wks_lines, time, Data(site,month,0,:,:), res_lines)
            res_sca@vpHeightF = 0.5  ;--default 0.6
            res_sca@tiXAxisOffsetYF               = 0.006
            plots_sites_scatters(site,month) = gsn_csm_xy(wks_scatters, Data(site,month,0,1,:), Data(site,month,0,0,:), res_sca)
            ; str = unique_string("txt")
            ; res_tmp = True
            ; res_tmp@txFontColor = "red"
            ; res_tmp@txFontHeightF = 0.02
            ; plots_sites_lines@$str$ = gsn_add_text(wks_lines, plots_sites_lines(site,month), "R="+tostring(R(site,month)), 600.0, 0.94*max(Data(site,month,0,:,:)), res_tmp)
          end do
        end do
      
    ;===| Step 4.2 Dram the correlation line and correlation coefficient |======
    ;===| Step 4.2.1 Dram the correlation line |======
        ; rc_1                                  = regline(data_x_1, data_y_1)
        ; rc_2                                  = regline(data_x_2, data_y_2)
        ; x_min                                 = min(data_x_1)
        ; x_max                                 = max(data_x_1)
        ; x_1                                   = (/x_min, x_max/)
        ; y_1                                   = rc_1*(x_1-rc_1@xave) + rc_1@yave
        
        ; x_min                                 = min(data_x_2)
        ; x_max                                 = max(data_x_2)
        ; x_2                                   = (/x_min, x_max/)
        ; y_2                                   = rc_2*(x_2-rc_2@xave) + rc_2@yave
        
        ; plot_over_1                           = gsn_csm_xy(wks, x_1, y_1, res_pl)
        ; plot_over_2                           = gsn_csm_xy(wks, x_2, y_2, res_pl)
        
        ; overlay(plots_total(0), plot_over_1)
        ; overlay(plots_total(1), plot_over_2)
      
    ;===| Step 4.2.2 Add the correlation coefficient text |======
        ; txres_1                                 = True
        ; txres_1@txFontColor                     = "red"
        ; txres_1@txFontHeightF                   = 0.025    ;--- default is 0.05
        
        ; x_add                                 = avg(x_1)
        ; y_add                                 = max(data_y_1)
        ; str                                   = "R = "+sprintf("%4.2f", R(5,0))
        ; add_R1                                = gsn_add_text(wks, plots_total(0), str, x_add, y_add, txres_1)

        ; x_add                                 = avg(x_2)
        ; y_add                                 = max(data_y_2)      
        ; str                                   = "R = "+sprintf("%4.2f", R(5,1))
        ; add_R2                                = gsn_add_text(wks, plots_total(1), str, x_add, y_add, txres_1)

    ;===| Step 4.3 Dram the needed lines and text explation|======
    ;===| Step 4.3.1 Dram the needed lines |======
        Add_plot_1              = new(3, graphic)
        Add_plot_2              = new(3, graphic)
        rate = 5.0

        res_pl@xyDashPattern    = 0
        res_pl@xyLineColor      = "black"
        res_pl@xyLineThicknessF = 1.0

        data_add_x              = (/0.,max_1/)
        data_add_y              = data_add_x
        Add_plot_1(0)           = gsn_csm_xy(wks, data_add_x, data_add_y, res_pl)
        
        data_add_y              = 1./rate*data_add_x
        Add_plot_1(1)           = gsn_csm_xy(wks, data_add_x, data_add_y, res_pl)
        
        data_add_y              = rate*data_add_x
        Add_plot_1(2)           = gsn_csm_xy(wks, data_add_x, data_add_y, res_pl)

        data_add_x              = (/0.,max_2/)
        data_add_y              = data_add_x
        Add_plot_2(0)           = gsn_csm_xy(wks, data_add_x, data_add_y, res_pl)
        
        data_add_y              = 1./rate*data_add_x
        Add_plot_2(1)           = gsn_csm_xy(wks, data_add_x, data_add_y, res_pl)
        
        data_add_y              = rate*data_add_x
        Add_plot_2(2)           = gsn_csm_xy(wks, data_add_x, data_add_y, res_pl)

        overlay(plots_total(0), Add_plot_1(0))
        overlay(plots_total(0), Add_plot_1(1))
        overlay(plots_total(0), Add_plot_1(2))
        overlay(plots_total(1), Add_plot_2(0))
        overlay(plots_total(1), Add_plot_2(1))
        overlay(plots_total(1), Add_plot_2(2))

    ;===| Step 4.3.2 Dram the text explation |======
        txres_2               = True
        txres_2@txFontColor   = "black"
        txres_2@txFontHeightF = 0.02    ;--- default is 0.05
        txres_2@txJust        = "TopLeft"
        
        ;--- for plots_total(0)
        str_tmp               = unique_string("str_tmp")
        Add_plot_1@$str_tmp$  = gsn_add_text(wks, plots_total(0), sprintf("%3.1f", 1./rate)+":1 line", 0.8*max_1, 0.75*(1./rate)*max_1, txres_2)
        str_tmp               = unique_string("str_tmp")
        Add_plot_1@$str_tmp$  = gsn_add_text(wks, plots_total(0), "1:1 line", 0.8*max_1, 0.8*max_1, txres_2)
        str_tmp               = unique_string("str_tmp")
        Add_plot_1@$str_tmp$  = gsn_add_text(wks, plots_total(0), sprinti("%0.1i", tointeger(rate))+":1 line", 0.92*max_1/rate, 0.9*max_1, txres_2)
        
        ;--- for plots_total(1)
        str_tmp               = unique_string("str_tmp")
        Add_plot_2@$str_tmp$  = gsn_add_text(wks, plots_total(1), sprintf("%3.1f", 1./rate)+":1 line", 0.8*max_2, 0.75*(1./rate)*max_2, txres_2)
        str_tmp               = unique_string("str_tmp")
        Add_plot_2@$str_tmp$  = gsn_add_text(wks, plots_total(1), "1:1 line", 0.8*max_2, 0.8*max_2, txres_2)
        str_tmp               = unique_string("str_tmp")
        Add_plot_2@$str_tmp$  = gsn_add_text(wks, plots_total(1), sprinti("%0.1i", tointeger(rate))+":1 line", 0.92*max_2/rate, 0.9*max_2, txres_2)


    ;===| Step 5.0 Final darw the plots in panels |=========
        pres                                    = True
        pres@gsnMaximize                        = True
        pres@gsnFrame                           = False
        pres@gsnPanelSave                       = True
        ; pres@gsnPanelFigureStrings              = (/"(a)","(b)","(c)","(d)","(e)","(f)","(g)","(h)","(i)","(j)","(k)","(l)"/)
        ; pres@gsnPanelFigureStringsJust          = "TopLeft"
        ; pres@gsnPanelFigureStringsFontHeightF = 0.008
        pres@gsnPanelCenter                     = True
        pres@gsnPanelRight                      = 0.99

        plots_sites_lines_1D = ndtooned(plots_sites_lines)
        plots_sites_scatters_1D = ndtooned(plots_sites_scatters)
        gsn_panel(wks, plots_total, (/1,2/), pres)
        gsn_panel(wks_lines, plots_sites_lines_1D, (/5,2/), pres)
        gsn_panel(wks_scatters, plots_sites_scatters_1D, (/2,5/), pres)


        txres               = True
        Number    = (/"a","b", "c","d", "e","f","g","h","i","j"/)
        
        ;for wks
        txres@txFontHeightF = 0.024
        do i = 0, dimsizes(plots_total)-1
            NDC_Pos = Get_NDC_Plot(plots_total(i), -0.09, 0.07)
            gsn_text_ndc(wks, "~F25~"+Number(i), NDC_Pos(0), NDC_Pos(1), txres)
        end do
        frame(wks)

        ;for wks_lines
        ; txres@txFontHeightF = 0.02
        ; do i = 0, dimsizes(plots_sites_lines_1D)-1
        ;     NDC_Pos = Get_NDC_Plot(plots_sites_lines_1D(i), -0.09, 0.07)
        ;     gsn_text_ndc(wks_lines, "~F25~"+Number(i), NDC_Pos(0), NDC_Pos(1), txres)
        ; end do
        frame(wks_lines)

        ;for wks_scatters
        txres@txFontHeightF = 0.02
        do i = 0, dimsizes(plots_sites_scatters_1D)-1
            NDC_Pos = Get_NDC_Plot(plots_sites_scatters_1D(i), -0.09, 0.08)
            gsn_text_ndc(wks_scatters, "~F25~"+Number(i), NDC_Pos(0), NDC_Pos(1), txres)
        end do
        frame(wks_scatters)
      
    print("|--- successful ---|")
end