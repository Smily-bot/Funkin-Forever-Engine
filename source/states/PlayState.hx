package states;

import base.ChartParser;
import base.ChartParser;
import base.Conductor;
import base.Controls;
import base.ForeverDependencies.ForeverSprite;
import base.MusicSynced.CameraEvent;
import base.MusicSynced.UnspawnedNote;
import base.ScriptHandler;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.Character;
import funkin.Note;
import funkin.Stage;
import funkin.Strumline.Receptor;
import funkin.Strumline;
import funkin.UI;
import openfl.media.Sound;
import states.editors.ChartEditor;

using StringTools;

class PlayState extends MusicBeatState
{
	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;

	public static var cameraSpeed:Float = 1;

	public static var camGame:FlxCamera;
	public static var camHUD:FlxCamera;
	public static var ui:UI;

	public var boyfriend:Character;
	public var dad:Character;

	var strumlines:FlxTypedGroup<Strumline>;

	public var judgementGroup:FlxTypedGroup<ForeverSprite>;
	public var comboGroup:FlxTypedGroup<ForeverSprite>;

	public var dadStrums:Strumline;
	public var bfStrums:Strumline;

	public var controlledStrumlines:Array<Strumline> = [];

	public static var song(default, set):SongFormat;
	public static var difficulty:Int = 1;

	static function set_song(value:SongFormat):SongFormat
	{
		// preloading song notes & stuffs
		if (value != null && song != value)
		{
			song = value;

			// song values
			songSpeed = song.speed;

			uniqueNoteStash = [];
			for (i in song.notes)
			{
				if (!uniqueNoteStash.contains(i.type))
					uniqueNoteStash.push(i.type);
			}

			// load in note stashes
			Note.scriptCache = new Map<String, ForeverModule>();
			Note.dataCache = new Map<String, ReceptorData>();
			for (i in uniqueNoteStash)
			{
				Note.scriptCache.set(i, Note.returnNoteScript(i));
				Note.dataCache.set(i, Note.returnNoteData(i));
			}
			song = ChartParser.parseChart(song);
		}
		return song;
	}

	public static var uniqueNoteStash:Array<String> = [];

	override public function create()
	{
		super.create();
		Timings.resetScore();

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);
		FlxCamera.defaultCameras = [camGame];
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD);

		song = ChartParser.loadChart(this, "philly-nice", difficulty, FNF_LEGACY);
		stackAdd(ScriptHandler.loadModule(song.rawName + ChartParser.difficultyMap[difficulty][0], 'songs/${song.rawName}'));

		// add stage
		var stage:Stage = new Stage('stage', FOREVER);
		add(stage);

		boyfriend = new Character(750, 850, PSYCH, 'bf-psych', 'BOYFRIEND', true);
		add(boyfriend);

		dad = new Character(50, 850, FOREVER, 'pico', 'Pico_FNF_assetss', false);
		add(dad);

		// handle UI stuff
		strumlines = new FlxTypedGroup<Strumline>();
		var separation:Float = FlxG.width / 4;
		// dad
		dadStrums = new Strumline((FlxG.width / 2) - separation, (downscroll ? FlxG.height - FlxG.height / 6 : FlxG.height / 6), 'default', true, false,
			[dad], [dad]);
		strumlines.add(dadStrums);
		// bf
		bfStrums = new Strumline((FlxG.width / 2) + separation, (downscroll ? FlxG.height - FlxG.height / 6 : FlxG.height / 6), 'default', false, true,
			[boyfriend], [boyfriend]);
		strumlines.add(bfStrums);
		add(strumlines);
		controlledStrumlines = [bfStrums];
		strumlines.cameras = [camHUD];

		// create the hud
		ui = new UI();
		add(ui);
		ui.cameras = [camHUD];

		// create the judgement and combo groups
		judgementGroup = new FlxTypedGroup<ForeverSprite>();
		comboGroup = new FlxTypedGroup<ForeverSprite>();
		add(judgementGroup);
		add(comboGroup);

		// create the game camera
		var camPos:FlxPoint = new FlxPoint(boyfriend.x + (boyfriend.width / 2), boyfriend.y + (boyfriend.height / 2));

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camPos.x, camPos.y);

		add(camFollow);
		add(camFollowPos);

		// preload stuffs lol
		displayJudgement(0, false, true, true);
		for (note in uniqueNoteStash)
		{
			for (strumline in strumlines)
			{
				var splash:ForeverSprite = generateNoteSplash(strumline, note, 0);
				if (splash != null)
					splash.visible = false;
			}
		}

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		gameCameraZoom = stage.cameraZoom;
		FlxG.camera.zoom = gameCameraZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		introCutscene();
	}

	public static var songSpeed(get, default):Float = 0;

	static function get_songSpeed()
		return FlxMath.roundDecimal(songSpeed / Conductor.rate, 2);

	public static var downscroll:Bool = false;

	override public function update(elapsed:Float)
	{
		var lerpVal:Float = (elapsed * 2.4) * cameraSpeed;
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		// control the camera zooming back out
		cameraZoomConverse(elapsed);

		if (FlxG.keys.justPressed.SEVEN)
		{
			persistentUpdate = false;
			FlxG.switchState(new ChartEditor());
		}

		// /*
		parseEventColumn(ChartParser.cameraEventList, spawnCameraEvent);
		parseEventColumn(ChartParser.unspawnedNoteList, spawnNote, -(16 * Conductor.stepCrochet));
		// */

		super.update(elapsed);

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}

		// control notes
		var downscrollMultiplier:Int = (!downscroll ? 1 : -1) * FlxMath.signOf(songSpeed);
		for (strumline in strumlines)
		{
			for (receptor in strumline.receptors)
			{
				if (strumline.autoplay && receptor.animation.finished)
					receptor.playAnim('static');
			}

			// trace('notes strumline amount ${strumline.allNotes.members.length}');
			strumline.allNotes.forEachAlive(function(strumNote:Note)
			{
				if (Math.floor(strumNote.noteData) >= 0)
				{
					// update speed
					if (strumNote.useCustomSpeed)
						strumNote.noteSpeed = strumNote.customNoteSpeed;
					else
						strumNote.noteSpeed = Math.abs(songSpeed);

					// update position
					var baseY = strumline.receptors.members[Math.floor(strumNote.noteData)].y;
					var baseX = strumline.receptors.members[Math.floor(strumNote.noteData)].x;
					strumNote.x = baseX + strumNote.offsetX;
					strumNote.y = baseY
						+ strumNote.offsetY
						+ (downscrollMultiplier * -((Conductor.songPosition - (strumNote.stepTime * Conductor.stepCrochet)) * (0.45 * strumNote.noteSpeed)));

					var noteSize:Float = (strumNote.receptorData.separation * strumNote.receptorData.size);
					var center:Float = baseY + (noteSize / 2);
					if (strumNote.isSustain)
					{
						// note placement
						strumNote.y += ((noteSize / 2) * downscrollMultiplier);

						// note clipping
						if (downscrollMultiplier < 0)
						{
							strumNote.flipY = true;
							if (strumNote.y - strumNote.offset.y * strumNote.scale.y + strumNote.height >= center
								&& (strumline.autoplay
									|| (strumNote.wasGoodHit || (strumNote.prevNote != null && strumNote.prevNote.wasGoodHit))))
							{
								var swagRect = new FlxRect(0, 0, strumNote.frameWidth, strumNote.frameHeight);
								swagRect.height = (center - strumNote.y) / strumNote.scale.y;
								swagRect.y = strumNote.frameHeight - swagRect.height;
								strumNote.clipRect = swagRect;
							}
						}
						else if (downscrollMultiplier > 0)
						{
							if (strumNote.y + strumNote.offset.y * strumNote.scale.y <= center
								&& (strumline.autoplay
									|| (strumNote.wasGoodHit || (strumNote.prevNote != null && strumNote.prevNote.wasGoodHit))))
							{
								var swagRect = new FlxRect(0, 0, strumNote.width / strumNote.scale.x, strumNote.height / strumNote.scale.y);
								swagRect.y = (center - strumNote.y) / strumNote.scale.y;
								swagRect.height -= swagRect.y;
								strumNote.clipRect = swagRect;
							}
						}
					}

					if ((strumNote.y < -strumNote.height || strumNote.y > FlxG.height + strumNote.height)
						&& (strumNote.tooLate || strumNote.wasGoodHit))
					{
						if (strumline.displayJudgement && controlledStrumlines.contains(strumline))
						{
							if (!strumNote.isSustain)
							{
								//
								if (!strumNote.ignoreNote)
									Timings.totalNotesHit++;
							}
							else
							{
								//
							}
						}
						strumline.remove(strumNote);
					}
				}

				if (strumline.autoplay && !strumNote.isMine)
				{
					if (strumNote.stepTime * Conductor.stepCrochet <= Conductor.songPosition)
						goodNoteHit(strumNote, strumline.receptors.members[Math.floor(strumNote.noteData)], strumline);
				}
			});
		}

		// find the right receptor(s) within the controlled strumlines
		for (strumline in controlledStrumlines)
		{
			// get notes held
			var holdingKeys:Array<Bool> = [];
			for (receptor in strumline.receptors)
			{
				for (key in 0...Controls.keyPressed.length)
				{
					if (receptor.action == Controls.getActionFromKey(Controls.keyPressed[key]))
						holdingKeys[receptor.noteData] = true;
				}
			}

			if (!strumline.autoplay)
			{
				strumline.holdGroup.forEachAlive(function(coolNote:Note)
				{
					for (receptor in strumline.receptors)
					{
						if ((coolNote.parentNote != null && coolNote.parentNote.wasGoodHit)
							&& coolNote.canBeHit
							&& !coolNote.wasGoodHit
							&& !coolNote.tooLate
							&& coolNote.noteData == receptor.noteData
							&& holdingKeys[coolNote.noteData])
							goodNoteHit(coolNote, receptor, strumline);
					}
				});
			}

			// reset animation
			for (character in strumline.singingList)
			{
				if (character != null
					&& (character.holdTimer > (Conductor.stepCrochet * 4) / 1000)
					&& (!holdingKeys.contains(true) || strumline.autoplay))
				{
					if (character.animation.curAnim.name.startsWith('sing') && !character.animation.curAnim.name.endsWith('miss'))
						character.dance();
				}
			}
		}
		//
	}

	// get the beats
	@:isVar
	public static var curBeat(get, never):Int = 0;

	static function get_curBeat():Int
		return Conductor.beatPosition;

	// get the steps
	@:isVar
	public static var curStep(get, never):Int = 0;

	static function get_curStep():Int
		return Conductor.stepPosition;

	override public function stepHit()
	{
		super.stepHit();

		for (strumline in strumlines)
		{
			strumline.allNotes.forEachAlive(function(note:Note)
			{
				note.stepHit();
			});
		}
	}

	override public function beatHit()
	{
		super.beatHit();
		for (strumline in strumlines)
		{
			strumline.allNotes.forEachAlive(function(note:Note)
			{
				note.beatHit();
			});
		}
		// bopper stuffs
		if (Conductor.stepPosition % 2 == 0)
		{
			for (i in strumlines)
			{
				for (j in i.characterList)
				{
					if (j.animation.curAnim.name.startsWith("idle") // check the idle before dancing
						|| j.animation.curAnim.name.startsWith("dance"))
						j.dance();
				}
			}
		}
		//
		cameraZoom();
	}

	public var camZooming:Bool = true;
	public var gameCameraZoom:Float = 1;
	public var hudCameraZoom:Float = 1;
	public var gameBump:Float = 0;
	public var hudBump:Float = 0;

	public function cameraZoom()
	{
		//
		if (camZooming)
		{
			if (gameBump < 0.35 && Conductor.beatPosition % 4 == 0)
			{
				// trace('bump');
				gameBump += 0.015;
				hudBump += 0.05;
			}
		}
	}

	public function cameraZoomConverse(elapsed:Float)
	{
		// handle the camera zooming
		FlxG.camera.zoom = gameCameraZoom + gameBump;
		camHUD.zoom = hudCameraZoom + hudBump;
		// /*
		if (camZooming)
		{
			var easeLerp = 1 - (elapsed * 3.125);
			gameBump = FlxMath.lerp(0, gameBump, easeLerp);
			hudBump = FlxMath.lerp(0, hudBump, easeLerp);
		}
		// */
	}

	public function parseEventColumn(eventColumn:Array<Dynamic>, functionToCall:Dynamic->Void, ?timeDelay:Float = 0)
	{
		// check if there even are events to begin with
		if (eventColumn.length > 0)
		{
			while (eventColumn[0] != null && (eventColumn[0].stepTime + timeDelay / Conductor.stepCrochet) <= Conductor.stepPosition)
			{
				if (functionToCall != null)
					functionToCall(eventColumn[0]);
				eventColumn.splice(eventColumn.indexOf(eventColumn[0]), 1);
			}
		}
	}

	function spawnCameraEvent(cameraEvent:CameraEvent)
	{
		// overengineered bullshit
		if (cameraEvent.simple)
		{
			// simple base fnf way
			var characterTo:Character = (cameraEvent.mustPress ? boyfriend : dad);
			camFollow.setPosition(characterTo.getMidpoint().x
				+ (characterTo.cameraOffset.x - 100 * (cameraEvent.mustPress ? 1 : -1)),
				characterTo.getMidpoint().y
				- 100
				+ characterTo.cameraOffset.y);
		}
	}

	function spawnNote(unspawnNote:Note)
	{
		if (unspawnNote != null)
		{
			var strumline:Strumline = strumlines.members[unspawnNote.strumline];
			if (strumline != null)
				strumline.addNote(unspawnNote);
		}
	}

	public function introCutscene()
	{
		// set visibility of stuff
		Conductor.songPosition = -(Conductor.crochet * 16);
		for (strumline in strumlines)
		{
			for (receptor in strumline.receptors)
				receptor.alpha = 0;
		}
		ui.alpha = 0;

		startingSong = true;
		startCountdown();
	}

	public var startedCountdown:Bool = false;
	public var startingSong:Bool = false;
	public var displayCountdown:Bool = true;

	public function startCountdown()
	{
		Conductor.songPosition = -(Conductor.crochet * 5);
		startedCountdown = true;

		// summon the notes
		for (strumline in strumlines)
		{
			for (i in 0...strumline.receptors.members.length)
			{
				var startY:Float = strumline.receptors.members[i].y;
				strumline.receptors.members[i].y -= 32;
				FlxTween.tween(strumline.receptors.members[i], {y: startY, alpha: 1}, (Conductor.crochet * 4) / 1000,
					{ease: FlxEase.circOut, startDelay: (Conductor.crochet / 1000) + ((Conductor.stepCrochet / 1000) * i)});
			}
		}

		FlxTween.tween(ui, {alpha: 1}, (Conductor.crochet * 2) / 1000, {startDelay: (Conductor.crochet / 1000)});

		// overengineering by definition but fuck you
		if (displayCountdown)
		{
			var introArray:Array<FlxGraphic> = [];
			var soundsArray:Array<Sound> = [];
			var introName:Array<String> = ['ready', 'set', 'go'];
			var soundNames:Array<String> = ['intro3', 'intro2', 'intro1', 'introGo'];
			for (intro in introName)
				introArray.push(AssetManager.getAsset('ui/default/$intro', IMAGE, 'images'));
			for (sound in soundNames)
				soundsArray.push(AssetManager.returnSound('assets/sounds/default/$sound.ogg'));

			var countdown:Int = -1;
			var startTimer:FlxTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (countdown >= 0 && countdown < introArray.length)
				{
					var introSprite:FlxSprite = new FlxSprite().loadGraphic(introArray[countdown]);
					introSprite.scrollFactor.set();
					introSprite.updateHitbox();

					introSprite.screenCenter();
					add(introSprite);
					FlxTween.tween(introSprite, {y: introSprite.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							introSprite.destroy();
						}
					});
				}
				countdown++;

				FlxG.sound.play(soundsArray[countdown], 0.6);
			}, 5);
		}
	}

	public function startSong()
	{
		startingSong = false;
		Conductor.boundSong.play();
		Conductor.boundVocals.play();
	}

	// CONTROLS
	public static var receptorActionList:Array<String> = ['left', 'up', 'down', 'right'];

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);
		if (receptorActionList.contains(action))
		{
			// find the right receptor(s) within the controlled strumlines
			for (strumline in controlledStrumlines)
			{
				if (strumline.autoplay)
					return;

				for (receptor in strumline.receptors)
				{
					// if this is the specified action
					if (action == receptor.action)
					{
						// placeholder
						// trace(action);

						var possibleNoteList:Array<Note> = [];
						var pressedNotes:Array<Note> = [];

						strumline.notesGroup.forEachAlive(function(daNote:Note)
						{
							if ((daNote.noteData == receptor.noteData)
								&& !daNote.isSustain
								&& daNote.canBeHit
								&& !daNote.wasGoodHit
								&& !daNote.tooLate)
								possibleNoteList.push(daNote);
						});
						possibleNoteList.sort(sortHitNotes);

						if (possibleNoteList.length > 0)
						{
							var eligable = true;
							var firstNote = true;
							// loop through the possible notes
							for (coolNote in possibleNoteList)
							{
								for (noteDouble in pressedNotes)
								{
									if (Math.abs(noteDouble.stepTime - coolNote.stepTime) < 0.1)
										firstNote = false;
									else
										eligable = false;
								}

								if (eligable)
								{
									goodNoteHit(coolNote, receptor, strumline);
									// goodNoteHit(coolNote, boyfriend, boyfriendStrums, firstNote); // then hit the note
									pressedNotes.push(coolNote);
								}
								// end of this little check
							}
							//
						}

						if (receptor.animation.curAnim.name != 'confirm')
							receptor.playAnim('pressed');
						// receptor.playAnim('confirm');
					}
				}
			}
		}
		//
	}

	/**
	 * Sorts through possible notes, author @Shadow_Mario
	 */
	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.stepTime, b.stepTime);
	}

	public function goodNoteHit(daNote:Note, receptor:Receptor, strumline:Strumline)
	{
		if (!daNote.wasGoodHit)
		{
			daNote.wasGoodHit = true;
			receptor.playAnim('confirm');
			for (i in strumline.singingList)
				characterPlayDirection(i, receptor);

			// is it the player's strumline
			if (strumline.displayJudgement)
			{
				if (!daNote.isSustain)
				{
					// get the note ms timing
					var millisecondTiming:Float = Math.abs((daNote.stepTime * Conductor.stepCrochet) - Conductor.songPosition);

					// get the current judgement
					for (i in 0...Timings.judgements.length)
					{
						// determine full combo
						if (i > Timings.highestFC)
							Timings.highestFC = i;

						if (millisecondTiming > Timings.judgements[i].timing)
							continue;
						else
						{
							Timings.combo++; // replace with conditional later
							if (!daNote.ignoreNote)
							{
								Timings.totalNotesHit++;
								if (!daNote.isMine)
								{
									Timings.notesAccuracy += Timings.judgements[i].accuracy;
									displayJudgement(i, (daNote.stepTime * Conductor.stepCrochet) < Conductor.songPosition);
									Timings.score += Timings.judgements[i].score;
								}
								else
									displayJudgement(Timings.judgements.length, (daNote.stepTime * Conductor.stepCrochet) < Conductor.songPosition);
							}

							if (i == 0 || daNote.isMine)
								generateNoteSplash(strumline, daNote.noteType, daNote.noteData);

							// play the note hit script
							daNote.noteHit();
							break;
						}
						//
					}
				}
			}

			if (!daNote.isSustain)
				strumline.addNote(daNote);
			ui.updateScoreText();
		}
	}

	public function generateNoteSplash(strumline:Strumline, noteType:String, noteData:Int):ForeverSprite
	{
		var noteModule:ForeverModule = Note.returnNoteScript(noteType);
		if (strumline.noteSplashes != null && noteModule.exists("generateSplash"))
		{
			var splashNote:ForeverSprite = strumline.noteSplashes.recycle(ForeverSprite, function()
			{
				var splashNote:ForeverSprite = new ForeverSprite();
				return splashNote;
			});
			//
			splashNote.alpha = 1;
			splashNote.visible = true;
			splashNote.scale.set(1, 1);
			splashNote.x = strumline.receptors.members[noteData].x;
			splashNote.y = strumline.receptors.members[noteData].y;
			//
			noteModule.get("generateSplash")(splashNote, noteData);
			if (splashNote.animation != null)
			{
				splashNote.animation.finishCallback = function(name:String)
				{
					splashNote.kill();
				}
			}
			splashNote.zDepth = -Conductor.songPosition;
			strumline.noteSplashes.sort(ForeverSprite.depthSorting, FlxSort.DESCENDING);
			return splashNote;
		}
		return null;
	}

	public function displayJudgement(judgementNumber:Int, late:Bool, ?perfect:Bool = false, ?preload:Bool = false)
	{
		var curJudgement:ForeverSprite = judgementGroup.recycle(ForeverSprite, function()
		{
			var newJudgement:ForeverSprite = new ForeverSprite();
			newJudgement.loadGraphic(AssetManager.getAsset('ui/default/judgements', IMAGE, 'images'), true, 500, 163);
			newJudgement.animation.add('sick-perfect', [0]);
			for (i in 0...Timings.judgements.length)
			{
				for (j in 0...2)
					newJudgement.animation.add(Timings.judgements[i].name + (j == 1 ? '-late' : '-early'), [(i * 2) + (j == 1 ? 1 : 0) + 2]);
			}
			//
			return newJudgement;
		});
		curJudgement.alpha = 1;
		if (preload)
			curJudgement.alpha = 0;
		curJudgement.zDepth = -Conductor.songPosition;
		curJudgement.screenCenter();
		curJudgement.animation.play(Timings.judgements[judgementNumber].name + (late ? '-late' : '-early'));
		if (Timings.highestFC == 0)
			curJudgement.animation.play('sick-perfect');
		curJudgement.antialiasing = true;
		curJudgement.setGraphicSize(Std.int(curJudgement.frameWidth * 0.7));

		curJudgement.acceleration.y = 550;
		curJudgement.velocity.y = -FlxG.random.int(140, 175);
		curJudgement.velocity.x = -FlxG.random.int(0, 10);

		FlxTween.tween(curJudgement, {alpha: 0}, (Conductor.stepCrochet) / 1000, {
			onComplete: function(tween:FlxTween)
			{
				curJudgement.kill();
			},
			startDelay: ((Conductor.crochet + Conductor.stepCrochet * 2) / 1000)
		});

		// combo
		var comboString:String = Std.string(Timings.combo);
		// determine negative combo
		var negative = false;
		if ((comboString.startsWith('-')) || (Timings.combo == 0))
			negative = true;

		// display combo
		var stringArray:Array<String> = comboString.split("");
		for (i in 0...stringArray.length)
		{
			var combo:ForeverSprite = comboGroup.recycle(ForeverSprite, function()
			{
				var newCombo:ForeverSprite = new ForeverSprite();
				newCombo.loadGraphic(AssetManager.getAsset('ui/default/combo_numbers', IMAGE, 'images'), true, 100, 140);
				newCombo.animation.add('-', [0]);
				for (i in 0...10)
					newCombo.animation.add('$i', [i + 1]);
				return newCombo;
			});
			combo.alpha = 1;
			if (preload)
				combo.alpha = 0;
			combo.zDepth = -Conductor.songPosition;
			combo.animation.play(stringArray[i]);
			combo.antialiasing = true;
			combo.setGraphicSize(Std.int(combo.frameWidth * 0.5));

			combo.acceleration.y = curJudgement.acceleration.y - FlxG.random.int(100, 200);
			combo.velocity.y = -FlxG.random.int(140, 160);
			combo.velocity.x = FlxG.random.float(-5, 5);

			combo.x = curJudgement.x + (curJudgement.width * (1 / 2)) + (43 * i);
			combo.y = curJudgement.y + curJudgement.height / 2;

			FlxTween.tween(combo, {alpha: 0}, (Conductor.stepCrochet * 2) / 1000, {
				onComplete: function(tween:FlxTween)
				{
					combo.kill();
				},
				startDelay: (Conductor.crochet) / 1000
			});
		}

		judgementGroup.sort(ForeverSprite.depthSorting, FlxSort.DESCENDING);
		comboGroup.sort(ForeverSprite.depthSorting, FlxSort.DESCENDING);
	}

	public function characterPlayDirection(character:Character, receptor:Receptor)
	{
		character.playAnim('sing' + receptor.getNoteDirection().toUpperCase(), true);
		character.holdTimer = 0;
	}

	override public function onActionReleased(action:String)
	{
		super.onActionReleased(action);
		if (receptorActionList.contains(action))
		{
			// find the right receptor(s) within the controlled strumlines
			for (strumline in controlledStrumlines)
			{
				if (strumline.autoplay)
					return;

				for (receptor in strumline.receptors)
				{
					// if this is the specified action
					if (action == receptor.action)
					{
						// placeholder
						// trace(action);
						receptor.playAnim('static');
					}
				}
			}
		}
		//
	}
}
