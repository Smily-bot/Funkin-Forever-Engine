package states.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import openfl.display.BlendMode;

typedef Category =
{
	var name:String;
}

class OptionsMenu extends MusicBeatState
{
	var topBar:FlxSprite;
	var bottomBar:FlxSprite;
	var topMarker:FlxText;
	var rightMarker:FlxText;

	public var categories:Array<Category> = [
		{name: 'GAMEPLAY'},
		{name: 'CONTROLS'},
		{name: 'VISUALS'},
		{name: 'ACCESSIBILITY'},
		{name: 'FOREVER'},
		{name: 'EXIT'},
	];
	public var categoryList:Array<FlxText> = [];

	override public function create()
	{
		super.create();

		generateBackground();

		topBar = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		topBar.setGraphicSize(FlxG.width, 48);
		topBar.updateHitbox();
		topBar.screenCenter(X);

		bottomBar = new FlxSprite().loadGraphic(topBar.graphic);
		bottomBar.setGraphicSize(FlxG.width, 48);
		bottomBar.updateHitbox();
		bottomBar.screenCenter(X);

		// create categories
		for (i in 0...categories.length)
		{
			var category:FlxText = new FlxText(0, 0, 720,
				categories[i].name + '\n').setFormat(AssetManager.getAsset('splatter', FONT, 'fonts'), 96, FlxColor.fromRGB(155, 155, 155));
			category.setBorderStyle(OUTLINE, FlxColor.BLACK, 5);
			category.blend = BlendMode.MULTIPLY;
			category.screenCenter();
			category.y += 16 + ((i + 1) - categories.length / 2) * 96;
			categoryList.push(category);
			add(category);
		}

		add(topBar);
		topBar.y -= topBar.height;
		add(bottomBar);
		bottomBar.y += FlxG.height;

		topMarker = new FlxText(8, 8, 0, "SETTINGS").setFormat(AssetManager.getAsset('vcr', FONT, 'fonts'), 32, FlxColor.WHITE);
		add(topMarker);

		rightMarker = new FlxText(8, 8, 0, "FRIDAY NIGHT FUNKIN': FOREVER").setFormat(AssetManager.getAsset('vcr', FONT, 'fonts'), 32, FlxColor.WHITE);
		rightMarker.x += FlxG.width - (rightMarker.width + 16);
		add(rightMarker);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		topBar.y = FlxMath.lerp(topBar.y, 0, elapsed * 6);
		bottomBar.y = FlxMath.lerp(bottomBar.y, FlxG.height - bottomBar.height, elapsed * 6);

		topMarker.y = topBar.y + 4;
	}

	var gridBackground:FlxTiledSprite;

	function generateBackground()
	{
		var background:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			[FlxColor.fromRGB(255, 158, 214), FlxColor.fromRGB(192, 41, 71)]);
		add(background);

		gridBackground = new FlxTiledSprite(AssetManager.getAsset('menus/options/gridPink', IMAGE, 'images'), FlxG.width, FlxG.height);
		add(gridBackground);

		// dark background
		var funkyBack:FlxSprite = new FlxSprite().loadGraphic(AssetManager.getAsset('menus/bg', IMAGE, 'images'));
		funkyBack.setGraphicSize(Std.int(FlxG.width));
		funkyBack.scrollFactor.set();
		funkyBack.blend = BlendMode.MULTIPLY;
		funkyBack.screenCenter();
		funkyBack.alpha = 0.4;
		add(funkyBack);
	}
}
