package;

import base.Controls;
import base.ScriptHandler;
import base.debug.Overlay;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.Sprite;
import states.MusicBeatState;
import states.PlayState;
import states.ScriptableState;

class Main extends Sprite
{
	public static var initialState:Class<FlxState> = PlayState;
	public static var defaultFramerate:Int = 120;

	public static var engineVersion:String = '1.0.0';

	public static function main():Void
		Lib.current.addChild(new Main());

	public function new()
	{
		super();

		// initialize the controls of the engine
		Controls.init();
		// initialize the forever scripthandler
		ScriptHandler.initialize();

		// haxeui stuff
		haxe.ui.Toolkit.init();

		var gameCreate:FlxGame;
		gameCreate = new FlxGame(1280, 720, Init, 1, defaultFramerate, defaultFramerate, true, false);
		addChild(gameCreate);

		var overlay:Overlay;
		overlay = new Overlay(0, 0);
		addChild(overlay);
	}
}
