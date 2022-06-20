set sourceBinary="%1"
set editorExe="KFEditor.exe"
set outputPath="G:\SteamSlow\steamapps\common\killingfloor2\Decompile"

%editorExe% batchexport %sourceBinary% class uc %outputPath%
pause