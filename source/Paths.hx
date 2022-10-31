/**
	Backwards Compatibility with Base Game's paths system.
**/
class Paths
{
	inline public static function image(key:String)
	{
		return AssetManager.getAsset(key, IMAGE);
	}

	inline public static function getSparrowAtlas(key:String)
	{
		return AssetManager.getAsset(key, SPARROW);
	}
}

class LocalPath
{
	public var localPath:String;

	public function new(localPath:String)
	{
		this.localPath = localPath;
	}

	private function image(key:String, ?gpuRender:Bool = false)
	{
		return AssetManager.getAsset(key, IMAGE, localPath);
	}

	private function json(key:String)
	{
		return AssetManager.getAsset(key, JSON, localPath);
	}

	private function sound(key:String)
	{
		return AssetManager.getAsset(key, SOUND, localPath);
	}

	private function font(key:String)
	{
		return AssetManager.getAsset(key, FONT, localPath);
	}

	private function module(key:String)
	{
		return AssetManager.getAsset(key, MODULE, localPath);
	}

	private function getSparrowAtlas(key:String)
	{
		return AssetManager.getAsset(key, SPARROW, localPath);
	}
}
