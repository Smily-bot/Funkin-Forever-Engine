package states;

import base.Controls;
import base.ScriptHandler.ForeverModule;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUISubState;

class ScriptableState extends FlxUIState
{
	public var scriptStack:Array<ForeverModule>;

	override function create()
	{
		super.create();
		Controls.onActionPressed.add(onActionPressed);
		Controls.onActionReleased.add(onActionReleased);
	}

	override function destroy()
	{
		Controls.onActionPressed.remove(onActionPressed);
		Controls.onActionReleased.remove(onActionReleased);
		super.destroy();
	}

	function onActionPressed(action:String) {}

	function onActionReleased(action:String) {}

	function stackAdd(newModule:ForeverModule)
	{
		if (newModule != null)
			scriptStack.push(newModule);
	}
}

class ScriptableSubState extends FlxUISubState
{
	override function create()
	{
		super.create();
		Controls.onActionPressed.add(onActionPressed);
		Controls.onActionReleased.add(onActionReleased);
	}

	override function destroy()
	{
		Controls.onActionPressed.remove(onActionPressed);
		Controls.onActionReleased.remove(onActionReleased);
		super.destroy();
	}

	function onActionPressed(action:String) {}

	function onActionReleased(action:String) {}
}
