package states.editors;

import base.ChartParser;
import base.Conductor;
import base.ScriptHandler;
import base.debug.HaxeUIOverlay;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import funkin.Note;
import funkin.Strumline;
import haxe.ui.RuntimeComponentBuilder;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import sys.io.File;
import sys.thread.Mutex;
import sys.thread.Thread;

typedef CharterSection =
{
	var header:FlxSprite;
	var numbers:Array<FlxText>;
	var body:Array<FlxSprite>;
}

typedef CharterNote =
{
	var holdLength:Float;
	var hold:FlxTiledSprite;
	var end:Note;
}

class ChartEditor extends MusicBeatState
{
	public var checkerboard:FlxGraphic;
	public var line:FlxGraphic;
	public var sectionLine:FlxGraphic;
	public var cellSize:Int = 50;

	public var keyAmount:Int = 4;
	public var strumlines:Int = 2;

	public var receptorGroup:FlxTypedGroup<Strumline>;

	public var chartCamera:FlxCamera;
	public var chartHUD:FlxCamera;

	public var camObject:FlxObject;

	static var _song:SongFormat = null; // local song format

	public var difficultySelected:Int;

	override public function create()
	{
		super.create();

		chartCamera = new FlxCamera();
		FlxG.cameras.reset(chartCamera);
		FlxCamera.defaultCameras = [chartCamera];

		chartHUD = new FlxCamera();
		chartHUD.bgColor.alpha = 0;
		FlxG.cameras.add(chartHUD);

		generateBackground();
		reloadSong();
		generateUI();

		FlxG.mouse.visible = true;
		FlxG.mouse.useSystemCursor = true;

		var ui:HaxeUIOverlay = new HaxeUIOverlay('chart-editor', 'images/menus/chart');
		add(ui);
	}

	public var conductorCrochet:FlxSprite;

	var gridBackground:FlxTiledSprite;
	var boardPattern:FlxTiledSprite;

	public var sectionGroup:FlxTypedGroup<FlxSprite>;
	public var sectionsList:Array<CharterSection> = [];
	public var holdsGroup:FlxTypedGroup<FlxSprite>;
	public var holdsMap:Map<Note, CharterNote> = [];
	public var notesGroup:FlxTypedGroup<Note>;

	public var holdGraphics:Array<FlxGraphic> = [];

	public var chartZoom:Float = 1;

	function generateBackground()
	{
		gridBackground = new FlxTiledSprite(AssetManager.getAsset('menus/chart/gridPurple', IMAGE, 'images'), FlxG.width, FlxG.height);
		gridBackground.cameras = [chartCamera];
		add(gridBackground);

		var background:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			[FlxColor.fromRGB(167, 103, 225), FlxColor.fromRGB(137, 20, 181)]);
		background.alpha = 0.6;
		background.cameras = [chartCamera];
		add(background);

		// dark background
		var darkBackground:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		darkBackground.setGraphicSize(Std.int(FlxG.width));
		darkBackground.cameras = [chartCamera];
		darkBackground.scrollFactor.set();
		darkBackground.screenCenter();
		darkBackground.alpha = 0.7;
		add(darkBackground);

		// dark background
		var funkyBack:FlxSprite = new FlxSprite().loadGraphic(AssetManager.getAsset('menus/chart/bg', IMAGE, 'images'));
		funkyBack.setGraphicSize(Std.int(FlxG.width));
		funkyBack.cameras = [chartCamera];
		funkyBack.scrollFactor.set();
		funkyBack.blend = BlendMode.DIFFERENCE;
		funkyBack.screenCenter();
		funkyBack.alpha = 0.07;
		add(funkyBack);

		// checkerboard pattern
		@:privateAccess
		checkerboard = new FlxGraphic('board$cellSize',
			FlxGridOverlay.createGrid(cellSize, cellSize, cellSize * 2, cellSize * 2, true, FlxColor.WHITE, FlxColor.BLACK), true);
		checkerboard.bitmap.colorTransform(new Rectangle(0, 0, cellSize * 2, cellSize * 2), new ColorTransform(1, 1, 1, 0.20));

		line = FlxG.bitmap.create(cellSize * keyAmount * strumlines, 1, FlxColor.WHITE, true, 'chartline');
		sectionLine = FlxG.bitmap.create((cellSize * keyAmount * strumlines) + 8, 2, FlxColor.WHITE, true, 'sectionline');

		// set the default camera to the hud after the bg lol
		FlxCamera.defaultCameras = [chartHUD];

		// temp checkerboard
		boardPattern = new FlxTiledSprite(checkerboard, cellSize * keyAmount * strumlines, cellSize * 16);
		boardPattern.screenCenter(X);
		add(boardPattern);

		sectionGroup = new FlxTypedGroup<FlxSprite>();
		add(sectionGroup);

		holdsGroup = new FlxTypedGroup<FlxSprite>();
		add(holdsGroup);

		notesGroup = new FlxTypedGroup<Note>();
		add(notesGroup);

		conductorCrochet = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		conductorCrochet.setGraphicSize(Std.int((cellSize * keyAmount * strumlines) + cellSize), 2);
		conductorCrochet.screenCenter(X);
		conductorCrochet.y = cellSize / 2;
		add(conductorCrochet);

		receptorGroup = new FlxTypedGroup<Strumline>();
		for (i in 0...strumlines)
		{
			var strumline:Strumline = new Strumline(boardPattern.x + ((cellSize * keyAmount) * i) + ((cellSize * keyAmount) / 2), (cellSize / 2) + 2,
				"default", false, false, [], [], (cellSize / 160));
			strumline.alpha = 0.75;
			receptorGroup.add(strumline);
		}
		add(receptorGroup);

		camObject = new FlxObject();
	}

	public function initHoldSprites()
	{
		for (strumline in receptorGroup)
		{
			for (i in 0...strumline.receptors.members.length)
			{
				//
				var noteHold:Note = new Note(0, i, strumline.receptors.members[i].noteType, i, true, null);
				var noteEnd:Note = new Note(0, i, strumline.receptors.members[i].noteType, i, true, noteHold);

				// do not use the note end (its a lot easier to establish ends)
				trace('curr hold note $i is ${noteHold.animation.frameName}');
				var frame:FlxFrame = noteHold.frames.framesHash.get(noteHold.animation.frameName);
				var graphic:FlxGraphic = FlxGraphic.fromFrame(frame);
				graphic.persist = true;
				// @:privateAccess
				// graphic.bitmap.height -= 16;
				holdGraphics.push(graphic);

				noteEnd.destroy();
				noteHold.destroy();
				//
			}
		}
	}

	public function regenSections()
	{
		for (i in sectionGroup)
			i.destroy();
		sectionGroup.clear();

		// generate sections
		for (i in 0...Std.int((Conductor.boundSong.length / Conductor.stepCrochet) / 16))
		{
			// generate header
			var lineSprite:FlxSprite = new FlxSprite(0, 0, sectionLine);
			lineSprite.alpha = 0.45;
			sectionGroup.add(lineSprite);
			var thisSection:CharterSection = {header: lineSprite, body: [], numbers: []};

			// generate text
			for (j in 0...2)
			{
				var sectionNumbers:FlxText = new FlxText().setFormat(AssetManager.getAsset('vcr', FONT, 'fonts'), 16, FlxColor.WHITE);
				sectionNumbers.alpha = 0.45;
				thisSection.numbers.push(sectionNumbers);
				sectionGroup.add(sectionNumbers);
			}

			// generate lines
			for (j in 1...4)
			{
				var thinLine:FlxSprite = new FlxSprite(0, 0, line);
				thinLine.alpha = 0.75;
				thisSection.body.push(thinLine);
				sectionGroup.add(thinLine);
			}
			sectionsList.push(thisSection);
		}
	}

	public var noteMutex:Mutex = new Mutex();

	public function getPositionHorizontal(noteStrumline:Int, noteData:Int)
	{
		var returnPos:Int = 0;
		for (i in 0...noteStrumline + 1)
		{
			for (j in 0...receptorGroup.members[i].receptorData.keyAmount)
			{
				if (i == noteStrumline && j == noteData)
					return returnPos;
				returnPos++;
			}
		}
		return returnPos;
	}

	public function regenNotes()
	{
		for (i in notesGroup)
			i.destroy();
		notesGroup.clear();

		Thread.create(function()
		{
			noteMutex.acquire();
			for (unspawnNote in _song.notes)
			{
				//
				var note:Note = new Note(unspawnNote.stepTime, unspawnNote.index, unspawnNote.type, unspawnNote.strumline);
				note.setGraphicSize(cellSize, cellSize);
				note.updateHitbox();
				note.active = false;
				note.visible = false;
				notesGroup.add(note);

				if (unspawnNote.holdStep > 0)
				{
					// holds!!!
					var curIndex:Int = getPositionHorizontal(unspawnNote.strumline, unspawnNote.index);
					// get receptor data
					var receptorData:ReceptorData = receptorGroup.members[unspawnNote.strumline].receptorData;
					var resize:Float = (cellSize / receptorData.separation);
					// trace('current hold index: $curIndex, graphic ${holdGraphics[curIndex]}'); // COME BACK TO THIS
					var hold:FlxTiledSprite = new FlxTiledSprite(holdGraphics[curIndex], cellSize, cellSize * unspawnNote.holdStep);
					hold.width = hold.graphic.width * resize;
					hold.scale.set(resize, cellSize);
					hold.active = false;
					hold.visible = false;
					holdsGroup.add(hold);

					var end:Note = new Note(0, unspawnNote.index, unspawnNote.type, unspawnNote.strumline, true);
					end.scale.set(resize, resize);
					end.updateHitbox();
					end.active = false;
					end.visible = false;
					holdsGroup.add(end);

					holdsMap.set(note, {holdLength: unspawnNote.holdStep, hold: hold, end: end});
				}
				//
			}
			trace('finished generating notes');
			noteMutex.release();
		});
	}

	public function reloadSong()
	{
		// bound song stuff
		if (PlayState.song != null)
			_song = PlayState.song;
		else
			_song = {
				name: 'test',
				rawName: 'test',
				bpm: 100,
				speed: 1,
				events: [],
				cameraEvents: [],
				notes: [],
			};

		if (Math.isNaN(difficultySelected))
			difficultySelected = PlayState.difficulty;

		var rawDirectory:String = AssetManager.getPath(_song.name, 'songs', DIRECTORY);
		Conductor.bindSong(this, AssetManager.returnSound('$rawDirectory/Inst.ogg'), _song.bpm, [AssetManager.returnSound('$rawDirectory/Voices.ogg')]);

		regenSections();
		initHoldSprites();
		regenNotes();
	}

	public var uiCornerBar:FlxText;

	public function generateUI()
	{
		uiCornerBar = new FlxText(0, 0, 512, returnCornerStats());
		uiCornerBar.setFormat(AssetManager.getAsset('vcr', FONT, 'fonts'), 24, FlxColor.WHITE);
		// uiCornerBar.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(uiCornerBar);
		uiCornerBar.scrollFactor.set();
		uiCornerBar.setPosition(4, FlxG.height - (uiCornerBar.height + 4) + 24);
		uiCornerBar.antialiasing = true;
	}

	public function returnCornerStats():String
	{
		return 'STEP: ${FlxMath.roundDecimal(Conductor.songPosition / Conductor.stepCrochet, 2)}\n'
			+ 'BEAT: ${FlxMath.roundDecimal(Conductor.songPosition / Conductor.crochet, 2)}\n'
			+ 'TIME: ${FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)} / ${FlxMath.roundDecimal(Conductor.boundSong.length / 1000, 2)}\n'
			+ 'BPM: ${_song.bpm}\n\n'
			+ 'Zoom: ${chartZoom}\n'
			+ 'Rate: ${Conductor.rate}\n';
	}

	public var totalElapsed:Float = 0;
	public var lastTiming:Float = 0;

	override public function update(elapsed:Float)
	{
		// set song time stuff lol
		uiCornerBar.text = returnCornerStats();
		if (FlxG.keys.justPressed.SPACE)
		{
			if (Conductor.boundSong.playing)
			{
				Conductor.boundSong.pause();
				Conductor.boundVocals.pause();
			}
			else
			{
				lastTiming = Conductor.songPosition;
				Conductor.boundSong.play();
				Conductor.boundVocals.play();
			}
		}

		if (FlxG.keys.justPressed.ENTER)
		{
			FlxG.mouse.visible = false;
			FlxG.mouse.useSystemCursor = false;
			FlxG.switchState(new PlayState());
		}

		var modifier:Int = (FlxG.keys.pressed.SHIFT ? 2 : 1);
		var vertical:Int = (FlxG.keys.pressed.UP ? -1 : 0) + (FlxG.keys.pressed.DOWN ? 1 : 0);
		if (vertical != 0)
		{
			Conductor.boundSong.pause();
			Conductor.boundVocals.pause();
			Conductor.boundSong.time += vertical * modifier * (cellSize / 4) * (elapsed / (1 / 120));
			Conductor.boundVocals.time = Conductor.boundSong.time;
		}

		if (FlxG.mouse.wheel != 0)
		{
			if (FlxG.keys.pressed.CONTROL)
			{
				chartZoom += (FlxG.mouse.wheel * 0.1);
				chartZoom = Math.min(3, chartZoom);
				chartZoom = Math.max(0.5, chartZoom);
				chartZoom = FlxMath.roundDecimal(chartZoom, 2);
			}
			else
			{
				Conductor.boundSong.pause();
				Conductor.boundVocals.pause();

				var formula:Float = ((Conductor.stepCrochet * 0.5 * (modifier / 2)) / chartZoom);
				Conductor.boundSong.time -= (FlxG.mouse.wheel * formula) * (elapsed / (1 / 120));
				Conductor.boundSong.time = Math.round((Conductor.boundSong.time / (formula))) * formula;
				Conductor.boundVocals.time = Conductor.boundSong.time;
			}
		}

		if (!Conductor.boundSong.playing)
			Conductor.songPosition = Conductor.boundSong.time;

		// /*
		if (FlxG.keys.pressed.LEFT)
			Conductor.rate += 0.01;
		else if (FlxG.keys.pressed.RIGHT)
			Conductor.rate -= 0.01;
		//  */

		super.update(elapsed);

		if (Conductor.songPosition < 0)
		{
			Conductor.boundSong.time = 0;
			Conductor.songPosition = 0;
		}

		// scale boardpattern
		boardPattern.scale.y = chartZoom;
		boardPattern.height = ((Conductor.boundSong.length / Conductor.stepCrochet) * cellSize) * chartZoom;

		// /*
		conductorCrochet.y = getYFromStep(Conductor.songPosition / Conductor.stepCrochet) + (cellSize * 0.5);
		for (strumline in receptorGroup)
			strumline.y = conductorCrochet.y - (cellSize * 0.5);

		for (i in 0...sectionsList.length)
		{
			var mySection:CharterSection = sectionsList[i];
			if (getYFromStep(i * 16) <= chartHUD.scroll.y - chartHUD.height || getYFromStep(i * 16) >= chartHUD.scroll.y + chartHUD.height)
			{
				if (mySection.header.visible)
				{
					mySection.header.visible = false;
					mySection.numbers[0].visible = false;
					mySection.numbers[1].visible = false;
					for (j in 0...mySection.body.length)
						mySection.body[j].visible = false;
				}
				// continue;
			}
			var displacement:Float = getYFromStep(i * 16);
			mySection.header.setPosition(boardPattern.x + boardPattern.width / 2 - mySection.header.width / 2, boardPattern.y + displacement);
			mySection.header.visible = true;
			// numbers
			mySection.numbers[0].text = '$i';
			mySection.numbers[0].setPosition(mySection.header.x - mySection.numbers[0].width - 8, mySection.header.y - mySection.numbers[0].height / 2);
			mySection.numbers[0].visible = true;
			mySection.numbers[1].text = '$i';
			mySection.numbers[1].setPosition(mySection.header.x + mySection.header.width + 8, mySection.header.y - mySection.numbers[0].height / 2);
			mySection.numbers[1].visible = true;

			for (j in 0...mySection.body.length)
			{
				var segment = mySection.body[j];
				segment.setPosition(boardPattern.x + boardPattern.width / 2 - segment.width / 2, boardPattern.y + getYFromStep(i * 16 + ((j + 1) * 4)));
				segment.visible = true;
			}
		}
		// */

		if (noteMutex.tryAcquire())
		{
			for (daNote in notesGroup)
			{
				if (getYFromStep(daNote.stepTime) <= chartHUD.scroll.y - chartHUD.height
					|| getYFromStep(daNote.stepTime) >= chartHUD.scroll.y + chartHUD.height)
				{
					if (daNote != null)
						daNote.visible = false;
					// continue;
				}
				daNote.visible = true;
				daNote.x = boardPattern.x + getPositionHorizontal(daNote.strumline, daNote.noteData) * cellSize;
				daNote.y = getYFromStep(daNote.stepTime);

				// behavior :)
				if (Conductor.boundSong.playing)
				{
					if (daNote.stepTime >= lastTiming / Conductor.stepCrochet
						&& daNote.stepTime <= (Conductor.songPosition / Conductor.stepCrochet)
						&& lastTiming >= (Conductor.songPosition / Conductor.stepCrochet))
					{
						// confirm animation (this is so fucking funny)
						receptorGroup.members[daNote.strumline].receptors.members[daNote.noteData].playAnim('confirm');
						lastTiming = daNote.stepTime * Conductor.stepCrochet;
					}
				}
			}

			for (note in holdsMap.keys())
			{
				if (note != null)
				{
					if (getYFromStep(note.stepTime + holdsMap[note].holdLength) <= chartHUD.scroll.y - chartHUD.height
						|| getYFromStep(note.stepTime) >= chartHUD.scroll.y + chartHUD.height)
					{
						if (holdsMap[note].hold.visible)
						{
							if (holdsMap[note].hold != null)
								holdsMap[note].hold.visible = false;
							if (holdsMap[note].end != null)
								holdsMap[note].end.visible = false;
						}
						// continue;
					}

					holdsMap[note].hold.visible = true;
					holdsMap[note].end.visible = holdsMap[note].hold.visible;

					holdsMap[note].hold.x = boardPattern.x
						+ getPositionHorizontal(note.strumline, note.noteData) * cellSize
						+ (note.width / 2 - holdsMap[note].hold.width / 2);
					holdsMap[note].hold.y = getYFromStep(note.stepTime) + cellSize / 2;

					holdsMap[note].hold.height = ((cellSize * holdsMap[note].holdLength) * chartZoom) - (cellSize * (1 - chartZoom));

					holdsMap[note].end.x = boardPattern.x
						+ getPositionHorizontal(note.strumline, note.noteData) * cellSize
						+ (note.width / 2 - holdsMap[note].end.width / 2);
					holdsMap[note].end.y = holdsMap[note].hold.y + holdsMap[note].hold.height;

					// /*
					if (holdsMap[note].hold.alive && Conductor.boundSong.playing)
					{
						var conductorPos:Float = getYFromStep(Conductor.songPosition / Conductor.stepCrochet);
						if (conductorPos >= holdsMap[note].hold.y
							&& conductorPos <= holdsMap[note].hold.y + holdsMap[note].hold.height + holdsMap[note].end.height)
						{
							// confirm animation (this is so fucking funny)
							receptorGroup.members[note.strumline].receptors.members[note.noteData].playAnim('confirm');
						}
					}
					//  */
				}
				//
			}
		}

		// clear receptors
		for (i in receptorGroup)
		{
			for (receptor in i.receptors)
			{
				if (receptor.animation.finished)
					receptor.playAnim('static');
			}
		}

		//
		camObject.screenCenter(X);
		camObject.y = conductorCrochet.y + (cellSize * 4);
		//
		chartHUD.follow(camObject, FlxCameraFollowStyle.LOCKON);

		gridBackground.scrollX += (elapsed / (1 / 60)) * 0.5;
		var increaseUpTo:Float = gridBackground.height / 8;
		gridBackground.scrollY = Math.sin(totalElapsed / increaseUpTo) * increaseUpTo;
		totalElapsed += (elapsed / (1 / 60)) * 0.5;
	}

	inline public function getYFromStep(step:Float = 0):Float
	{
		return step * cellSize * chartZoom;
	}
}
