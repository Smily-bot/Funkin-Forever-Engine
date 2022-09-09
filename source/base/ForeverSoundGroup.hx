package base;

import flixel.system.FlxSound;
import openfl.media.Sound;

class ForeverSoundGroup
{
	public var sounds:Array<FlxSound> = [];
	@:isVar
	public var time(get, set):Float;

	public function get_time():Float
	{
		// quickly verify all sounds are in sync
		var standardTime:Float = sounds[0].time;
		for (i in sounds)
		{
			if (Math.abs(i.time - standardTime) > 20)
			{
				// resynchronize the songs
				i.pause();
				i.time = standardTime;
				i.play();
			}
		}
		return standardTime;
	}

	public function set_time(newTime:Float)
	{
		for (i in sounds)
			i.time = newTime;
		return newTime;
	}

	public var pitch(default, set):Float;

	public function set_pitch(newPitch:Float):Float
	{
		for (i in sounds)
			i.pitch = newPitch;
		return pitch = newPitch;
	}

	/**
	 * [Creates a Sound Group with multiple Sounds]
	 * @param newSounds an Array of Sounds you would like the group to include
	 */
	public function new(?newSounds:Array<Sound>)
	{
		// return all of the sounds
		if (newSounds != null)
		{
			for (i in newSounds)
				sounds.push(new FlxSound().loadEmbedded(i));
		}
	}

	/**
	 * [Plays all of the Sounds in a Sound Group]
	 */
	public function play()
	{
		for (i in sounds)
			i.play();
	}

	/**
	 * [Pauses all of the Sounds in a Sound Group]
	 */
	public function pause()
	{
		for (i in sounds)
			i.pause();
	}
}
