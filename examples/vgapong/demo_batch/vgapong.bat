@ REM ######################################
@ REM # Variable to ignore <CR> in DOS
@ REM # line endings
@ set SHELLOPTS=igncr

@ REM ######################################
@ REM # Variable to ignore mixed paths
@ REM # i.e. G:/$SOPC_KIT_NIOS2/bin
@ set CYGWIN=nodosfilewarning

@ copy /Y ..\output_files\vgapong.sof vgapong.sof
%QUARTUS_ROOTDIR%\\bin\\quartus_pgm.exe -m jtag -c 1 -o "p;vgapong.sof@1"
pause