REM Clear downloaded mods from cache
RD /S /Q "G:\Games\kf2server\KFGame\Cache"

REM Clear Alpha Branch mod from workshop content
RD /S /Q "G:\Games\kf2server\Binaries\Win64\steamapps\workshop\content\232090\2727429858"
REM Clear Beta Branch mod from workshop content
RD /S /Q "G:\Games\kf2server\Binaries\Win64\steamapps\workshop\content\232090\2724231725"

REM Clear localization
DEL "G:\Games\kf2server\KFGame\Localization\INT\SentryRedux.INT"

REM Clear downloaded mods
DEL "G:\Games\kf2server\KFGame\Config\KFSentryRedux.ini"