## File structure: VERY IMPORTANT
- ALL FOLDERS MUST BE LOWERCASE
- Scene and script names names should be in `snake_case`
- If you rename or move anything, do it in the Godot editor (not your file system) otherwise you may mess up dependencies.

Here's the general file structure we'll be using as a reference. 
No strict rules, this is just a general guideline.
```
/
	assets/
		player.png
	data/
		lvl_data.gd     # resource template
		lvl_1_data.tres
	resources/
		character.tres
	globals/ #used as autoloads
		notifications.tscn
		lobby.tscn
		serialization.tscn
	menus/ #for scenes that are used standalone 2d menus, or popups
		title/
			title.tscn
			font_title.tres
	ui/ #for any assets related to UI that are reused
		theme_default/
			assets/
				[...] #generally pngs for interface
			theme_default.tres
		font_uidefault.tres
		cool_font.ttf
	scenes/ #scenes where a player will probably be instantiated
		entities/
			player/
				player.tscn
				player.gd
			enemies/
				generic_enemy.gd
				enemy.tscn #base scene to be overridden
				boss_enemy.gd
				boss.tscn #base scene to be overridden
			actor.tscn
			actor.tres
			actor.gd
		 common/
			 assets/
				 [...]
			 prefabs/ #premade designs for inclusion in a level elsewhere
				 [...].tscn
			 common_gridmap.tres
		 main/
			 assets/
				 [...]
			 main.tscn
			 [...]
		 overworld/
			 assets/
				 [...]
			 overworld.tscn
			 [...]
		 dungeon/
			 assets/
				 [...]
			 dungeon.tscn
			 [...]
```

## Resources
[Official Godot Docs](https://docs.godotengine.org/en/stable/getting_started/first_2d_game/index.html#)

[Using Composition in Godot](https://www.youtube.com/watch?v=74y6zWZfQKk)

[Git cheat sheet ](https://education.github.com/git-cheat-sheet-education.pdf)

[Call down signal up](https://www.reddit.com/r/godot/comments/vodp2a/comment/iegv4fs/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)


## Setup Instructions
1. Clone the repo
2. Download latest Godot (4.7.1) [here](https://godotengine.org/download/), and extract it, giving you the Godot executable. **Everyone should have the latest version otherwise it might create conflicts anytime you save a scene.** 
	a. You can consider using the [godotenv version manager](https://github.com/chickensoft-games/godotenv) which allows you to switch between versions with less hassle
3. Open Godot then click `Import` and select the project repo folder.

### VSCode setup (if you prefer to use it)
1.  If you are using VSCode, install the godot-tools extension
	a. You may be prompted to provide the godot executable path. On windows you can find this by right-clicking Godot and clicking "Go to file location"
2. Set VSCode as your default editor in Godot (if using VSCode)
	1. Go to `Editor > Editor Settings` on the menu bar
	2. Go to `External` under the `Text Editor` section and check the `Use External Editor` box
	3. In exec path put your VSCode executable Path (On Windows you should be able to right click the VSCode app and click "Go to file location"). If you paste in the path make sure to remove any quotes because otherwise it won't work.
3. If you create a script then double-click it in the editor, it should open in VSCode!
