# Roadmap
Goals are in order of what should be acomplished. Input is welcome.


### 1: Merge the UEx and SDK Decompiles into the main branch
- ~~Perform a differential comparison file by file to find all entries unique to each decompile~~
- ~~Remove unecessary comments and entries from the new source~~
- ~~Format new source in accordance with coding conventions~~
- ~~Merge menu classes from ClassicMode into the codebase~~
- Comment source for readability
  - Status: Ongoing


### 2: Move default properties and variables to config file
- ~~Sentry Missile speed~~
- ~~Place turret delay when right clicking~~
- ~~Disable right click to sell~~
- ~~Customizable refund modifier~~
- GFX disabling booleans
- Client side graphic-centric settings menu
- Server mod settings menu page available to Admins


### 3: Source turret models and animations
- ~~Get original assets used in TF2 Sentry mod~~
- ~~Get permission from Marco/Slav to use them~~
- ~~Extract the TF2 wrench mesh + animations + material~~
- Obtain new turret models + animations + materials to craft new turrets


### 4: Streamline code
- ~~Combine simple functions and remove null calls~~
- ~~Move TF2 Turret dependant variables to a new extended class~~
- ~~Rework the base turret class to be more flexible~~
- Implement config value clamping


### 5: Fix long-standing bugs
- ~~Change purple light on turret to red~~
- ~~Replace green hammer material~~
- ~~Patch taking over existing turrets beyond max number~~
- Stop the Sentry Hammer from showing as EMPTY in inventory
- Improve pop-in when obstructed by narrow walls, etc


### 6: Implement new features
- ~~Be able to rotate turret during placement~~
- More turret varieties (Perkified versions)
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
- Add menu accesible with Hammer AltFire to change turret being placed


### 6: Optimization
- Run clocked test to compare old random bullet trajectory to new method
- Only load one copy of each texture used in mod
- Implement Skip flags for complex If statements (use booleans and timers to reduce branching frequency)
- Minimise raytracing
  - ~~Missiles~~
  - Turret preview


### Bugs
