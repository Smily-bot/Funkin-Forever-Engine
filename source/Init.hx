import flixel.FlxG;
import flixel.addons.ui.FlxUIState;

class Init extends FlxUIState
{
	override public function create()
	{
		super.create();

		// FlxG.autoPause = true;
		FlxG.fixedTimestep = false; // This ensures that the game is not tied to the FPS
		FlxG.mouse.useSystemCursor = true; // Use system cursor because it's prettier
		FlxG.mouse.visible = false; // Hide mouse on start

		FlxG.switchState(cast Type.createInstance(Main.initialState, []));
	}
}
