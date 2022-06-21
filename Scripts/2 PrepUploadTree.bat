REM Pull packages from unpublished
robocopy "%KFFolder%\KFGame\Unpublished\BrewedPC\Packages\SentryRedux" "%KFFolder%\SentryRedux\BrewedPC\Packages\SentryRedux" *.upk /purge

REM Pull scripts from unpublished
robocopy "%KFFolder%\KFGame\Unpublished\BrewedPC\Script" "%KFFolder%\SentryRedux\BrewedPC" SentryRedux.u

REM Pull localization from source
robocopy "%KFFolder%\KFGame\Src\SentryRedux\Localization" "%KFFolder%\SentryRedux\Localization\INT" SentryRedux.INT