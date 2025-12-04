sfall, a fallout 2 engine tweak mod by Timeslip and many other contributers
version 3.2, built for fallout 2 v1.02 US

Sourceforge project and source code: http://sourceforge.net/projects/sfall
Additional materials at:             http://timeslip.users.sourceforge.net

This was a quick fallout mod which I originally stuck together to try and fix a few minor annoyances that I had with the games, but which then turned into a slightly bigger mod which fixed some other peoples annoyances and some of the bugs in the original fallout engine too, and has since turned into a bloody huge mod with code contributions from a double figured number of people and with which modders could practically write a whole new game. The features are too numerous to list these days, so you'll have to read through the changelog instead.

This mod only works with a specific version of the fallout 2 exe; the US copy of 1.02. Attempting to use this mod with an incompatible version of fallout will result in an error when you try to run it. If your version of fallout doesn't have kids, then you have the UK version instead of the US version, so you'll need to patch it into the US version before using this mod.

Using a d3d9 graphics mode obviously requires you to have dx9 installed and a dx9 compatible graphics card. sfall requires a recent DX9.0c update. (Specifically, the one that includes d3dx9_43.dll.) If you set the graphics mode to 4 or 5 but don't have DX9.0c installed at all, fallout will crash on startup. If you have a version of DX9.0c installed, but one which is older than the required one, fallout will crash at the main menu. Please note that there have been several years worth of releases all labelled '9.0c', with little way of telling them apart aside from the release date. The versions of DirectX 10 and 11 included with windows vista and 7, as well as the versions of directx installed by games, do not always contain the most up to date DirectX 9 components, so even if you think you have DX9.0c already, run the web installer to check if you crash at the main menu.

The current version of sfall only works on windows xp services pack 3 and above. Versions up to 3.1 are available for windows 2000, and older versions are available for windows 9x.

******************
** Installation **
******************

Extract 'ddraw.dll' and 'ddraw.ini' to fallout's base directory. (i.e. the one that contains fallout2.exe.)

IMPORTANT NOTE:
If you are using a mod that included sfall already (e.g. killaps unofficial path or RP, etc.) then that mod has probably included a custom modified ddraw.ini. In that case, overwriting it with sfall's vannila ddraw.ini will be likely break your game. Instead, only overwrite ddraw.dll, and keep the mods existing copy of ddraw.ini. (Or, if you know what you're doing, you can merge them together by hand.)

The folder 'translations' contains translations of some of the strings that sfall displays in game. To use a translation, copy this folder to fallout's base directory too, and then in ddraw.ini change the 'TranslationsINI' setting to './translations/<your language>.ini'

********************
** Uninstallation **
********************

Delete ddraw.dll and ddraw.ini from your fallout directory.

***********
** Usage **
***********

This mod is configured via the 'ddraw.ini' file, which can be opened with any text editor. Details of every configerable option are included in that file. Where a comment refers to a DX scancode, the complete list of codes can at the link below:
http://www.gamespp.com/directx/directInputKeyboardScanCodes.html

In a default installation using an unmodified copy of ddraw.ini, the middle mouse button will be set to switch between weapons and the mouse wheel will be set to scroll through any menus that respond to the up/down arrow keys. Holding ctrl and hitting numpad keys 0 to 6 will adjust the game speed. The script extender and any engine fixes are also enabled. Options which change gameplay in some way not originally intended by the developers are disabled.

******************
** Known issues **
******************

It is not possible to completely remove the fallout 2 13 year time limit, because fallout 2 stores the time passed since the start of the game in a 32 bit variable, and on the 8th of March 2255 this variable overflows, causing fallout to crash. (Normally, the game will end on the 25th of July 2254) This mod does give you several options for removing the limit, but each option has its own set of side effects. If you are planning on powergaming, as well as setting the TimeLimit line to -3, I suggest setting the WorldMapTimeMod value to somewhere around 10, which will increase the amount of gameplay time you have between tickcount rollovers by an order of magnitude.

***************
** Changelog **
***************

v3.2
>The build environment is now visual studio 2012. The required d3dx9 version is increased, and
  win xp sp2 and win 2000 are no longer supported.
>Fixed potential corruption of pc's age, gender, or current hp/poison/rads when using perks.ini
>Readded npc combat control
>Changed the way mode 1 global scripts work, to fix compatibility with the latest res patch
>Fixes to glovz ammo patch

v3.1
>Fixed folding of constant float expressions in sfall script editors optimizer
>Fixed the active_hand and set_pickpocket_max script functions
>Added a fix for a crash when killing critters with explosives

v3.0
>Added get/set_critter_skill_points, get/set_available_skill_points, mod_skill_points_per_level,
  set_perk_freq, get_last_attacker, get_last_target and block_combat script functions
>Added a fix for the super stimpack exploit
>Added config options to control skill costs
>Fixed in_world_map script function potentially returning an incorrect value
>Fixed force_aimed_shots and disable_aimed_shots corrupting behaviour of other weapons
>Fixed potential problem with the modified_ini script function
>Fixed the missing last argument of the ap cost hook script
>Fixed apperence of version info in windows (From NovaRain)
>When using dx9 graphics, gpu blt is enabled automatically if supported
>When using dx9 graphics, resolution is changed automatically when using the res patch
>Removed upscaling filter support
>Removed ddraw.ini defined global shader
>Removed multiplayer
>Removed the update check

v2.20a
>Fixes for sfall bugs in critical hits against horrigan and the player
>Update check is now disabled by default

v2.19a
>Added options to move the main menu buttons and credit text
>Fixed a bug in the default heal rate formula when modifying stat relationships

v2.18a
>Added an option to disable the pipboy alarm
>Hero apperence mod bug fixes. (From Mash)

v2.17b
>Fixed a crash bug introduced with motion scanners

v2.17a
>Added an option to adjust the behaviour of the motion scanner
>Added an option to increase the maximum number of slots in encounter tables
>Added new script function: get_npc_level
>Fixed removal of hardcoded effects for the skilled trait

v2.16a
>Added new script functions: force_aimed_shots, disable_aimed_shots, mark_movie_played
>Added a config file to change the SPECIAL/derived stat relationships
>Added an option to limit inventory by space as well as weight
>Improved the compatibility mode check

v2.15a
>Added the ability to adjust skill/stat relationship
>Added an option to add stat/skill effects to traits via config files
>Fixed an issue with doors being able to dodge bullets (From Mash)
>Added an option to increase the maximum number of named scripts

v2.14a
>Added a method of creating critical tables for new critter types
>Added a new option to block all saving in combat (off by default)

v2.13b
>A fix for hero apperence mod breakage in 2.13a (From Mash)

v2.13a
>Fixed a virtual file system bug
>Hero apperence mod fixes and improvements (From Mash)
>Two alternate fixes to the interaction between H2H attacks and the fast shot trait (One from Haenlomal)

v2.12a
>New script function: set_sfall_arg
>Added a fix for the original engine issue that could cause fallout to look for the music in the wrong folder
>Added a fix for the original engine issue that prevented melee npcs attacking multihex critters (From Haenlomal) 
>Added an option to allow party members to reach level 6 (From Haenlomal)
>Added an option to change the font colour on the main menu
>More bug fixes for Glovz's mod
>More flexibility for the 32 bit talking heads
>key_pressed now accepts values from 256 to 263 to report on the status of up to 8 mouse buttons (From NVShacker)
>Fix the rcpres variable in shaders containing two copies of 1/screen width
>Fixed an sfall bug that broke critical hits when starting a new game, up until a game was first reloaded
>Limited the scrollable quest window to prevent crashes from multiline quests (From Haenlomal)

v2.11a
>Added an option to remove the critical hit/miss limits in the first few days of game time
>Added an option to use 32 bit images for talking heads
>Fixed the original engine issue that resulted in the jet antidote not being consumed (From Haenlomal)
>Fixed the original engine issues with the wield_obj_critter script function (From Haenlomal)
>Fixed the original engine issue that caused the critical hit bonuses from special unarmed attacks to not be applied correctly. (From Haenlomal) 
>Fixed the sfall bug that made the jinxed trait rather more potent than it should have been
>Fixed an issue with the karma image override that caused it to leak out to other panels
>Fixed a hero appearance mod issue that caused the wrong frm to be displayed when opening a bag in the inventory (From Mash)
>Fixed a bug in Glovz's damage mod.

v2.10b
>Fix a crash bug in Haenlomal's hth damage fix

v2.10a
>A fix for the original engine bug that caused bonus hth damage to not be applied correctly (From Haenlomal)
>New script function get_sfall_args
>A new hook script hs_itemdamage
>A fix for one possible cause of the cannot create input device error (Thanks to mjurgilas for the hint)
>An option to increase the cap on maximum number of map animations to 127. (From Mash)
>Moved DontDeleteProtos to the [Debugging] section of ddraw.ini

v2.9c
>A hero apperence mod fix (from Mash)
>A new version of Glovz's ammo patch (From, umm, Glovz...)

v2.9b
>Fix a mixup with the hs_hex[type]blocking which resulted in using the shoot blocking rule for a sight test
>Last of the ddraw.ini cleanup

v2.9a
>New script functions: scan_array, get_tile_fid, modified_ini
>New hook scripts: hs_movecost, hs_hex[type]blocking
>Fixed a crash bug in get_game_mode
>Some more ddraw.ini cleanup

v2.8c
>Added the ability to add additional notification boxes to the interface
>Some more ddraw.ini cleanup.
>Fixed critical hits against the player being broken when overriding the critical hit table

v2.8b
>new script functions: atoi, atof
>Moved SkipCompatModeCheck to the [Debugging] section of ddraw.ini
>Removed a few options from ddraw.ini that should never be turned off
>Added an option to apply bug fixes to the critical table without having to supply an ini (Values from killap)
>Fixed broken return value from hs_barterprice

v2.8a
>New script functions: len_array, resize_array, temp_array, fix_array, string_split, list_as_array
>New hook scripts: hs_removeinvenobj, hs_barterprice
>Added an option to adjust the rotation rate of the critter frm in the inventory/new char screens. (From Mash)
>the list_xxx functions can now list over scenery, walls and misc objects.
>A new ammo mod (From Haenlomal)
>Fixed a crash bug in get_uptime
>Moved ExtraCRC and AllowUnsafeScripting into the [Debugging] section of ddraw.ini

v2.7a
>Added an option to make the karma image on the character screen dependent on your current karma
>Added support for using wma, mp3 or wav files for sound, and new looping script functions
>Added array support in scripts
>Added an option to allow the use of the science/repair skills on critters
>Some debug editor improvements (array and critter editing support)
>updater improvements to prevent the crashes that happened during sourceforges maintenance downtime from reoccurring.

v2.6c
>More apperence mod bugfixes (From Mash)
>Fixed a crash when restoring the fallout window while using graphics mode 4

v2.6b
>Fixed a bug in the hero apperence mod that broke player sfx (From Mash)

v2.6a
>New script function: set_map_time_multi 
>Added option to speed up the spinning interface counter animations
>Debug editor now has access to sfall globals, and can show the names of globals and critters
>Fixed a nasty memory corruption bug in hookscripts
>Added an option to increase the number of save slots (From Mash)
>Added improved logging capabilities

v2.5b
>Fixed a crash bug in the hero apperence mod (From Mash)

v2.5a
>Appearance mod improvements (From Mash)
>Added a debug editor that lets you make changes to various values while in game
>The combatdamage hook script can now get the targeted bodypart

v2.4a
>New script function: force_encounter_with_flags
>Added an option to save the console contents to a file
>get/set_sfall_global can now optionally take an int instead of a string
>The limit of 1024 sfall globals has been removed
>sfall globals are now far faster if many are in use at once

v2.3a
>Added the ability to attach voice clips to floating text displayed in combat
>Added an option to override the hardcoded city reputations list
>New script function: get_attack_type
>Added a fix for the original engine issue that could prevent npc levelling with some party compinations
>Fixed reentrency problems in hook scripts
>Fixed the delay loading of d3dx, which became broken when I switched to the newer directx sdk.
>Removed the trait_adjust_* hook scripts, which were causing unfixable script corruption

v2.2b
>New script function refresh_pc_art (from Mash)
>Appearance mod fixes and tweaks (from Mash)
>create_message_window tweaks (From Helios)
>Fixed crc check checking the size of the wrong file when launching fallout from a shortcut

v2.2a
>Added the ability to control premade characters, and add additional ones
>Switched to using a crc check to make sure that sfall is being used with the correct fallout exe
>The multiplayer server is now functional, and the client is included
>New script function: get_light_level
>Two new hook scripts: HS_AdjustSkill and HS_AdjustStat
>Included german and french translations (From Mr.Wolna and Ardent)

v2.1a
>Some elements of sfall can now be translated
>Added a check-for-updates option
>Added an option to allow scrolling of quest lists in the pipboy (From Ray)
>Removed eax support
>Removed win9x support
>Removed the block on steam, and the timeout code

v2.0d
>Modified the trait override code to not run if the perks.ini is not present
>Another attempt at fixing the explorer hang

v2.0c
>You can now edit traits via perks.ini as well as perks
>New script function, remove_trait
>Fixed sfall title display when using the res patch
>Updated hero apperence mod (from Mash)

v2.0b
>The control party members option now behaves slightly better
>The mouse position functions now return the hotspot rather than the upper left corner of the cursor
>Fixed something I broke while adding in Helios's code

v2.0a
>Added new hook scripts hs_findtarget and hs_useobjon
>Added an option to skip the opening movies
>Made a fix to the line of fire fix
>Added an option to give npcs a second chance to spend left over ap at the end of their combat round
>Added new script functions to manipulate weapon ammo
>Added an option to allow the use of tiles larger than 80x36
>Added an option to directly control party members in combat (buggy)
>Multiplayer support (buggier)
>New script function: write_string
>Added an option to replace the mouse cursor used when using skills. (From Helios)
>Added new window related script functions. (From Helios)

v1.49d
>Fixed issue with global scripts not running on the world map when using the new world map speed patch
>Fixed issue with item highlighting only working on the first elevation of each map.

v1.49c
>Hero apperence mod behaviour changes to fix some conflicts with patch dats and sfall saving (from Mash)

v1.49b
>Fixed some parts of the hero apperence mod still running even if disabled in the ini

v1.49a
>Added Hero appearance mod code from Mash
>Extra argument to hook script hs_combatdamage to get the weapon used in the attack
>Fixed set_script bug when used with critters
>New script function set_critter_burst_disable

v1.48a
>Altered numbering scheme to avoid bug in unicode version of windows
>sfall now displays its version number on the title menu
>display an appropriate message and quit when used with steam
>fixed very nasty bug when saving with a patch file loaded
>added new script functions to get the current sfall version

v1.47b
>New script functions: list_begin, list_next and list_end
>Fixed an issue if a global script tried to register_hook a hook that already had a hs_* script attached.
>Fixed an issue with using register_hook across reloads

v1.47
>New script functions set_proto_data, set_self, register_hook
>Further file system script functions
>Hook script changes to aid in mod compatibility; multiple scripts can now attach to one hook point

v1.46b
>New script function get_proto_data

v1.46
>13 new script functions related to a virtual filesystem
>Added a new hook script hs_ondeath
>Added a new option 'GPUBlt' to speed up rendering in dx9 graphics modes by 3-4x
>Using graphics mode 4 or 5 with an out of date version of DirectX now displays a useful error message instead of crashing

v1.45b
>Added an option to prevent fallout from hogging the processor
>Fixed get_script still returning a script after calling remove_script
>set_script can now be used on objects that are already scripted

v1.45
>Added a new hook script, hs_combatdamage
>Added 3 new script functions: remove_script, set_script and get_script
>Fixed the vanilla fallout bug where an instadeath critical hit for no damage wouldn't run the critter death function
>Fixed issue with the initilization function of most hook scripts not being rerun on player reload
>Added an extra check to try and fix WorldMapFPSPatch crashes

v1.44c
>Added an option to reverse the left and right mouse buttons for left handed players

v1.44b
>Added an option to setup a key to toggle highlighting of items on the ground
>Fixed issue with death anim hook scripts crashing on some npcs
>Fixed fake traits/perks not being removed if picked and then canceled

v1.44
>Added two new hook scripts to allow scripting of death animations

v1.43b
>Added an option to play the players idle animation on weapon reload
>Added a fix for corpses absorbing weapons fire

v1.43
>Added an option to display karma changes
>Added new world map speed patch (From Ray)
>Added shiv item code fix (From Kanhef)
>Added fix for imported procedures with arguments (From KLIMaka)
>Added an option to always reload msg files (From Ray)

v1.42
>Added some maths scripting functions: sqrt, abs, sin, cos, tan, arctan
>New script function: set_palette
>New hook script: hs_calcapcost

v1.41c
>Added an option to load multiple patch files at once (From Ray)

v1.41b
>New script function: get_ini_string
>New hook script: hs_afterhitroll

v1.41
>Added new script functions for modifing the critical hit table, ap ac bonus and to support hook scripts
>Added an option to override the default critical hit table
>Added hook scripts. (Only one atm, to override the hit percentage chance modifier)

v1.40
>Added 2 new script functions: get_bodypart_hit_modifier and set_bodypart_hit_modifier
>New options in the ini file to set the initial bodypart hit modifiers

v1.39
>Added 3 new script functions: show_iface_tag, hide_iface_tag and is_iface_tag_active
>Added an option to fix the crash caused by withdrawal effects without an associated description

v1.38
>Added an ini option to skip the compatibility mode check
>Added 11 new script functions for performing generic memory writes and function calls
>Added new sript function: set_hp_per_level_mod

v1.37
>Added support for adding additional movies (max of 32)
>In dx9 mode, avi movies will be used in preference to .mve's if they exist
>Weapon animation codes 11 and 15 now corrispond to file paths of 's' and 't' respectively
>Weapon animation codes greater than 15 are no longer allowed
>Fixed another possible hang on startup problem on win9x

v1.36
>Added an option to increase the number of sound buffers available for sound effects
>Added an option to stop fallout deleting non readonly protos
>Fixed compatibility with v1.7 of the resolution patch when using graphics mode 5 or 6

v1.35d
>Fixed crash bug with thrown weapons introduced in 1.33

v1.35c
>Fixed issues with negative hit chances
>Increased the number of new animation slots
>Trying to set a custom xp table caused a hang on startup with the win9x version

v1.35b
>Fixed player not being able to increase skills

v1.35
>Added an option to set a custom xp table and level cap
>Added the ability to add new weapon animation types
>Fixed a possible issue with fake perks on win9x

v1.34c
>Fixed a bug introduced in 1.33 that caused skills with negative percentages to wrap around
>Fixed elevators again

v1.34b
>Fixed an issue with adding additional elevators

v1.34
>Added an option to define a key to allow you to move the window in graphics mode 5
>Added experimental support for adding additional elevators and modifing old ones.

v1.33c
>Fixed a compilation error in the win xp version that broke compatibility with older processors

v1.33b
>Added some extra script functions to modify some of the vanilla perks

v1.33
>8 new script functions related to adding new perks
>6 new script functions to allow critter specific modifications to skill caps, stealing and combat hit chances.

v1.32
>New script functions: set_fake_trait and set_fake_perk

v1.31b
>Fixed some get_game_mode issues
>A further slight speed increase in dx9 mode

v1.31
>Improved fps in DX9 mode
>Add a 'combat save' fix that prevents saving in combat if you have spent any ap
>Removed the bonus move fix, which was unfixably buggy, in favour of the combat save fix

v1.30
>Fixed movies in DX9 mode
>The compatibility mode check will now ignore the disable themes, turn off advanced text services and run as administrator settings.
>Added new script functions: set_pc_stat_min, set_pc_stat_max, set_npc_stat_min, set_npc_stat_max

v1.29d
>Added a fix for the print to file crash caused by fallouts inability to handle long filenames

v1.29c
>Expanded set_stat_max to work on most of the derived stats
>Added new script functions: set_stat_min, set_car_current_town

v1.29b
>A fix to the ammo damage tweak (from Glovz)
>Added new script function: set_stat_max

v1.29
>Added skilldex, inventory and automap flags to the game mode functions
>set_shader_mode now lets you set a list of excluded and required loops simultaniously
>Added new script function: get_uptime

v1.28c
>Glovz fixed a bug in his AP ammo mod.

v1.28b
>World map speed timer will revert to the normal timer if the high performance timer is low resolution
>Reduced the art cache size override setting

v1.28
>Added a fix for the skilldex button vanishing if you have many active quests and holodisks
>Added a fix for the gain xxx perks not giving all the bonuses that they should. (Will only effect new games)
>Updated the ap ammo mod (From Glovz)
>Hopefully fixed the issues with quickload
>sfall will display an error if you try running the win xp version in win 9x compatibility mode
>Added an option to override the art cache size, to fix F2RP EPA crashes without modifing fallout2.cfg
>Added new script functions: get_shader_texture, set_shader_texture

v1.27
>Added an override console option to fit more text into the console at high resolutions (Not finished!)
>Added a fix for saving/loading in combat with the bonus move perk
>Added an option to automatically set processor affinity to a single core
>sfall functions which expect a string as a parameter now accept variables as well as constants
>Global scripts set to run only on the local map no longer stop running in combat
>Improved the behaviour of set_shader_mode.
>Added new script functions: get_game_mode, force_graphics_refresh

v1.26
>Global script modes 2 or 3 no longer require the world map speed patch to be active to work 
>Added new script functions: get_ini_setting, set_shader_mode, get_shader_version
>Graphics mode 0 was broken in the win xp version of 1.25

v1.25
>Added the city limits patch
>You can now use hardware shaders in dx9 mode when using Mash's resolution patch. Software scalers will not be supported.
>Added new script functions set_xp_mod, set_perk_level_mod
>Graphics modes 1, 2 and 3 are no longer supported.

v1.24b
>Tweaked dx9 mode to be compatible with Mash's resolution patch. (Warning: Using very high resolutions in dx9 mode will be _slow_)

v1.24
>Added options for setting starting world map position and world map viewport
>Added new script functions: get_viewport_x, get_viewport_y, set_viewport_x, set_viewport_y

v1.23
>Added an option to remove the random element from npc levelling
>Added a new script function inc_npc_level

v1.22b
>EAX environment can be set on a per map basis via an eax.ini file.
>Tweaked the way the disable horrigan encounter option works. (Now only affects new games)

v1.22
>Added EAX support
>2 new script functions: eax_available, set_eax_environment
>Bug fixes to save/load/new game hooks (Most visible result is that global scripts no longer run on the main menu)

v1.21
>Added six new script functions: set_sfall_global, get_sfall_global_int, get_sfall_global_float, set_pickpocket_max, set_hit_chance_max and set_skill_max

v1.20c
>Fixed a crash if you set the height greater than the width using scale filter 6
>Fixed a crash bug in the combat_p_proc fix when critter_dmg was called. (From Ray)

v1.20b
>The global shader can declare a variable called rcpres which will recieve the reciprical screen resolution.
>All shaders can load up to 128 textures (e.g. add the lines 'string texname1="filename.bmp";' and 'texture tex1;' to load a texture from data\art\stex\filename.bmp)
>Two new ScaleFilter modes

v1.20
>Added an option to disable the horrigan encounter
>Added two new script functions set_global_script_type and available_global_script_types
>Added two additional execution modes for global scripts
>combat_p_proc fix (From Ray)
>Added an alternative damage calculation formula. (From Glovz)

v1.19b
>Fixed a crash introduced in 1.19a when gaining two levels at once

v1.19
>Tweaks to the way perks work when the script extender is being used: If you go more than 3 levels without visiting the character screen, you no longer loose your perk.
>set_perk_owed now accepts values up to 250, so you can give the player multiple perks in one go
>Updated the ammo patch (From Glovz)

v1.18f
>get_perk_owed will now return 1 as soon as the player levels up, rather than only after they have visted the character screen

v1.18e
>Added an option to modify the encounter rate
>Make use of a higher resolution counter for world map fps counting if one is available
>More bugfixes

v1.18b
>Added an option to make world map encounters independent of world map travel speed. (From Ray, from www.teamx.ru)
>Some bug fixes

v1.18
>Added an option to remove the ability to escape dialogue by hitting 0. (From Ray, from www.teamx.ru)
>Added new script functions: get_active_hand, toggle_active_hand, set_weapon_knockback, set_target_knockback, set_attacker_knockback, remove_weapon_knockback, remove_target_knockback, remove_attacker_knockback

v1.17c
>Made the world map speed patch independant of processor speed.

v1.17b
>Fixed some of the filter stuff that I managed to screw up...

v1.17
>Added an option to use Glovz's AP ammo patch
>Added some upscaling filters (From Dream, from www.fallout.ru)
>Fixed ForceEncounter preventing the encounter with horrigan if it was used to soon

v1.16d
>Added new script functions get/set_critter_current_ap
>Modified world map speed setting to work on copies of the fallout exe's without the speed patch already applied

v1.16c
>Added new script functions get_perk_owed, set_perk_owed, get_perk_available
>Fixed a bug in get_kill_counter function
>Fixed a few bugs introduced in 1.16b

v1.16b
>Added an option to double the number of available kill types
>Some performance tweaks

v1.16
>Added new script functions get_kill_counter and mod_kill_counter

v1.15
>Global scripts are now also loaded when the player starts a new game, instead of only when an existing game is loaded
>Added an option to enable the pipboy on game start
>Added a set_pipboy_available script function

v1.14
>Added the ability to modify perks
>19 new set_perk_xxx functions to modify perks ingame

v1.13c
>You can now change the limit on how far away from the player local maps can be scrolled

v1.13b
>Added the option to change the starting day/month/year
>Fixed a 1.13 bug which broke female players

v1.13
>You can now change the start and default player models
>You can now change the hardcoded in game movies
>Added new script functions (set_dm_model, set_df_model, set_movie_path)
>If you use the fallout2.exe included with killaps patch, sfall will no longer complain about an unsupported exe if you use the sharpshooter fix

v1.12b
>Added new script functions (get_world_map_x_pos, get_world_map_y_pos, set_world_map_pos)

v1.12
>You can change the number of locations displayed in the locations list of the world map
>A fix for the bug that could cause the world map locations list to become unresponsive
>You can tell fallout to use a patch file other than patch000.dat
>You can change the version string that appears in the bottom right of the main menu
>You can use command line args to tell sfall to use a ini file other than ddraw.ini

v1.11b
>Fixed a possible crash releated to trying to load global scripts that don't actually exist

v1.11
>Added the ability to tell fallout 2 to use a config file other than fallout.cfg
>Shaders now have access to the system tick count. (Create a non-static variable called 'tickcount')
>If using a dx9 mode, you can set up a key to toggle the global shader, and control when the shader gets used
>Added new script functions (in_world_map, force_encounter, set_shader_int, set_shader_float, set_shader_vector)

v1.10b
>Fixed a couple of issues with the dx9 graphics modes
>sfall no longer tries to load global scripts if you have the script extender turned off

v1.10
>Added an option to display debug messages in fallout, or to print them to the debug log
>Added the ability to create global scripts. (Scripts that run independently of the loaded map, and are not attached to any object)
>Added new script functions (set_global_script_repeat, input_funcs_available, key_pressed)
>When using a dx9 graphics mode with a non 640x480 resolution and with multiple shaders running, the screen is no longer distorted

v1.9c
>Fixed mistake in ddraw.ini's default settings

v1.9b
>Fixed possible lock-up bug when using graphics mode 4 or 5

v1.9
>If you use sfall with a version of fallout.exe that it wasn't built for, you get a useful error instead of the generic 'requires DirectX 3a' message
>If using a 16 bit colour mode, you can alter the speed of fades
>Added some extra graphics modes that use d3d9 for rendering instead of ddraw
>Can change the initial map to load when starting a new game
>Added some extra scripting functions. (game_loaded, graphics_funcs_available, load_shader, free_shader, activate_shader, deactivate_shader)

v1.8
>If using the pathfinder fix, you can modify how fast game time moves when travelling across the world map
>If using an exe with the world map speed tweak applied, you can change how fast you physically move across the map
>Added a new script function (get_year)
>Fixed a bug when setting TimeLimit=-3 that could cause crashes before reaching the 13 year limit

v1.7
>Added a fix for the pathfinder perk
>Added a new and improved fix for the 13 year time limit, that no longer results in the date wrapping around
>Added a new script function (tap_key)
>You can now set a key to toggle the speed tweak on and off

v1.6d
>Added some extra script functions. (get_critter_base_stat, get_critter_extra_stat, set_critter_base_stat and set_critter_extra_stat)
>Fixed parameter checking bug with set_pc_base_stat and set_pc_extra_stat
>get_pc_base_stat and get_pc_extra_stat now return 0 if an invalid stat id is given

v1.6c
>Fixed bug with get_pc_base_stat and get_pc_extra_stat returning incorrect values

v1.6b
>Added some extra script functions. (get_pc_base_stat, get_pc_extra_stat, set_pc_base_stat and set_pc_extra_stat)

v1.6
>Added an option to reduce mouse sensitivity below fallouts normal minimum.
>Added the option to use a 16 bit colour mode in fallout 2. (Windowed 16 bit is a lot faster than windowed 8 bit)
>Added the sharpshoot perk perception fix for fallout 2
>Made a few extra functions available to scripts. (read_byte, read_short, read_int and read_string)

v1.5c
>More bugfixes to the time limit adjuster.

v1.5b
>Slight bugfix to the time limit adjuster

v1.5
>Added an option to adjust the 13 year time limit in fallout 2
>Added an option to set the initial speed at game startup

v1.4
>Restructured source code so that it's easier to add support for different exe versions
>Created a new dll for the v1.2 US version of fallout 1

v1.3
>Added an option to bind the middle mouse button to a keyboard key. ('c' by default)
>Added a frameskip option when running in windowed mode.
>Fallout's DirectInput device is now used to control speed changes and any other keyboard input this mod requires, because GetAsyncKeyState is unreliable when DInput is in use
>Added an option to force DirectInput into background mode
>The mouse wheel scroll modifier can now be set to 0 to always scroll one click regardless of mouse and windows settings. (This is the new default.)

v1.2
>The whole gameplay speed section of the mod can now be disabled, while still allowing windowed mode
>Added an option to let you use the mouse scroll wheel to scroll through your inventory and save menu.

v1.1
>You no longer need to hex-edit fallout2.exe in order to get this mod working
>You can now edit the controls in ddraw.ini
>Added an additional option to run fallout in windowed mode

*************
** Credits **
*************

ravachol    For the sharpshooter perk fix.
Noid        For the debug patch
Glovz       For the AP ammo patch
Dream       For the upscaling filter code
Ray/Alray   For the active hand and dialogue fix memory addresses, the encounter rate patch,
              the combat_p_proc fix and the load multiple patch files option, and more
Kanhef      For the shiv item code address
KLIMaka     For the imported procedure fix
Mash        For the hero apperence mod and the extra save game slots
Helios      For the skilldex mouse cursor patch, a bunch of scripting functions and the window rounding option
Haenlomal   For another ammo patch, and lots of other stuff (See the changelog)