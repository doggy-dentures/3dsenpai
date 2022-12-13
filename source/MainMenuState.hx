package;

import config.*;
import title.TitleScreen;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.text.FlxText;

using StringTools;

class MainMenuState extends MusicBeatState
{
	var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	var optionShit:Array<String> = ['story mode', "options"];

	var pointer:FlxSprite;
	var versionText:FlxText;
	var keyWarning:FlxText;

	override function create()
	{
		openfl.Lib.current.stage.frameRate = 144;

		PlayState.SONG = null;
		PlayState.EVENTS = null;

		FlxG.sound.playMusic(Paths.music(TitleScreen.titleMusic), 0.75);

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('weeb/bg'));
		bg.scale.set(5, 5);
		bg.updateHitbox();
		bg.screenCenter(XY);
		add(bg);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite();
			if (i == 0)
				menuItem.loadGraphic(Paths.image("weeb/pixelUI/play"));
			else
				menuItem.loadGraphic(Paths.image("weeb/pixelUI/options"));
			menuItem.scale.set(4, 4);
			menuItem.updateHitbox();
			menuItem.screenCenter(X);
			menuItem.y = (i + 1) * FlxG.height / (optionShit.length + 1) - menuItem.height / 2;
			menuItem.ID = i;
			menuItems.add(menuItem);
		}

		pointer = new FlxSprite().loadGraphic(Paths.image("weeb/pixelUI/hand_textbox"));
		pointer.scale.set(6, 6);
		pointer.updateHitbox();
		add(pointer);

		versionText = new FlxText(5, FlxG.height - 21, 0, Assets.getText(Paths.text("version")), 16);
		versionText.scrollFactor.set();
		versionText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionText);

		keyWarning = new FlxText(5, FlxG.height - 21 + 16, 0, "If your controls aren't working, try pressing BACKSPACE to reset them.", 16);
		keyWarning.scrollFactor.set();
		keyWarning.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		keyWarning.alpha = 0;
		add(keyWarning);

		FlxTween.tween(versionText, {y: versionText.y - 16}, 0.75, {ease: FlxEase.quintOut, startDelay: 10});
		FlxTween.tween(keyWarning, {alpha: 1, y: keyWarning.y - 16}, 0.75, {ease: FlxEase.quintOut, startDelay: 10});

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		// Offset Stuff
		Config.reload();

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (FlxG.keys.justPressed.BACKSPACE)
			{
				KeyBinds.resetBinds();
				switchState(new MainMenuState());
			}

			// if (controls.BACK)
			// {
			// 	switchState(new TitleScreen());
			// }

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					#if linux
					Sys.command('/usr/bin/xdg-open', ["https://ninja-muffin24.itch.io/funkin", "&"]);
					#else
					FlxG.openURL('https://ninja-muffin24.itch.io/funkin');
					#end
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					var daChoice:String = optionShit[curSelected];

					FlxG.sound.music.stop();

					// FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								// var daChoice:String = optionShit[curSelected];

								spr.visible = true;

								switch (daChoice)
								{
									case 'story mode':
										// switchState(new StoryMenuState());
										// trace("Story Menu Selected");
										// var poop = Highscore.formatSong("roses", 1);
										// PlayState.SONG = Song.loadFromJson(poop, "roses");
										// PlayState.isStoryMode = false;
										// PlayState.storyDifficulty = 1;
										// PlayState.loadEvents = true;
										// PlayState.returnLocation = "main";
										// PlayState.storyWeek = 6;
										// switchState(new PlayState());
										// case 'freeplay':
										// 	FreeplayState.startingSelection = 0;
										// 	switchState(new FreeplayState());
										// 	trace("Freeplay Menu Selected");
										switchState(new Overworld());
									case 'options':
										ConfigMenu.exitTo = MainMenuState;
										switchState(new ConfigMenu());
										trace("options time");
								}
							});
						}
					});
				}
			}
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});

		#if debug
		if (FlxG.keys.justPressed.Q)
		{
			FlxG.sound.music.stop();
			switchState(new Overworld());
		}

		if (FlxG.keys.justPressed.W)
		{
			FlxG.sound.music.stop();
			var poop = Highscore.formatSong("roses", 1);
			PlayState.SONG = Song.loadFromJson(poop, "roses");
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 1;
			PlayState.loadEvents = true;
			PlayState.returnLocation = "main";
			PlayState.storyWeek = 6;
			switchState(new PlayState());
		}

		if (FlxG.keys.justPressed.E)
		{
			FlxG.sound.music.stop();
			var poop = Highscore.formatSong("fuzzy-logic", 1);
			PlayState.SONG = Song.loadFromJson(poop, "fuzzy-logic");
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 1;
			PlayState.loadEvents = true;
			PlayState.returnLocation = "main";
			PlayState.storyWeek = 6;
			switchState(new PlayState());
		}
		#end
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		pointer.y = menuItems.members[curSelected].y + menuItems.members[curSelected].height / 2 - pointer.height / 2;
		pointer.x = menuItems.members[curSelected].x - pointer.width - 20;
	}
}
