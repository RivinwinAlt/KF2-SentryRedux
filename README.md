# SentryRemake (change to TF2SentryRedux pending)

### Overview:
A rework/update of Marco's TF2 Sentry mod from the Steam Workshop, currently uploaded by Commander Comrade Slav.


### Details:
As of now we have pirated Marco's intellectual property in an effort to continue his work for the enjoyment of all Modded-KF2 players. We have recieved permission from the current mod uploader to duplicate his workshop listing and have obtained his source materials.
This repository will be kept private for the safety and reputation of those who work on it until all code and models have been completely replaced from the ground up or the original author (Marco) gives his blessing to the project.


### GitHub File Structure:
Decompiled code will be kept seperate from the working classses and unchanged. All changes to code should occur in the "Classes" folder.


### Workshop Upload Sturcture
Workshop listings are currently maintained by Rivinwin, there is an alpha build listing and a beta build listing.
Alpha ID:	2727429858		Usually broken, used to test minute by minute changes to the code.
Beta ID:	2724231725		Usually playable with bugs, used to test for unforseen bugs/multiplayer dependant bugs.
Release ID: 
NB: The package and script names are identical between listings so you must delete the server and/or client download caches when switching between them.


### Commenting Code Guidelines:
Try to comment all blocks of code that include math or use variables with unclear names. This will allow multiple people through the years to repair the codebase as well as promote cooperation between team members.


### Project Goals:
- Fix long-standing bugs
- Implement new features
- Expose most variables in the config file
- (Recieved blessings from Slav) Get permission from Marco
- Minimize computational overhead for server
- Minimize package size for clients
- Clean up code for future expansion and upkeep
- Structure classes to be easily extendable in other mods


### [Project Roadmap](ROADMAP.md)


### Completed Changes
- Made purple light red.
- Decreased delay when right clicking to place turret.
- Sped up sentry missiles.
- Greatly reduced missile tracking overhead.
- Replaced sentry hammer model with a temporary nicer one.
- Turret preview hugs the ground when placing.
- Disabled explosion effects when selling turret.
- Fixed exploit that allowed greater than max number of turrets.
- Changed bullet tracing math to KF2 standardized method.


### Resources:
[Example project of an unbranded turret in UDK3](https://docs.unrealengine.com/udk/Three/MasteringUnrealScriptStates.html#TUTORIAL%2011.5%20%E2%80%93%20TURRET,%20PART%20I:%20MU_AUTOTURRET%20CLASS%20AND%20STRUCT%20DECLARATION)

[UDK3 Custom Menu Scripting using Flash and Kismet](https://sites.google.com/site/tessaleetutorials/home/custom-menu-in-udk)

[Source for Menu Files](https://github.com/ForrestMarkX/KFClassicMode)
- Courtesy of Forrest X