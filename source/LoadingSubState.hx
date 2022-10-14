import config.Config;
import flixel.util.FlxColor;
import flixel.FlxSubState;

class LoadingSubState extends FlxSubState
{
	override function create()
	{
		super.create();
		openfl.Lib.current.stage.frameRate = 144;
		bgColor = FlxColor.BLACK;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (LoadingCount.isDone())
		{
			if (Config.noFpsCap)
				openfl.Lib.current.stage.frameRate = 999;
			close();
		}
	}
}
