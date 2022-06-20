package base;

typedef UnspawnedNote =
{
	var stepTime:Float;
	var index:Int;
	var strumline:Int;
	var type:String;
	var holdStep:Float;
	var animationString:String;
}

typedef CameraEvent =
{
	var stepTime:Float;
	var simple:Bool;
	var mustPress:Bool;
}

typedef TimedEvent = {}
