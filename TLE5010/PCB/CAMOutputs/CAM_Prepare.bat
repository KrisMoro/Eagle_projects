:: Dedaults 
@SET DIA=1.5 
@SET GAP=0.8
@SET GAPS=tb
@SET DPT=1.6
@SET FR=60
@SET GRV=0.1
@SET PAS=2
@SET GRVW=0.3
 
::Filenames
@SET DIMEN=BoardShape.gbr
@SET ISOL=copper_top.gbr
@SET DRI=drill.xln
@SET MILL=Cutouts.gbr
@SET FP="C:\Program Files\FlatCAM\FlatCAM.exe"

@SET DIMEN_OUT=04_BoardShape.nc
@SET ISOL_OUT=01_copper_top.nc
@SET DRI_OUT=02_drill.nc
@SET MILL_OUT=03_Cutouts.nc
 
@ECHO Cut border %DIMEN%. Drill %DRI% Engrave %ISOL% Mill holes %MILL%
@ECHO.
@ECHO Defaults:
@ECHO Mill diameter	= %DIA% mm
@ECHO Mill flow rate	= %FR% mm/min
@ECHO Tap width	= %GAP% mm
@ECHO Tap placement	= %GAPS%
@ECHO Drill depth	= %DPT% mm
@ECHO Carving depth	= %GRV% mm
@ECHO Carver width    = %GRVW% mm
@ECHO Carving passes	= %PAS%
 
@ECHO.
 
@SET /P DIA=Enter mill diameter (%DIA%):
@SET /P FR=Enter flow rate of external milling(%FR%):
@SET /P GAP=Enter tap width(%GAP%):
@SET /P GAPS=Enter gap placement (8,4,tb,lr,2tb,2lr)[%GAPS%]:
@SET /P DPT=Enter drill depth (laminate height +0.2)[%DPT%]:
@SET /P GRV=Enter carving depth (0.05...0.2)[%GRV%]:
@SET /P GRVW=Enter carver width [%GRVW%]:
@SET /P PAS=Enter number of carving passes [%PAS%]:
 
 
 
:: Берем текущий каталог
set dp=%CD%
 
:: Меняем в нем слеши на обратные (это надо флаткаму)
set dp=%dp:\=/%

delete %DIMEN_OUT%
delete %ISOL_OUT%
delete %DRI_OUT%
delete %MILL_OUT%
 
:: Вбиваем программу.
:: echo new > cmd.tcl
echo set_sys excellon_zeros T > cmd.tcl
 
:: Грузим файлы из корня
echo # Loading gerger files >> cmd.tcl
echo open_gerber %dp%/%DIMEN% >> cmd.tcl
echo open_gerber %dp%/%ISOL% >> cmd.tcl
echo open_gerber %dp%/%MILL% >> cmd.tcl
echo open_excellon %dp%/%DRI% >> cmd.tcl
 
::Первым под обрезку идет контур.
echo # Milling cutout >> cmd.tcl
echo isolate %DIMEN% -dia %DIA% -passes 1 -outname cut >> cmd.tcl
echo exteriors cut -outname cutout >> cmd.tcl
echo delete cut >> cmd.tcl
echo geocutout cutout -dia %DIA% -gapsize %GAP% -gaps %GAPS% >> cmd.tcl
echo cncjob cutout_cutout -z_cut -%DPT% -z_move 2 -feedrate %FR% -tooldia %DIA% -spindlespeed 20000 -outname cutout.tap >> cmd.tcl
echo delete cutout_cutout >> cmd.tcl
echo write_gcode cutout.tap %dp%/%DIMEN_OUT% >> cmd.tcl
 
:: Mill holes
echo # Milling holes >> cmd.tcl


:: Гравировка поверхности
echo # Carving cooper >> cmd.tcl
echo isolate %ISOL% -dia %GRVW% -passes %PAS% -overlap 0.5 -combine 1 -outname bottom >> cmd.tcl
echo cncjob bottom -z_cut -%GRV% -z_move 2 -feedrate 100 -tooldia 0.2 -spindlespeed 20000 -outname bottom.tap >> cmd.tcl
echo delete bottom >> cmd.tcl
echo write_gcode bottom.tap %dp%/%ISOL% >> cmd.tcl
 
:: Затем идет сверловка
echo # Drilling >> cmd.tcl
echo drillcncjob %DRI% -drillz -%DPT% -travelz 3 -feedrate 100 -spindlespeed 300 -toolchange True -outname drill.tap >> cmd.tcl
echo write_gcode drill.tap %dp%/%DRI_OUT% >> cmd.tcl
 
 
:: Последним шагом запускаем флаткам и скармливаем ему этот скрипт.
%FP% --shellfile=%dp%/cmd.tcl