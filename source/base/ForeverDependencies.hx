package base;

import flixel.FlxSprite;

/**
 * A class that truncates/adds several functions and utilities
 * such as storing song time, simple depth sorting & offsetting functionality to the FlxSprite class
 */
class ForeverSprite extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var zDepth:Float = 0;
	public var currentTime:Float;

	public static inline function depthSorting(Order:Int, Obj1:ForeverSprite, Obj2:ForeverSprite)
	{
		if (Obj1.zDepth > Obj2.zDepth)
			return -Order;
		return Order;
	}

	public function resizeOffsets(?newScale:Float)
	{
		if (newScale == null)
			newScale = scale.x;
		for (i in animOffsets.keys())
			animOffsets[i] = [animOffsets[i][0] * newScale, animOffsets[i][1] * newScale];
	}

	public function new(?x:Float, ?y:Float)
	{
		super(x, y);
		animOffsets = new Map<String, Array<Dynamic>>();
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0):Void
		animOffsets[name] = [x, y];

	public function playAnim(AnimName:String, ?Force:Bool = false, ?Reversed:Bool = false, ?Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);
		centerOffsets();
		centerOrigin();

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
			offset.set(daOffset[0], daOffset[1]);
	}
}
