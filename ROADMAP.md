Resources:
	TF2 Sentry mod - Unreal Explorer decompile	-UEx Decompile
	TF2 Sentry mod - KF2 SDK decompile			-SDK Decompile
	TF2 Sentry mod - .upk from Workshop			-Asset Package


Goal 1: Merge the UEx and SDK Decompiles into the main branch
	Step 1: Perform a differential comparison file by file to find all entries unique to each decompile
		(Done) Used the SDK decompile in all cases after analyzing decompiled class files.
	Step 2: Remove unecessary comments and entries from the new source
		(Started)
	Step 3: Format new source in accordance with coding conventions
		(Not Started)
	Step 4: Comment source for readability
		(Started)


Goal 2: Resolve function/class names and fix default properties


Goal 3: Source turret models and animations\
	Step 1: Get original assets used in TF2 Sentry mod
		(Done) Downloaded mod from Workshop, pushed .upk to main repo
	Step 2A: Get permission from Marco to work off of them
	Step 2B: Replace assets with newly sourced ones.


Goal 4: Generate loadable binary


Goal 5: Streamline code
	Step ?: Implement Skip flags for complex If statements
	Step ?: Implement default config creation
	Step ?: Load properties from Config across project


Goal 6: Fix long-standing bugs


Goal 7: implement new features