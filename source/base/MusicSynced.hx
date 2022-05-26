package base;

typedef UnspawnedNote =
{
	var beatTime:Float;
	var index:Int;
	var strumline:Int;
	var type:String;
	var holdBeat:Float;
	var animationString:String;
}

typedef CameraEvent =
{
	var beatTime:Float;
	var simple:Bool;
	var mustPress:Bool;
}

typedef TimedEvent = {}
