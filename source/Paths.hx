/**
	Backwards Compatibility with Base Game's paths system.
**/
class Paths
{
	public var publicPath:String;

	public function new(publicPath:String)
	{
		this.publicPath = publicPath;
	}

	public function image(key:String, ?textureCompression:Bool = false)
	{
		return AssetManager.getAsset(key, IMAGE, publicPath);
	}
}
