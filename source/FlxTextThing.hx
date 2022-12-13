import flixel.math.FlxRandom;
import flixel.system.FlxSound;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.addons.text.FlxTypeText;
import flixel.util.FlxDestroyUtil;
import flixel.text.FlxText;

class FlxTextThing extends FlxText
{
	var disposedImage:Bool = false;

	public function disposeImage()
	{
		graphic.bitmap.disposeImage();
		disposedImage = true;
	}

	override function regenGraphic():Void
	{
		if (disposedImage)
			return;
		super.regenGraphic();
	}

	override function set_text(Text:String):String
	{
		if (Text == text)
			return text;
		return super.set_text(Text);
	}

	override public function destroy()
	{
		if (graphic != null && graphic.bitmap != null)
		{
			graphic.bitmap.disposeImage();
			graphic.bitmap.dispose();
			graphic.bitmap = null;
		}
		graphic = FlxDestroyUtil.destroy(graphic);
		super.destroy();
	}
}

class FlxTextTypeThing extends FlxTypeText
{
	public var altSounds:Array<FlxSound> = [];

	var curSound:FlxSound;

	override public function destroy()
	{
		curSound = null;
		altSounds = null;
		if (altSounds != null)
		{
			for (snd in altSounds)
			{
				if (snd != null)
				{
					snd.stop();
					snd = FlxDestroyUtil.destroy(snd);
				}
			}
		}
		altSounds = FlxDestroyUtil.destroyArray(altSounds);
		if (_sound != null)
			_sound.stop();
		_sound = FlxDestroyUtil.destroy(_sound);
		if (skipKeys != null)
			skipKeys.resize(0);
		skipKeys = null;
		completeCallback = null;
		eraseCallback = null;
		_finalText = null;
		graphic.bitmap.disposeImage();
		graphic.bitmap.dispose();
		graphic.bitmap = null;
		graphic = FlxDestroyUtil.destroy(graphic);
		super.destroy();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (altSounds != null && _typing && (curSound == null || !curSound.playing))
		{
			curSound = FlxG.random.getObject(altSounds).play();
		}
	}
}
