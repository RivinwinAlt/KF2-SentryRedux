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
- Be able to rotate turret during placement
- Expose most constant variables in config files.
- Ensure the mod is as lightweight as possible for servers without sacrificing functionality.
- Integrate perks that boost or alter turrets.
or
- More turret varieties
  - Perkified versions
- Integrate more buyable upgrades.
  - swivel speed
  - firerate
- Fix longstanding bugs.
  - ~~Replace green hammer~~
  - ~~Patch taking over existing turrets~~
- Trying to make it as the Sentry shows up as empty in your inventory.
- Turret will not scan until it finds its first target; fix this.
- Faster rockets would be nice.
- Change the Rocket logic

### Completed Changes
Reduced placement delay from 0.5 to 0.3
Sped up rocket (2000 -> 3000)
Changed the purple light on the turret to be red

### Resources:
[Example project of a non-branded turret in UDK3](https://docs.unrealengine.com/udk/Three/MasteringUnrealScriptStates.html#TUTORIAL%2011.5%20%E2%80%93%20TURRET,%20PART%20I:%20MU_AUTOTURRET%20CLASS%20AND%20STRUCT%20DECLARATION)
[UDK3 Custom Menu Scripting](https://sites.google.com/site/tessaleetutorials/home/custom-menu-in-udk)