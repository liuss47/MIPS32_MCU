debImport "-f" "filelist_sim.f"
debLoadSimResult /home/summer/Desktop/Project/mips32_core_v2/rtl/build/test.fsdb
wvCreateWindow
srcHBSelect "testbench.mips_sopc0" -win $_nTrace1
verdiWindowResize -win $_Verdi_1 "497" "100" "900" "700"
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBDrag -win $_nTrace1
wvSetPosition -win $_nWave2 {("mips_sopc0" 0)}
wvRenameGroup -win $_nWave2 {G1} {mips_sopc0}
wvAddSignal -win $_nWave2 "/testbench/mips_sopc0/clk" "/testbench/mips_sopc0/rst"
wvSetPosition -win $_nWave2 {("mips_sopc0" 0)}
wvSetPosition -win $_nWave2 {("mips_sopc0" 2)}
wvSetPosition -win $_nWave2 {("mips_sopc0" 2)}
wvZoomOut -win $_nWave2
srcHBSelect "testbench.mips_sopc0.mips32_core0.hilo0" -win $_nTrace1
srcHBDrag -win $_nTrace1
wvSetPosition -win $_nWave2 {("mips_sopc0" 1)}
wvSetPosition -win $_nWave2 {("mips_sopc0" 2)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("hilo0" 0)}
wvRenameGroup -win $_nWave2 {G2} {hilo0}
wvAddSignal -win $_nWave2 "/testbench/mips_sopc0/mips32_core0/hilo0/clk" \
           "/testbench/mips_sopc0/mips32_core0/hilo0/rst" \
           "/testbench/mips_sopc0/mips32_core0/hilo0/hilo_en" \
           "/testbench/mips_sopc0/mips32_core0/hilo0/hi_in\[31:0\]" \
           "/testbench/mips_sopc0/mips32_core0/hilo0/lo_in\[31:0\]" \
           "/testbench/mips_sopc0/mips32_core0/hilo0/hi_out\[31:0\]" \
           "/testbench/mips_sopc0/mips32_core0/hilo0/lo_out\[31:0\]"
wvSetPosition -win $_nWave2 {("hilo0" 0)}
wvSetPosition -win $_nWave2 {("hilo0" 7)}
wvSetPosition -win $_nWave2 {("hilo0" 7)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
verdiSetActWin -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvSetCursor -win $_nWave2 558855.439067 -snap {("hilo0" 7)}
wvSetCursor -win $_nWave2 559150.355954 -snap {("hilo0" 7)}
srcActiveTrace "testbench.mips_sopc0.mips32_core0.hilo0.lo_out\[31:0\]" \
           -TraceByDConWave -TraceTime 550000 -TraceValue \
           00000101000001010000000000000000 -win $_nTrace1
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
debExit
