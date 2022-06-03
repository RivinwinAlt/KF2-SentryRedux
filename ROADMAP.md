# Roadmap
Goals are roughly in order. Input is welcome.


### 1: Merge the UEx and SDK Decompiles into the main branch
- ~~Perform a differential comparison file by file to find all entries unique to each decompile~~
- ~~Remove unecessary comments and entries from the new source~~
- ~~Format new source in accordance with coding conventions~~
- ~~Merge menu classes from ClassicMode into the codebase~~
- ~~Comment original source for readability~~


### 2: Source turret models and animations
- ~~Get original assets used in TF2 Sentry mod~~
- ~~Get permission from Marco/Slav to use them~~
- ~~Extract the TF2 wrench mesh + animations + material~~
- Obtain new turret models + animations + materials to craft new turrets


### 4: Fix long-standing bugs
- ~~Change purple light on turret to red~~
- ~~Replace green hammer material~~
- ~~Disable taking over existing turrets beyond max allowed~~
- Stop the Sentry Hammer from showing as EMPTY in inventory
- Improve pop-in when obstructed by narrow walls, etc


### 5: Implement new features
- ~~Be able to rotate turret during placement~~
- More turret types
- Integrate more buyable upgrades
  - See Discord google sheets (Rowdy Howdy's Server)
- ~~Turret Preview hugs ground when placing~~
- ~~Decrease delay when right clicking~~
- ~~Faster rockets~~
- Implement new default balancing:
  - Lower turret cost
  - Higher ammo cost
  - Higher refund percentage
- ~~Custom canvas based menu~~
- ~~Disable explosion GFX when selling turret~~
- Add custom "selling turret" SFX
- Add idle wrench animation from TF2
- ~~Alter menu rendering to enforce 16:9 aspect ratio on all screens~~
- Be able to queue upgrades
- Add menu accesible with Hammer AltFire to change selected turret type


### 6: Move default properties and variables to config file
- Sentry Missile speed
- Place turret delay when right clicking
- Disable right click to sell
- Customizable refund modifier
- GFX disabling booleans
- Client side graphic-centric settings menu
- Server mod settings menu page available to Admins
- Implement config value clamping


### 7: Optimization
- Run clocked test to compare old random bullet trajectory to new method
- ~~Only load one copy of each texture used in mod~~
- Minimise missile raytracing


### Bugs
- Custom sounds aren't working, unlinked when transfering assets to new package