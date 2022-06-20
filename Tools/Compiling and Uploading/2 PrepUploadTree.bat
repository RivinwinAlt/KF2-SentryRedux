REM Pull packages from unpublished
robocopy "C:\Users\howde\Documents\My Games\KillingFloor2\KFGame\Unpublished\BrewedPC\Packages\SentryRedux" "C:\Users\howde\Documents\My Games\KillingFloor2\SentryRedux\BrewedPC\Packages\SentryRedux" *.upk /purge

REM Pull scripts from unpublished
robocopy "C:\Users\howde\Documents\My Games\KillingFloor2\KFGame\Unpublished\BrewedPC\Script" "C:\Users\howde\Documents\My Games\KillingFloor2\SentryRedux\BrewedPC" SentryRedux.u

REM Pull localization from source
robocopy "C:\Users\howde\Documents\My Games\KillingFloor2\KFGame\Src\SentryRedux\Localization" "C:\Users\howde\Documents\My Games\KillingFloor2\SentryRedux\Localization\INT" SentryRedux.INT

REM Pull config from source
robocopy "C:\Users\howde\Documents\My Games\KillingFloor2\KFGame\Src\SentryRedux\Config" "C:\Users\howde\Documents\My Games\KillingFloor2\SentryRedux\Config" KFSentryRedux.ini