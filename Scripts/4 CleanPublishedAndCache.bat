REM Clear Brewed packages
RD /S /Q "%KFFolder%\KFGame\Published\BrewedPC\Packages\SentryRedux"

REM Clear downloaded mod - ScaredKids custom turret version (In case Rivinwin plays on there and picks up a loose tf2sentry.upk)
RD /S /Q "%KFFolder%\KFGame\Cache\2786576980\"
REM Clear downloaded mod - Comander Comrade Slavs Turret Mod
RD /S /Q "%KFFolder%\KFGame\Cache\2146677560\"
REM Clear downloaded mod - Sentry Redux Alpha
RD /S /Q "%KFFolder%\KFGame\Cache\2727429858\"
REM Clear downloaded mod - Sentry Redux Beta
RD /S /Q "%KFFolder%\KFGame\Cache\2815922523\"


REM Clear compiled scripts
DEL "%KFFolder%\KFGame\Unpublished\BrewedPC\Script\SentryRedux.u"
DEL "%KFFolder%\KFGame\Published\BrewedPC\SentryRedux.u"