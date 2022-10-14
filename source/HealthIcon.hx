package;

import sys.FileSystem;
import flixel.util.FlxDestroyUtil;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{
	public var defualtIconScale:Float = 1.0;
	public var iconScale:Float = 1.0;
	public var iconSize:Float = 128;

	var char:String;
	public var status:String = "normal";

	private var tween:FlxTween;

	private static final pixelIcons:Array<String> = ["bf-pixel", "senpai", "senpai-angry", "spirit"];

	public function new(char:String = 'face', isPlayer:Bool = false, ?_id:Int = -1)
	{
		super();
		flipX = isPlayer;

		changeChar(char);

		normal();

		antialiasing = !pixelIcons.contains(char);
		scrollFactor.set();

		tween = FlxTween.tween(this, {}, 0);
	}

	public function changeChar(char:String)
	{
		if (FileSystem.exists("assets/images/healthicons/" + char))
			this.char = char;
		else
			this.char = "face";
	}

	public function normal()
	{
		if (FileSystem.exists("assets/images/healthicons/" + char + "/normal.png"))
			loadGraphic(Paths.image("healthicons/" + char + "/normal"));
		status = "normal";
	}

	public function win()
	{
		if (FileSystem.exists("assets/images/healthicons/" + char + "/win.png"))
			loadGraphic(Paths.image("healthicons/" + char + "/win"));
		status = "win";
	}

	public function lose()
	{
		if (FileSystem.exists("assets/images/healthicons/" + char + "/lose.png"))
			loadGraphic(Paths.image("healthicons/" + char + "/lose"));
		status = "lose";
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		setGraphicSize(Std.int(iconSize * iconScale));
		updateHitbox();
	}

	public function tweenToDefaultScale(_time:Float, _ease:Null<flixel.tweens.EaseFunction>)
	{
		tween.cancel();
		tween = FlxTween.tween(this, {iconScale: this.defualtIconScale}, _time, {ease: _ease});
	}

	override public function destroy()
	{
		tween = FlxDestroyUtil.destroy(tween);
		super.destroy();
	}
}
