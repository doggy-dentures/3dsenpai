package;

import flixel.util.FlxDestroyUtil;
import flixel.FlxSprite;
import openfl.events.KeyboardEvent;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class GameOverSubstate extends MusicBeatSubstate
{
	// var bf:Boyfriend;
	// var camFollow:FlxObject;
	var stageSuffix:String = "";
	var retry:FlxSprite;
	var tmr:FlxTimer;

	override public function create()
	{
		var daStage = PlayState.curStage;
		var daBf:String = '';
		switch (daStage)
		{
			case 'school':
				stageSuffix = '-pixel';
				daBf = 'bf-pixel-dead';
			case 'schoolEvil':
				stageSuffix = '-pixel';
				daBf = 'bf-pixel-dead';
			default:
				daBf = 'bf';
		}

		super.create();

		bgColor = FlxColor.BLACK;

		retry = new FlxSprite().loadGraphic(Paths.image("weeb/pixelUI/retry"));
		retry.scale.set(4, 4);
		retry.updateHitbox();
		retry.screenCenter(XY);
		retry.visible = false;
		add(retry);

		Conductor.songPosition = 0;

		// bf = new Boyfriend(x, y, daBf);
		// add(bf);

		// camFollow = new FlxObject(camX, camY, 1, 1);
		// add(camFollow);
		// FlxTween.tween(camFollow, {x: bf.getGraphicMidpoint().x, y: bf.getGraphicMidpoint().y}, 3, {ease: FlxEase.quintOut, startDelay: 0.5});

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
		Conductor.changeBPM(100);

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		// bf.playAnim('firstDeath');

		tmr = new FlxTimer().start(3, function(_)
		{
			retry.visible = true;
			FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// FlxG.camera.follow(camFollow, LOCKON);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();

			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, PlayState.instance.keyDown);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, PlayState.instance.keyUp);

			// if (PlayState.isStoryMode)
			// 	PlayState.instance.switchState(new StoryMenuState());
			// else
			// 	PlayState.instance.switchState(new FreeplayState());
			// PlayState.instance.switchState(new MainMenuState());
			PlayState.instance.switchState(new Overworld());
		}

		// if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		// {
		// 	FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));
		// }

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		// FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			// FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, PlayState.instance.keyDown);
			// FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, PlayState.instance.keyUp);
			isEnding = true;
			// bf.playAnim('deathConfirm', true);
			if (tmr.active)
				tmr.cancel();
			retry.visible = true;
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.4, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 1.2, false, function()
				{
					PlayState.instance.switchState(new PlayState());
				});
			});
		}
	}

	override public function destroy()
	{
		tmr = FlxDestroyUtil.destroy(tmr);
		retry = FlxDestroyUtil.destroy(retry);
		super.destroy();
	}
}
