package base;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import openfl.media.Sound;
import states.MusicBeatState.MusicHandler;

/**
 * A singleton class that handles the usage and control of songs
 */
typedef Judgement =
{
	var name:String;
	var timing:Float;
	var score:Int;
	var accuracy:Float;
	var health:Float;
	var comboStatus:Null<String>;
}

class Conductor
{
	public static var songPosition:Float = 0; // determines the position of the song in milliseconds
	public static var beatPosition:Int = 0; // ditto, but beats
	public static var stepPosition:Int = 0; // ditto, but steps

	public static var rate:Float = 1.0; // the rate of the song playback speed
	public static var bpm:Float = 0; // beats per minute or the tempo of the song

	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds

	public static var boundSong:FlxSound;
	public static var boundVocals:ForeverSoundGroup;
	public static var boundState:MusicHandler;

	public static final comparisonThreshold:Float = 20; // the amount of milliseconds of difference before resynchronization

	public static var bpmMap:Map<Float, Float>;
	public static var soundGroup:FlxTypedGroup<FlxSound>;

	public static function bindSong(newState:MusicHandler, newSong:Sound, songBPM:Float, ?newVocals:Array<Sound>)
	{
		boundSong = new FlxSound().loadEmbedded(newSong);
		boundVocals = new ForeverSoundGroup(newVocals);
		boundState = newState;

		soundGroup = new FlxTypedGroup<FlxSound>();
		soundGroup.add(boundSong);
		for (i in boundVocals.sounds)
			soundGroup.add(i);
		boundState.add(soundGroup);

		// recalculate crochets
		bpm = songBPM;
		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / 4;

		// reset last steps
		lastStep = -1;
		lastBeat = -1;

		// call the finish song execution once the song is done
		boundSong.onComplete = function()
		{
			boundState.finishSong();
		};
	}

	public static var lastStep:Float = -1;
	public static var lastBeat:Float = -1;

	public static function updateTimePosition(elapsed:Float)
	{
		if (boundSong.playing)
		{
			// update time position
			boundSong.pitch = rate;
			boundVocals.pitch = rate;
			songPosition += elapsed * 1000 * rate;
			// trace('$songPosition');

			// update the bpm
			var lastTime:Float = 0;
			if (bpmMap != null)
			{
				var biggestPosition:Float = 0;
				for (i in bpmMap.keys())
				{
					if ((songPosition >= i) && (i > biggestPosition))
					{
						lastTime = i;
						bpm = bpmMap[i];
					}
				}
			}

			stepPosition = Math.floor(lastTime / stepCrochet) + Math.floor((songPosition - lastTime) / stepCrochet);
			beatPosition = Math.floor(stepPosition / 4);
			if (stepPosition > lastStep)
			{
				// trace('bound song time ${boundSong.time}');
				// /* possible resync measure
				if ((Math.abs(boundSong.time - songPosition) > 20)
					|| (boundVocals != null && Math.abs(boundVocals.time - songPosition) > 20))
					resyncTime();
				// */

				boundState.stepHit();
				lastStep = stepPosition;
			}
			if (beatPosition > lastBeat)
			{
				boundState.beatHit();
				lastBeat = beatPosition;
			}
		}
	}

	public static var focused:Bool = true;

	public static function onFocusLost()
	{
		if (focused)
		{
			@:privateAccess
			for (i in soundGroup)
				i.onFocusLost();
		}
		focused = false;
	}

	public static function onFocus()
	{
		if (!focused)
		{
			@:privateAccess
			for (i in soundGroup)
				i.onFocus();
		}
		focused = true;
	}

	public static function resyncTime()
	{
		// resynchronization
		///*
		trace('resyncing song time ${boundSong.time}, ${songPosition}');
		// /*
		if (boundVocals != null)
			boundVocals.pause();

		boundSong.play();
		songPosition = boundSong.time;
		if (boundVocals != null)
		{
			if (songPosition <= boundVocals.sounds[0].length)
				boundVocals.time = songPosition;
			boundVocals.play();
		}
		//  */

		trace('new song time ${boundSong.time}, ${songPosition}');
		// */
	}
}

class Timings
{
	public static var highestFC:Int;

	public static var combo:Int = 0;
	public static var score:Int = 0;
	public static var health:Float = 1;
	public static var misses:Int = 0;

	public static var totalNotesHit:Int = 0;
	public static var notesAccuracy:Float = 0;
	public static var accuracy(get, never):Float;

	static function get_accuracy():Float
		return notesAccuracy / totalNotesHit;

	public static var threshold:Float = 200;

	// judgements
	public static var judgements:Array<Judgement> = [
		{
			name: "sick",
			timing: 45,
			score: 350,
			health: 100,
			accuracy: 100,
			comboStatus: 'SFC'
		},
		{
			name: "good",
			timing: 90,
			score: 150,
			health: 50,
			accuracy: 85,
			comboStatus: 'GFC'
		},
		{
			name: "bad",
			timing: 125,
			score: 50,
			health: 20,
			accuracy: 50,
			comboStatus: 'FC'
		},
		{
			name: "shit",
			timing: 150,
			score: -50,
			health: -50,
			accuracy: 0,
			comboStatus: null
		},
		{
			name: "miss",
			timing: 175,
			score: -100,
			health: -100,
			accuracy: 0,
			comboStatus: null
		}
	];

	public static var scoreRating:Map<String, Int> = [
		"S+" => 100,
		"S" => 95,
		"A" => 90,
		"B" => 85,
		"C" => 80,
		"D" => 75,
		"E" => 70,
		"F" => 65
	];

	public static function resetScore()
	{
		combo = 0;
		score = 0;
		health = 1;
		misses = 0;

		//
		totalNotesHit = 0;
	}

	public static function returnAccuracy():String
	{
		var returnString:String = 'N/A';
		if (totalNotesHit > 0)
			returnString = '${Math.floor(accuracy * 100) / 100}%';
		return returnString;
	}
}
