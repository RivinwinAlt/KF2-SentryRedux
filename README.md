# SentryRemake (working title)

### Overview:
A rework/update of Marco's TF2 Sentry mod from the Steam Workshop.


### Details:
As of now we have pirated Marco's intellectual property in an effort to continue his work for the enjoyment of all Modded-KF2 players. This repository will be kept private for the safety and reputation of those who work on it until all code and models have been completely replaced from the ground up or the original author gives his blessing to the project. If we recieve Marco's permission to officially continue his code the mods title may be reverted to 'tf2sentry'.


### GitHub File Structure:
Decompiled code will be kept seperate from the working classses and unchanged. All changes to code should occur in the "Classes" folder.


### Comment Guidelines:
Try to comment all blocks of code as they are understood and reworked. This will allow multiple people through the years to repair the codebase.


### Project Goals:
- Fix long-standing bugs
- Implement new features
- Expose most variables in the config file
- Get permission to publish original assets from Marco/Slav
- Minimize computational overhead for server
- Minimize package size for clients
- Clean up code for future expansion and upkeep


### [Project Roadmap](ROADMAP.md)


### Completed Changes
- Made purple light red
- Decreased delay when right clicking to place turret
- Sped up sentry missiles
- Reduced missile tracking overhead
- Replaced sentry hammer model with a temporary nicer one
- Turret preview hugs the ground when placing

### Resources:
[Example project of an unbranded turret in UDK3](https://docs.unrealengine.com/udk/Three/MasteringUnrealScriptStates.html#TUTORIAL%2011.5%20%E2%80%93%20TURRET,%20PART%20I:%20MU_AUTOTURRET%20CLASS%20AND%20STRUCT%20DECLARATION)
[UDK3 Custom Menu Scripting using Flash and Kismet](https://sites.google.com/site/tessaleetutorials/home/custom-menu-in-udk)