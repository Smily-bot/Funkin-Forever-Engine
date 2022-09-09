package funkin;

import AssetManager.EngineImplementation;
import base.ScriptHandler;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.ds.StringMap;
import states.PlayState;

class Stage extends FlxTypedGroup<FlxBasic>
{
	public var defaultCamZoom(never, set):Float;

	function set_defaultCamZoom(value:Float):Float
	{
		cameraZoom = value;
		return cameraZoom;
	}

	public var cameraZoom:Float = 1;
	public var stageBuild:ForeverModule;

	public function new(stage:String, engineImplementation:EngineImplementation)
	{
		super();
		switch (engineImplementation)
		{
			case FNF:

			case PSYCH:

			case FOREVER:
				var exposure:StringMap<Dynamic> = new StringMap<Dynamic>();
				exposure.set('add', add);
				exposure.set('stage', this);
				stageBuild = ScriptHandler.loadModule('stage', 'stages/$stage', exposure);
				if (stageBuild.exists("onCreate"))
					stageBuild.get("onCreate")();
				trace('$stage loaded successfully');
			default:
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (stageBuild.exists("onUpdate"))
			stageBuild.get("onUpdate")(elapsed);
	}
}
