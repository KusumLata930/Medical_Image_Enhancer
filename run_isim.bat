@echo off
REM ===== End-to-end ISim run (Xilinx ISE) =====
REM Usage:  run_isim.bat          -> opens ISim GUI with waveform for each stage
REM         run_isim.bat batch    -> no GUI, just runs everything and writes outputs
REM Open "ISE Design Suite Command Prompt" (or run settings64.bat) first so fuse is on PATH.

cd /d "%~dp0sim"
set MODE=%1

for %%T in (tb_salt_pepper_removal tb_image_enhancer tb_image_enhancer_advanced) do (
  echo.
  echo ===== Compiling %%T =====
  fuse work.%%T -prj ..\isim\%%T.prj -o %%T.exe || goto :err
)

if /I "%MODE%"=="batch" goto :batch

echo ===== Stage 1: median filter (GUI) =====
tb_salt_pepper_removal.exe -gui -tclbatch ..\isim\wave_salt_pepper.tcl
echo ===== Stage 2: contrast stretching (GUI) =====
tb_image_enhancer.exe -gui -tclbatch ..\isim\wave_contrast.tcl
echo ===== Stage 3: histogram equalisation (GUI) =====
tb_image_enhancer_advanced.exe -gui -tclbatch ..\isim\wave_advanced.tcl
goto :post

:batch
tb_salt_pepper_removal.exe -tclbatch ..\isim\batch.tcl || goto :err
tb_image_enhancer.exe -tclbatch ..\isim\batch.tcl || goto :err
tb_image_enhancer_advanced.exe -tclbatch ..\isim\batch.tcl || goto :err

:post
cd ..
python python\compare_and_view.py
goto :eof

:err
echo *** Build or run failed - see messages above ***
exit /b 1
