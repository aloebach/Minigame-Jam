# Minigame-Jam
Repository for the Minigame Jam!

This is based on the Mobware Minigames framework.

Designed for the Playdate, this framework will allow you to compile your own minigame and play it within the overarching minigame framework.

The minigame framework will load a minigame which is programmed similar to a normal playdate game. See the minigame template in the minigame folder for details!

To get started, clone the repository. 
In z-shell: `git clone https://github.com/aloebach/Minigame-Jam.git`

Rename and edit the `minigame_template` folder 
To compile and rule the minigame jame pdx use the following command in z-shell:
`pdc ./Minigame-Jam  minigame_jam.pdx && open minigame_jam.pdx`

Once you've cloned the repository open minigames/minigame-template, and follow the instructions from there! After you've set up your own minigame using the template, you can set the DEBUG_GAME variable in `main.lua` to the name of your minigame to test. Finally, once you've succesfully tested your new minigame, simply add it to the list in  `minigame_list.lua`, and you've successfully added your own game to the Moware Minigames framework!


#Minigame guidelines 
Minigames should not last longer 10s or so.
The minigame should be in its own folder under "minigames", and the <minigame_name> folder should have the same name as <minigame_name>.lua. all necessary files such a libraries, music and image files are contained within the individual minigame's folders, and the games can reference them accordingly. 
<minigame_name>.lua must contain <minigame_name>.update(), similar to playdate.update(), which is called every frame
Playdate's additional callback functions are supported, but will be named the <minigame_name> equivalent. 
  
<minigame_name>.update() should return a 1 if the player won, or a 0 if the player lost
credits.json should be in the minigame's root folder and contain the credits to be included in the game's final credits
credits.gif should be a Gif to be displayed for the minigame in the credits sequence, no larger than 180 x 180


#License information
Code for the Minigame-Jam is licensed under Creative Commons Attribution-NonCommercial 4.0 International license.
https://creativecommons.org/licenses/by-nc/4.0/

Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

NonCommercial — You may not use the material for commercial purposes. 
