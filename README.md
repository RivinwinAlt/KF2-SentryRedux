# TF2 Sentry Redux

### Overview:
A rework/update of Marco's TF2 Sentry mod from the Steam Workshop, currently uploaded by Commander Comrade Slav.


### Details:
As of now we have pirated Marco's intellectual property in an effort to continue his work for the enjoyment of all Modded-KF2 players. We have recieved permission from Commander Comrade Slav to duplicate his workshop listing and have obtained his source materials. We have also recieved permission from Forrest Mark X to use menu code from his Classic Mode mod to create the turret upgrade menu.


### GitHub File Structure:
Decompiled code will be kept seperate from the working classses and unchanged. All changes to code should occur in the "Classes" folder.


### Workshop Upload Structure
Workshop listings are currently maintained by Rivinwin, there is an alpha build listing and a beta build listing.
| Build | Workshop ID | Notes |
| ---: | :---: | :--- |
| Alpha | 2727429858 | Usually broken, minute by minute changes to code |
| Beta | 2724231725 | Usually playable, multiplayer bug testing |
| Public Beta | | Due to be live with a semi-stable public beta |
| Release | | Release schedule not yet determined |

N.B. - The package and script names are identical between listings so you must delete the server and/or client download caches when switching between them.


### Commenting Code Guidelines:
Try to comment all blocks of code that include math or use variables with unclear names. This will allow multiple people through the years to repair the codebase as well as promote cooperation between team members.


### Project Goals:
- Fix long-standing bugs
- Implement new features
- Expose most variables in the config file
- Recieve permission from Slav (Mod uploader, Recieved)
- Recieve permission from Marco (Not yet contacted)
- Recieve permission from Forrest (Menu system, Recieved)
- Create a new Upgrade UI using Classic Mode code
- Theme the user interface to match TF2
- Optimize server computation
- Optimize replication bandwidth and frequency
- Optiomize asset package size
- Clean code for future expansion and upkeep
- Structure classes to be easily extendable


### [Project Roadmap](ROADMAP.md)


### Resources:
[Example project of an unbranded turret in UDK3](https://docs.unrealengine.com/udk/Three/MasteringUnrealScriptStates.html#TUTORIAL%2011.5%20%E2%80%93%20TURRET,%20PART%20I:%20MU_AUTOTURRET%20CLASS%20AND%20STRUCT%20DECLARATION)

[Source for Menu Files](https://github.com/ForrestMarkX/KFClassicMode)
- Courtesy of Forrest X