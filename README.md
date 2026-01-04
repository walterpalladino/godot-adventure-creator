
## Adventure

**Key Features:**

1.  **Old-style text commands**: Look, Inventory, Move (north/south/east/west), Take item, Use item
2.  **Random objectives**: The game randomly selects from:
	-   Find items (Ancient Amulet, Golden Key, etc.)
	-   Rescue characters (Princess Elena, Professor Smith, etc.)
	-   Activate artifacts (Ancient Portal, Sacred Altar, etc.)
3.  **Item-based room requirements**: Some rooms require specific items (like keys) to enter
4.  **Adventure validation**: The game tests if the adventure is completable before letting you play. It attempts up to 10 times to generate a solvable adventure.
5.  **Meaningful items**: All items have defined uses in the `item_uses` dictionary
6.  **Connected rooms**: Minimum 5 rooms (configurable via `MIN_ROOMS`) with bidirectional connections

**To use in Godot 4:**

1.  Create a new Control node scene
2.  Add this structure:
	-   VBoxContainer
		-   ScrollContainer → RichTextLabel (name: OutputText)
		-   HBoxContainer
			-   LineEdit (name: InputField)
			-   Button (name: SendButton, text: "Send")
3.  Attach this script to the root Control node
4.  Run the scene!

The game will automatically generate a completable adventure or notify you if it fails after 10 attempts. Players navigate rooms, collect items, unlock doors, and complete objectives like a classic text adventure!

## Prompt

*Create an Godot 4 program using gdscript that do the next: - Old Style Text Adventure interaction using actions like: Look, Inventory, Move in a direction, Use item, etc - There should be a general objective for the adventure which will be created at the start of the game. An example will be found or recover an item, save another character, activate an ancient artifact, etc. - There should be pre made objectives and at the begining of the adventure will one be picked. As a placeholder should be a list of items to recover or characters to rescue or ancient artifacts to activate. Could be usefull using a dictionary using the key as type of objective an the value an array of possible options. - There should be based on rooms connected. Some rooms will require the player having some item in its inventory to enter that room like a key or a passcode. The game should include a minmum number of rooms whcih should be configurable. The game should include a Dictionary including item as a key and as value a list of possible uses for that item. - All the pickable items should have a meaning for the adventure. - Previous to offer the adventure to the player, should be a method that allows to test is it is possible to complete the adventure moving between rooms and picking the required items and check the adventure can be completed. If pass, then allow to be played it. If can not be completed try again up to a number configurable of times. If can not be found a solution, inform it and stop allowing to start a new adventure. - An example adventure could be Mistery Mansion like wehre the player tarverse rooms opening doors and looking for clues on furniture to found the exit of the mansion.*
