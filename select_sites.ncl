;---------------------------------------------------------------------
;target:
;       Get right sites (good R) to verify.
;---------------------------------------------------------------------
;time:  2019/7/13
;---------------------------------------------------------------------
;update:
;       1. plot the panel.
;       2. add the site id to the title.
;       3. Draw the scatters for all sites.(date:2019/7/10)
;---------------------------------------------------------------------

undef("add_latlon_lines")
procedure add_latlon_lines(wks, plot:graphic, xlats[*][*]:numeric, xlons[*][*]:numeric)
local nlat, nlon, res_ln, lat_str, lon_str, lon_tx, lat_tx, i
begin
  nlat                     = dimsizes(xlats(:,0))
  nlon                     = dimsizes(xlats(0,:))
  
  res_ln                   = True
  res_ln@gsLineColor       = "skyblue1"
  res_ln@gsLineDashPattern = 0
  res_ln@gsLineOpacityF    = 0.8
  
  res_tx                   = True
  res_tx@txFontHeightF     = 0.01  ;---default 0.05
  res_tx@txFontColor       = "black"
  
  ; lat_str                  = unique_string("lat") + ispan(0,nlat-1,1)
  ; lon_str                  = unique_string("lon") + ispan(0,nlon-1,1)

  ;--- Add the polylines
  do i = 0, nlat-1
    if ((i+1)%10.eq.0) then
      res_ln@gsLineColor = "violet"
    else
      res_ln@gsLineColor = "skyblue1"
    end if
    lat_str = unique_string("lat")
    plot@$lat_str$ = gsn_add_polyline(wks, plot, xlons(i,:), xlats(i,:), res_ln)
  end do

  do i = 0, nlon-1
    if ((i+1)%10.eq.0) then
      res_ln@gsLineColor = "violet"
    else
      res_ln@gsLineColor = "skyblue1"
    end if
    lon_str = unique_string("lon")
    plot@$lon_str$ = gsn_add_polyline(wks, plot, xlons(:,i), xlats(:,i), res_ln)
  end do

  ;--- Add the txt.
  do i = 0, nlat-1
    if ((i+1)%10.eq.0) then
      lat_tx        = unique_string("lat_txt")
      plot@$lat_tx$ = gsn_add_text(wks, plot, i+1, xlons(i,1), xlats(i,1), res_tx)
    end if
  end do

  do i = 0, nlon-1
    if ((i+1)%10.eq.0) then
      lon_tx        = unique_string("lon_txt")
      plot@$lon_tx$ = gsn_add_text(wks, plot, i+1, xlons(1,i), xlats(1,i), res_tx)
    end if
  end do

end

;----------------------------------------------------------------------
; Main code
;----------------------------------------------------------------------
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
    nWE                    = dimsizes(xlons(0,:))
    nNS                    = dimsizes(xlons(:,0))

  ;===| Step 2.0 Get the data: simulation and obesrvation |======
    Data_PM25              = new((/nNS,nWE,2,2,717/), float, -999.9)  ;--- data for scatters plots.; 
                                ; !0[nNS] : north_south
                                ; !1[nWE] : west_east
                                ; !2[2]   : [0] in 2016.1,  [1] in 2016.7
                                ; !3[2]   : [0] simulation, [1] is observation
                                ; !4[717] : hours:2016/01/01-19:00:00==>2016/01/31-15:00:00 [UTC]

    distance = new((/nNS,nWE/), float, -999.9)
    lonslats = new((/2,nNS,nWE/), float, -999.9)

    do NS = 0, nNS-1
      do WE = 0, nWE-1
        ;January, simulation
        Data_PM25(NS,WE,0,0,:)     = (/pm25_sm_1(:,NS,WE)/)
        ;July,    simulation 
        Data_PM25(NS,WE,1,0,:)     = (/pm25_sm_7(:,NS,WE)/)

        interval                  := ( location(0,:) - xlons(NS,WE) )^2 + ( location(1,:) - xlats(NS,WE) )^2
        a1D                       := ndtooned(interval)
        dsizes_a                  := dimsizes(interval)
        inds_2                    := ind_resolve(minind(a1D),dsizes_a)
        distance(NS,WE)            = interval(inds_2(0,0))
        if (distance(NS,WE).gt.10.0) then
          Data_PM25(NS,WE,:,1,:)     = -999.9       
        else
          ;January, Observed
          tmp                       := ndtooned( Obse(0,0,:,:,inds_2(0,0)) )
          Data_PM25(NS,WE,0,1,:)     = (/tmp(27:)/)        
          ;July,    Observed
          tmp                       := ndtooned( Obse(1,0,:,:,inds_2(0,0)) )
          Data_PM25(NS,WE,1,1,:)     = (/tmp(27:)/)
        end if
      end do
    end do


  ;===| Step 2.1 Calculate the R between simulation and obesrvation |======
    R = escorc(Data_PM25(:,:,:,0,:), Data_PM25(:,:,:,1,:))


  ;===| Step 3.0 Draw the R over map |======
    res                            = True
    res@gsnFrame                   = False
    res@gsnDraw                    = False 
    res@gsnCenterStringFontHeightF = 0.018
    res@cnFillOn                   = True
    res@cnLinesOn                  = False
    res@cnFillPalette              = "BlueWhiteOrangeRed"
    res@mpDataSetName              = "Earth..4"
    res@mpDataBaseVersion          = "MediumRes"
    res@mpOutlineOn                = True
    res@mpOutlineBoundarySets      = "NoBoundaries"
    res@mpOutlineSpecifiers        = (/"China:states"/)
    res@mpNationalLineColor        = "slate gray"
    res@mpProvincialLineThicknessF = 1.5
    res@lbBoxEndCapStyle           = "TriangleBothEnds"
    res@lbTitleOn                  = True
    ; res@lbTitlePosition          = "Bottom"
    res@lbTitleFontHeightF         = 0.015  ;the font size(default:0.025)
    res@lbTitleOffsetF             = -0.2   ;move the labelbar title upwards.
    res                            = wrf_map_resources(fin_1, res)
    
    type                           = "eps"
    plots                          = new(2, graphic)
    wks_back                       = gsn_open_wks(type, "R") 
    
    data                           = (/R(:,:,0)/)
    data@_FillValue                = -999.9
    data@lon2d                     = xlons
    data@lat2d                     = xlats
    res@gsnCenterString            = "R in Jan 2016"
    plots(0)                        = gsn_csm_contour_map(wks_back, data, res)
    
    data                           = (/R(:,:,1)/)
    res@gsnCenterString            = "R in July 2016"
    plots(1)                        = gsn_csm_contour_map(wks_back, data, res)

  ;;============================| Step-3.1  Add the windfarm location |=============================================
    ;-------------------------------- Setp 1:read the windfarm location data ------------------------------------------------
      delim  = ","
      temp_1 = asciiread("/home/lisi/wrf/namelist/article/windfarm/"+"windfarm.csv", -1, "string")
      loca   = str_fields_count(temp_1(0), delim)
      nwind  = dimsizes(temp_1)
      wf     = new((/nwind,loca/), float)            ;windfarm( wf )
      do i = 0, nwind-1
        do j = 0, loca-1
          wf(i,j) = tofloat(str_get_field(temp_1(i), j+1, delim))
        end do
      end do
    ;--------------------------------- Setp 2:Add the polygon to the map -------------------------------------------------
      pgres        = True
      polygon_back = new(nwind, "graphic")
      polygon_1    = new(nwind, "graphic")
      Mult         = 2.0^0.5      
      do i = 0, nwind-1
        pgres@gsFillColor = "grey60"
        lon1              = wf(i,0)
        lon2              = wf(i,1)
        lat1              = wf(i,2)
        lat2              = wf(i,3)
        lon1_d            = (lon2 + lon1)/2.0 - Mult * (lon2 - lon1)/2.0
        lon2_d            = (lon2 + lon1)/2.0 + Mult * (lon2 - lon1)/2.0
        lat1_d            = (lat2 + lat1)/2.0 - Mult * (lat2 - lat1)/2.0
        lat2_d            = (lat2 + lat1)/2.0 + Mult * (lat2 - lat1)/2.0
        lon               = (/lon1,  lon1,  lon2,  lon2,  lon1/)
        lat               = (/lat1,  lat2,  lat2,  lat1,  lat1/)
        lon_d             = (/lon1_d,lon1_d,lon2_d,lon2_d,lon1_d/)
        lat_d             = (/lat1_d,lat2_d,lat2_d,lat1_d,lat1_d/)        
        polygon_back(i)   = gsn_add_polygon(wks_back, plots(0), lon,   lat,   pgres)
        polygon_1(i)      = gsn_add_polygon(wks_back, plots(1), lon,   lat,   pgres)
      end do

  ;;============================| Step-3.2  Add the Chian map from shapefiles |=====================================
    shpname                = "/home/lisi/wrf/data/China_maps/bou1_4m/" + "bou1_4l.shp"
    plres                  = True
    plres@gsLineColor      = "black"
    ; plres@gsLineThicknessF = 1.5
    poly_1                 = gsn_add_shapefile_polylines(wks_back, plots(0), shpname, plres)
    poly_2                 = gsn_add_shapefile_polylines(wks_back, plots(1), shpname, plres)

  ;;============================| Step-3.3  Add the latlon lines |=====================================
    ; add_latlon_lines(wks_back, plots(0), xlats, xlons)
    ; add_latlon_lines(wks_back, plots(1), xlats, xlons)

  ;;============================| Step-4.0  Select the needed grids and sites |=====================================
    sites_name = (/"Tianjing","Chengde","Jilin","Neimeng","Ninxia"/)
    sites_grids_scope = (/(/54,56,18,21/),(/56,59,19,23/),(/61,64,29,33/),(/47,51,21,25/),(/36,38,8,12/)/)
    inds_max = new((/dimsizes(sites_name),2/), integer)  ;--- to save the ind of grid for the sites.
    do i = 0, 4

      c1    = sites_grids_scope(i,0)  ;--- column 1
      c2    = sites_grids_scope(i,1)  ;--- column 2
      r1    = sites_grids_scope(i,2)  ;--- row 1
      r2    = sites_grids_scope(i,3)  ;--- row 2
      tmp_R := R(r1:r2,c1:c2,0) + R(r1:r2,c1:c2,1)
      a1D   := ndtooned(tmp_R)
      dsizes_a := dimsizes(tmp_R)
      inds_max(i,:) = ind_resolve(maxind(a1D), dsizes_a)
      inds_max(i,0) = inds_max(i,0) + r1  ;--- north_south
      inds_max(i,1) = inds_max(i,1) + c1  ;--- west_east

    end do

    print(inds_max)
    
  ;;============================| Step-4.1  Add the selected grids to the map |=====================================
    res_marker = True
    do i = 0, 4
      north_south = inds_max(i,0)
      east_west = inds_max(i,1)
      tmp_lon = xlons(north_south,east_west)
      tmp_lat = xlats(north_south,east_west)
      str = unique_string("plotmarker")
      plots@$str$ = gsn_add_polymarker(wks_back, plots(0), tmp_lon, tmp_lat, res_marker)
      str = unique_string("plotmarker")
      plots@$str$ = gsn_add_polymarker(wks_back, plots(1), tmp_lon, tmp_lat, res_marker)
    end do


  ;;============================| Step-5.0  Final darw the plots in panels |=====================================
    pres                                  = True
    pres@cnLinesOn                        = False
    pres@gsnPanelFigureStrings            = (/"(a)","(b)","(c)","(d)","(e)","(f)","(g)"/)
    pres@gsnPanelFigureStringsJust        = "TopLeft"
    pres@gsnPanelFigureStringsFontHeightF = 0.008
    pres@gsnPanelCenter                   = True
    gsn_panel(wks_back, plots, (/1,2/), pres)

    print("|--- successful ---|")
end