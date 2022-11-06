package funkin;

import base.Conductor.Timings;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import states.PlayState;

class UI extends FlxSpriteGroup
{
	public var scoreBar:FlxText;
	public var cornerMark:FlxText;
	public var centerMark:FlxText;

	public var healthbarBG:FlxSprite;
	public var healthbar:FlxBar;

	public function new()
	{
		super();

		// ui stuffs!
		var cornerMark:FlxText = new FlxText(0, 0, 0, 'FOREVER ENGINE v' + Main.engineVersion + '\n');
		cornerMark.setFormat(AssetManager.getAsset('vcr', FONT, 'fonts'), 18, FlxColor.WHITE);
		cornerMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(cornerMark);
		cornerMark.setPosition(FlxG.width - (cornerMark.width + 5), 5);
		cornerMark.antialiasing = true;

		if (PlayState.song != null)
		{
			centerMark = new FlxText(0, 0, 0, '- ${PlayState.song.name.toUpperCase()} -\n');
			centerMark.setFormat(AssetManager.getAsset('vcr', FONT, 'fonts'), 24, FlxColor.WHITE);
			centerMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
			add(centerMark);
			centerMark.y = FlxG.height / 24;
			centerMark.screenCenter(X);
			centerMark.antialiasing = true;
		}

		var barY:Float = FlxG.height * 0.875;
		if (PlayState.downscroll)
			barY = FlxG.height - barY;
		// generate healthbar
		healthbarBG = new FlxSprite(0, barY).loadGraphic(AssetManager.getAsset('ui/default/healthBar', IMAGE, 'images'));
		healthbarBG.screenCenter(X);
		healthbarBG.scrollFactor.set();
		add(healthbarBG);

		healthbar = new FlxBar(healthbarBG.x + 4, healthbarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthbarBG.width - 8), Std.int(healthbarBG.height - 8));
		healthbar.scrollFactor.set();
		// healthbar.blend = BlendMode.MULTIPLY; I have to do this someday
		healthbar.createFilledBar(0xFFFF0048, 0xFF33FF5F - 0xFFFF0048);
		healthbar.percent = 50;
		add(healthbar);

		scoreBar = new FlxText(FlxG.width / 2, Math.floor(healthbarBG.y + 40), 0, "FRIDAY NIGHT FUNKIN LOLLL\n");
		scoreBar.setFormat(AssetManager.getAsset('vcr', FONT, 'fonts'), 18, FlxColor.WHITE);
		scoreBar.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		updateScoreText();
		scoreBar.scrollFactor.set();
		scoreBar.antialiasing = true;
		add(scoreBar);
	}

	public static var divider:String = " • ";

	public function updateScoreText()
	{
		var newText:String = '';
		newText += 'Score: ${Timings.score}' + divider;
		newText += 'Accuracy: ${Timings.returnAccuracy()}' + divider;
		newText += 'Combo Breaks: ${Timings.misses}' + divider;
		newText += 'Rank: S';
		//
		newText += '\n';
		if (scoreBar.text != newText)
			scoreBar.text = newText;
		scoreBar.screenCenter(X);
	}
}
