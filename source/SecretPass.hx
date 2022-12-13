import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import sys.net.Host;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSubState;

using StringTools;

class SecretPass extends FlxSubState
{
	var twn:FlxTween;
	var bg:FlxSprite;
	var thing:String;
	var cool:Array<FlxKey> = [UP, UP, DOWN, DOWN, LEFT, RIGHT, LEFT, RIGHT, B, A];
	var curCool:Int = 0;

	override public function create()
	{
		super.create();
		FlxG.sound.play(Paths.sound('popup'));
		bg = new FlxSprite().loadGraphic(Paths.image('ow/pass'));
		add(bg);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (fading)
			return;

		if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE)
		{
			fadeout();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
		else if (FlxG.keys.justPressed.ENTER)
		{
			FlxG.openURL('https://gamebanana.com/mods/406432');
		}
		else if (FlxG.keys.justPressed.ANY)
		{
			if (FlxG.keys.anyJustPressed([cool[curCool]]))
			{
				curCool++;
				if (curCool >= cool.length)
				{
					cast(FlxG.state, Overworld).didPass = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));
					fadeout();
					Main.goodThing = true;
					FlxG.save.data.goodThing = true;
				}
			}
			else
			{
				curCool = 0;
			}
		}
	}

	var fading:Bool = false;

	function fadeout()
	{
		fading = true;
		if (twn != null && twn.active)
			twn.cancel();
		twn = FlxDestroyUtil.destroy(twn);
		twn = FlxTween.tween(bg, {"alpha": 0}, 0.2, {
			onComplete: function(_)
			{
				close();
			}
		});
	}
}
