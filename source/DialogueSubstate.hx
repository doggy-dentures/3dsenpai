package;

import openfl.Assets;
import flixel.text.FlxText;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxSound;
import flixel.text.FlxText.FlxTextAlign;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;
import sys.FileSystem;
import flixel.FlxG;
import config.Config;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.addons.text.FlxTypeText;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import sys.io.File;
import haxe.Json;

using StringTools;

class DialogueSubstate extends FlxSubState
{
	var finishThing:Void->Void;
	var suffix:String;
	var delay:Float;

	var black:FlxSprite;
	var dialogue:Dialogue;
	var currentLine:Int = 0;
	var textBox:FlxSprite;
	var textOutput:FlxTextThing.FlxTextTypeThing;
	var cam:FlxCamera;
	var portrait:FlxSprite;
	var music:FlxSound;

	var typingSounds:Map<String, Array<FlxSound>> = [];
	var faces:Map<String, Map<String, FlxGraphic>> = [];
	var boxes:Map<String, FlxGraphic> = [];

	var doneTyping:Bool = false;
	var stopInputs:Bool = false;
	var skipNotice:FlxTextThing;
	var showTimer:FlxTimer;
	var textBoxTween:FlxTween;
	var portraitTween:FlxTween;

	var musicStream:AudioStreamThing;

	override public function new(onFinish:Void->Void, delay:Float = 0.4, suffix = "", BGColor:FlxColor = FlxColor.TRANSPARENT)
	{
		super(BGColor);
		this.finishThing = onFinish;
		this.suffix = suffix;
		this.delay = delay;
	}

	override function create()
	{
		super.create();

		// if (!FileSystem.exists(Paths.json(song + '/' + "dialogue/" + player + suffix)))
		// {
		// 	close();
		// 	return;
		// }

		// openfl.Lib.current.stage.frameRate = 144;
		// Main.changeFramerate(144);

		cam = new FlxCamera();
		cam.bgColor.alpha = 0;
		FlxG.cameras.add(cam);
		cameras = [cam];
		black = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		black.alpha = 0.5;
		black.scrollFactor.set();
		black.setGraphicSize(FlxG.width, FlxG.height);
		black.updateHitbox();
		add(black);

		dialogue = Json.parse(Assets.getText('assets/agal/dialogue/fuzzy-logic.json').trim());

		if (dialogue == null)
		{
			trace("DIALOGUE NULL");
			close();
		}
		else if (dialogue.dialogueLines == null)
		{
			trace("DIALOGUE LINES NULL");
			close();
		}

		portrait = new FlxSprite();
		portrait.visible = false;
		portrait.antialiasing = true;
		add(portrait);
		textBox = new FlxSprite();
		textBox.visible = false;
		textBox.antialiasing = true;
		textBox.alpha = 0.7;
		add(textBox);
		textOutput = new FlxTextThing.FlxTextTypeThing(0, 0, Std.int(textBox.width * 0.8), "", 32);
		textOutput.antialiasing = true;
		add(textOutput);

		preloadStuff();

		showTimer = new FlxTimer().start(delay, function(tmr)
		{
			spitDialogue();
		});

		skipNotice = new FlxTextThing(0, 10, 0, "Press BACKSPACE to skip", 16);
		skipNotice.setFormat(null, 16, FlxColor.WHITE, null, OUTLINE, FlxColor.BLACK);
		skipNotice.screenCenter(X);
		add(skipNotice);
	}

	function preloadStuff()
	{
		var speakers:Map<String, Array<String>> = [];
		var boxTypes:Array<String> = [];

		for (line in dialogue.dialogueLines)
		{
			var face = (line.face == null ? "default" : line.face);
			var speaker = line.speaker;
			if (speaker != null)
			{
				var speaker = speaker.toLowerCase();
				// trace("SPEAKER: " + speaker + "/" + face);
				// trace("LOOK AT: " + "assets/sounds/dialogue/" + speaker);
				if (speaker != null)
				{
					if (speakers[speaker] == null)
						speakers[speaker] = [];
					if (!speakers[speaker].contains(face))
						speakers[speaker].push(face);
				}
			}

			var boxType = (line.boxType == null ? "default" : line.boxType);
			// trace("BOX " + boxType);
			if (boxType != null && !boxTypes.contains(boxType))
			{
				boxTypes.push(boxType);
			}
		}

		for (speaker in speakers.keys())
		{
			var sounds:Array<FlxSound> = [];
			if (speaker != null)
			{
				// if (FileSystem.isDirectory("assets/sounds/dialogue/" + speaker))
				// {
				// 	var files = FileSystem.readDirectory("assets/sounds/dialogue/" + speaker);
				// 	for (file in files)
				// 	{
				// 		if (StringTools.endsWith(file, ".ogg"))
				// 		{
				// 			var flxsnd = new FlxSound().loadEmbedded("assets/sounds/dialogue/" + speaker + "/" + file);
				// 			add(flxsnd);
				// 			sounds.push(flxsnd);
				// 		}
				// 	}
				// 	if (sounds.length > 0)
				// 	{
				// 		typingSounds[speaker] = sounds;
				// 	}
				// }
				// else
				// {
				// 	trace("NO SOUNDS OR SOMETHING");
				// }

				faces[speaker] = new Map<String, FlxGraphic>();

				// for (face in speakers.get(speaker))
				// {
				// 	if (FileSystem.exists("assets/images/dialogue/portraits/" + speaker + "/" + face + ".funk"))
				// 	{
				// 		// trace("GOOD STUFFZ OF " + face + " FOUND FOR " + speaker);
				// 		faces[speaker][face] = Paths.image("dialogue/portraits/" + speaker + "/" + face);
				// 	}
				// 	else
				// 	{
				// 		// trace("NO PORTRAIT OF " + face + " FOUND FOR " + speaker);
				// 		faces[speaker][face] = Paths.image("dialogue/portraits/default");
				// 	}
				// }
			}
		}

		for (boxType in boxTypes)
		{
			if (boxType != null)
			{
				boxes[boxType] = Paths.image("dialogue/" + boxType);
			}
		}

		typingSounds["h"] = [];
		for (i in 0...4)
		{
			var n = new FlxSound().loadEmbedded("assets/sounds/dialogue/h" + i + ".ogg");
			n.volume = 0.4;
			add(n);
			typingSounds["h"].push(n);
		}
	}

	function spitDialogue()
	{
		if (currentLine >= dialogue.dialogueLines.length)
		{
			unpause();
			return;
		}
		var curDiag = dialogue.dialogueLines[currentLine];
		var line = curDiag.line;
		if (line == null)
			line = "[null text error]";
		var boxType = (curDiag.boxType == null ? "default" : curDiag.boxType);
		textBox.loadGraphic("assets/images/dialogue/default.png");
		textBox.y = FlxG.height - textBox.height;
		textBox.visible = true;
		var side = (curDiag.side == null ? "right" : curDiag.side.toLowerCase());
		if (side == "left")
		{
			textBox.flipX = true;
			textBox.x = -textBox.width;
		}
		else
		{
			textBox.flipX = false;
			textBox.x = FlxG.width + textBox.width;
		}
		var align:FlxTextAlign;
		switch (curDiag.align)
		{
			case "left":
				align = LEFT;
			case "right":
				align = RIGHT;
			default:
				align = CENTER;
		}
		textOutput.alignment = align;
		textOutput.fieldWidth = Std.int(textBox.width * 0.8);
		textOutput.x = FlxG.width / 2 - textOutput.width / 2;
		textOutput.y = textBox.y + 20;
		textOutput.skip();
		textOutput.resetText(line);
		var stuff = Math.sqrt(textBox.width * 0.8 * textBox.height * 0.7 / (line.length * 1.1));
		var textSize = Std.int(Math.min(40, stuff - 1));
		var speaker = curDiag.speaker;
		portrait.visible = false;
		if (speaker != null)
		{
			speaker = speaker.toLowerCase();
			// trace("TYPING SOUNDS is " + (typingSounds[speaker] == null ? "bad" : "good"));
			textOutput.altSounds = typingSounds[speaker];
			textOutput.setTypingVariation(0.5);
			if (faces[speaker] != null)
			{
				var face = (curDiag.face == null ? "default" : curDiag.face);
				if (faces[speaker][face] != null)
				{
					portrait.loadGraphic(faces[speaker][face]);
					portrait.y = textBox.y - portrait.height + 25;
					if (side == 'left')
					{
						portrait.flipX = false;
						portrait.x = -portrait.width;
					}
					else
					{
						portrait.flipX = true;
						portrait.x = FlxG.width + portrait.width;
					}
					portrait.visible = true;
				}
			}
		}
		else
		{
			textOutput.setTypingVariation(0, false);
			textOutput.altSounds = null;
		}
		var theColor = FlxColor.WHITE;
		if (curDiag.color != null)
		{
			theColor = FlxColor.fromString(curDiag.color);
		}
		// else if (speaker != null && Main.characterColors[speaker] != null)
		// {
		// 	theColor = Main.characterColors[speaker];
		// }
		textBox.color = theColor;
		var theFont = (curDiag.font == null ? "vcr" : curDiag.font);
		textOutput.setFormat(Paths.font(theFont), textSize, FlxColor.interpolate(FlxColor.WHITE, theColor, 0.25));
		doneTyping = false;
		if (textBoxTween != null && textBoxTween.active)
		{
			textBoxTween.cancel();
			FlxDestroyUtil.destroy(textBoxTween);
		}
		textBoxTween = FlxTween.tween(textBox, {x: FlxG.width / 2 - textBox.width / 2}, 0.15);
		if (portraitTween != null && portraitTween.active)
		{
			portraitTween.cancel();
			FlxDestroyUtil.destroy(portraitTween);
		}
		if (side == 'left')
			portraitTween = FlxTween.tween(portrait, {x: 25}, 0.15, {
				onComplete: function(_)
				{
					startOutput();
				}
			});
		else
			portraitTween = FlxTween.tween(portrait, {x: FlxG.width - 25 - portrait.width}, 0.15, {
				onComplete: function(_)
				{
					startOutput();
				}
			});
		if (curDiag.music != null)
			playMusic(curDiag.music);

		@:privateAccess
		switch (curDiag.event)
		{
			case 'zero':
				FlxTween.tween(cast(FlxG.state, PlayState).posMap["dad"], {'roll': -30}, 0.5);
			case 'one':
				FlxTween.tween(cast(FlxG.state, PlayState).view.view.camera, {'rotationX': -20}, 0.5);
			case 'two':
				cast(FlxG.state, PlayState).executeEvent('y', ['tv', -50, 0.5, false]);
				new FlxTimer().start(0.4, function(_)
				{
					FlxG.sound.play(Paths.sound('tv'), 0.7);
				});
				FlxTween.tween(cast(FlxG.state, PlayState).view.view.camera, {'rotationX': 0}, 0.5);
				FlxTween.tween(cast(FlxG.state, PlayState).posMap["dad"], {'roll': 0}, 0.5);
		}
	}

	function startOutput()
	{
		textOutput.start(0.025, true, false, null, function()
		{
			doneTyping = true;
		});
	}

	function nextDialogue()
	{
		currentLine++;
		spitDialogue();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (stopInputs)
			return;

		if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER)
		{
			if (doneTyping)
			{
				if (textBoxTween != null && textBoxTween.active)
				{
					textBoxTween.cancel();
					FlxDestroyUtil.destroy(textBoxTween);
				}
				textBoxTween = FlxTween.tween(textBox, {x: FlxG.width / 2 - textBox.width / 2}, 0.15);
				if (portraitTween != null && portraitTween.active)
				{
					portraitTween.cancel();
					FlxDestroyUtil.destroy(portraitTween);
				}
				nextDialogue();
			}
			else if (textOutput != null)
			{
				textOutput.skip();
			}
		}
		else if (FlxG.keys.justPressed.BACKSPACE)
		{
			doAllEvents();
			unpause(0.1);
		}
	}

	function doAllEvents()
	{
		@:privateAccess
		if (true)
		{
			cast(FlxG.state, PlayState).executeEvent('y', ['tv', -20, 0.5, false]);
			FlxTween.tween(cast(FlxG.state, PlayState).view.view.camera, {'rotationX': 0}, 0.5);
			FlxTween.tween(cast(FlxG.state, PlayState).posMap["dad"], {'roll': 0}, 0.5);
		}
	}

	function unpause(delay:Float = 0.5)
	{
		stopInputs = true;

		if (showTimer.active)
			showTimer.cancel();
		skipNotice.visible = false;
		for (object in [textBox, textOutput, black, portrait])
		{
			FlxTween.tween(object, {"alpha": 0}, delay, {
				onComplete: function(tween)
				{
					FlxDestroyUtil.destroy(tween);
				}
			});
		}
		if (musicStream != null)
		{
			musicStream.destroy();
			remove(musicStream);
		}
		new FlxTimer().start(delay, function(tmr)
		{
			close();
			FlxDestroyUtil.destroy(tmr);
		});
	}

	function playMusic(newSong:String)
	{
		if (musicStream != null)
		{
			musicStream.destroy();
			remove(musicStream);
		}
		if (newSong != "none")
		{
			musicStream = new AudioStreamThing(Paths.opus(newSong));
			musicStream.looping = true;
			add(musicStream);
			musicStream.play();
		}
	}

	override public function close()
	{
		// if (Config.noFpsCap)
		// 	openfl.Lib.current.stage.frameRate = 999;
		// Main.fpsSwitch();
		FlxG.cameras.remove(cam);
		super.close();
		finishThing();
	}

	override public function destroy()
	{
		black = FlxDestroyUtil.destroy(black);
		cam = FlxDestroyUtil.destroy(cam);
		showTimer = FlxDestroyUtil.destroy(showTimer);
		for (sndArray in typingSounds)
		{
			for (snd in sndArray)
				snd = FlxDestroyUtil.destroy(snd);
		}
		typingSounds.clear();
		typingSounds = null;
		// for (speaker in faces.keys())
		// {
		// 	for (face in faces[speaker].keys())
		// 	{
		// 		Cashew.destroyOne("dialogue/portraits/" + speaker + "/" + face);
		// 	}
		// }
		faces.clear();
		faces = null;
		// for (key in boxes.keys())
		// {
		// 	Cashew.destroyOne("dialogue/" + key);
		// }
		boxes.clear();
		boxes = null;
		if (textBoxTween != null && textBoxTween.active)
			textBoxTween.cancel();
		textBoxTween = FlxDestroyUtil.destroy(textBoxTween);
		if (portraitTween != null && portraitTween.active)
			portraitTween.cancel();
		portraitTween = FlxDestroyUtil.destroy(portraitTween);
		if (musicStream != null)
			musicStream.destroy();
		super.destroy();
	}
}

typedef Dialogue =
{
	var dialogueLines:Null<Array<DialogueLine>>;
}

typedef DialogueLine =
{
	var line:Null<String>;
	var speaker:Null<String>;
	var face:Null<String>;
	var side:Null<String>;
	var boxType:Null<String>;
	var font:Null<String>;
	var music:Null<String>;
	var align:Null<String>;
	var color:Null<String>;
	var event:Null<String>;
}
