vlib work
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_pack-p.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_comp_pack-p.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_core_comp_pack-p.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_col_pack-p.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_addr_mux.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_clk_gen.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_col_mux.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_cpuio.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_ctrl.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_hor_vert.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_pattern.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_sprite.vhd
IF ERRORLEVEL 1 GOTO error
vcom ..\vdp18\vdp18_core.vhd
IF ERRORLEVEL 1 GOTO error

vcom tb_vdp18.vht
IF ERRORLEVEL 1 GOTO error
vsim -t ns tb -do all.do
IF ERRORLEVEL 1 GOTO error

goto ok

:error
echo Error!
pause

:ok
