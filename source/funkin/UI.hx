package funkin;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import states.PlayState;

class UI extends FlxSpriteGroup
{
	public function new()
	{
		super();

		// ui stuffs!
		var cornerMark:FlxText = new FlxText(0, 0, 0, 'FOREVER ENGINE v' + openfl.Lib.application.meta["version"] + '\n');
		cornerMark.setFormat(AssetManager.getAsset('vcr', FONT, 'fonts'), 18, FlxColor.WHITE);
		cornerMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(cornerMark);
		cornerMark.setPosition(FlxG.width - (cornerMark.width + 5), 5);
		cornerMark.antialiasing = true;

		if (PlayState.song != null)
		{
			var centerMark:FlxText = new FlxText(0, 0, 0, '- ${PlayState.song.name.toUpperCase()} -\n');
			centerMark.setFormat(AssetManager.getAsset('vcr', FONT, 'fonts'), 24, FlxColor.WHITE);
			centerMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
			add(centerMark);
			centerMark.y = FlxG.height / 24;
			centerMark.screenCenter(X);
			centerMark.antialiasing = true;
		}
	}
}
