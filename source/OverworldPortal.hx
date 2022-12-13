import config.Config;
import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.addons.display.FlxExtendedSprite;
import flixel.FlxG;
import flixel.FlxSubState;

class OverworldPortal extends FlxSubState
{
	var bg:FlxSprite;
	var yes:FlxExtendedSprite;
	var no:FlxExtendedSprite;
	var twn:FlxTween;
	var choice:Int = 0;

	override public function new()
	{
		super();
	}

	override public function create()
	{
		FlxG.mouse.visible = true;
		super.create();

		if (bg == null)
			bg = new FlxSprite();
		bg.antialiasing = true;
		bg.alpha = 0;
		add(bg);
		twn = FlxTween.tween(bg, {"alpha": 1}, 0.2);

		yes = new FlxExtendedSprite();
		yes.loadGraphic(Paths.image('start'));
		yes.antialiasing = true;
		add(yes);
		no = new FlxExtendedSprite();
		no.loadGraphic(Paths.image('cancel'));
		no.antialiasing = true;
		add(no);

		yes.setPosition(FlxG.width / 3 - yes.width / 2, FlxG.height - yes.height - 20);
		no.setPosition(FlxG.width / 3 * 2 - no.width / 2, FlxG.height - no.height - 20);

		FlxG.sound.play(Paths.sound('popup'));
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (fading || accepted)
			return;

		if (Config.noMouse)
		{
			if (FlxG.keys.justPressed.ESCAPE)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				fadeout();
				return;
			}

			if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT)
			{
				choice--;
				choice = choice % 2;
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			else if (FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT)
			{
				choice++;
				choice = choice % 2;
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (choice == 0)
			{
				yes.color = 0xff4797ff;
				no.color = FlxColor.WHITE;
			}
			else
			{
				no.color = 0xff4797ff;
				yes.color = FlxColor.WHITE;
			}

			if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER)
			{
				if (choice == 0)
				{
					yes.color = 0xff80d0ff;
					FlxG.sound.play(Paths.sound('confirmMenu'));
					accept();
				}
				else
				{
					no.color = 0xff80d0ff;
					FlxG.sound.play(Paths.sound('cancelMenu'));
					fadeout();
				}
				return;
			}
		}
		else
		{
			if (yes.mouseX > -1 && yes.mouseY > -1)
			{
				if (yes.color == FlxColor.WHITE)
				{
					yes.color = 0xff4797ff;
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}

				if (FlxG.mouse.justPressed)
				{
					yes.color = 0xff80d0ff;
					FlxG.sound.play(Paths.sound('confirmMenu'));
					accept();
					return;
				}
			}
			else if (yes.color != FlxColor.WHITE)
				yes.color = FlxColor.WHITE;

			if (no.mouseX > -1 && no.mouseY > -1)
			{
				if (no.color == FlxColor.WHITE)
				{
					no.color = 0xff4797ff;
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}

				if (FlxG.mouse.justPressed)
				{
					no.color = 0xff80d0ff;
					FlxG.sound.play(Paths.sound('cancelMenu'));
					fadeout();
					return;
				}
			}
			else if (no.color != FlxColor.WHITE)
				no.color = FlxColor.WHITE;
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

	override function close()
	{
		FlxG.mouse.visible = false;
		if (twn != null && twn.active)
			twn.cancel();
		super.close();
	}

	var accepted:Bool = false;

	function accept()
	{
		accepted = true;
		cast(FlxG.state, Overworld).selected = true;
		FlxTween.tween(no, {"alpha": 0}, 0.2);
		FlxTween.color(yes, 0.2, yes.color, 0xff24f8ff);
		new FlxTimer().start(1, function(twn)
		{
			fadeout();
		});
	}

	override public function destroy()
	{
		twn = FlxDestroyUtil.destroy(twn);
		super.destroy();
	}
}
