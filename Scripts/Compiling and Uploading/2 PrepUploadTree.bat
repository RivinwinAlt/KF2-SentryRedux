REM Pull packages from unpublished
robocopy "C:\Users\joshu\Documents\My Games\KillingFloor2\KFGame\Unpublished\BrewedPC\Packages\SentryRedux" "C:\Users\joshu\Documents\My Games\KillingFloor2\SentryRedux\BrewedPC\Packages\SentryRedux" *.upk /purge

REM Pull scripts from unpublished
robocopy "C:\Users\joshu\Documents\My Games\KillingFloor2\KFGame\Unpublished\BrewedPC\Script" "C:\Users\joshu\Documents\My Games\KillingFloor2\SentryRedux\BrewedPC" *.u

REM Pull localization from source
robocopy "C:\Users\joshu\Documents\My Games\KillingFloor2\KFGame\Src\SentryRedux\Localization" "C:\Users\joshu\Documents\My Games\KillingFloor2\SentryRedux\Localization\INT" *.INT

REM Pull config from source
robocopy "C:\Users\joshu\Documents\My Games\KillingFloor2\KFGame\Src\SentryRedux\Config" "C:\Users\joshu\Documents\My Games\KillingFloor2\SentryRedux\Config" *.ini