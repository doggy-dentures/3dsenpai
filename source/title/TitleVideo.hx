package title;

import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxColor;

using StringTools;

class TitleVideo extends FlxState
{
	// var oldFPS:Int = VideoHandler.MAX_FPS;
	// var video:VideoHandler;
	var titleState = new TitleScreen();

	override public function create():Void
	{

		super.create();

		FlxG.sound.cache(Paths.music("Lunchbox"));

		next();
	}

	override public function update(elapsed:Float){

		super.update(elapsed);

	}

	function next():Void{

		// FlxG.camera.flash(FlxColor.WHITE, 60);
		FlxG.sound.playMusic(Paths.music("Lunchbox"), 0.75);
		Conductor.changeBPM(158);
		FlxG.switchState(titleState);

	}
	
}
