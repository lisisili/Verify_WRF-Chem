; target:       add the plot resource file
; created time: 2020/4/18

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
    ResOut@xyMarkLineModes             = (/"Lines", "Markers"/) ;--- Sim is lines, Obs is markers
    ; ResOut@xyMarkLineModes             = (/"Lines", "Lines"/) ;--- Sim is lines, Obs is markers
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
    ResOut@xyMarkLineModes             = (/"Lines", "Lines"/) ;--- Sim is lines, Obs is markers
    
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