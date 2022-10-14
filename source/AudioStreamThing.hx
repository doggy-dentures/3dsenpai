import MiniAudio.MAResMan;
import MiniAudio.MAGroup;
import flixel.FlxG;
import MiniAudio.MAEngine;
import MiniAudio.MASound;
import lime.media.vorbis.VorbisFile;
import cpp.RawPointer;
import flixel.FlxBasic;

class AudioStreamThing extends FlxBasic
{
	var sound:RawPointer<MASound>;

	public var volume(get, set):Float;
	public var time(get, set):Float;
	public var speed(get, set):Float;
	public var looping(get, set):Bool;
	public var playing(get, never):Bool;
	public var isDone(get, never):Bool;
	public var length(get, never):Float;
	// public var gamePaused:Bool = false;

	var _length:Float = -1;
	var _volume:Float = 1;

	var prevGlobalVol:Float = 1;

	static var engine:RawPointer<MAEngine>;
	static var group:RawPointer<MAGroup>;
	static var resourceManager:RawPointer<MAResMan>;

	static var addedSounds:Array<AudioStreamThing> = [];

	public override function new(filePath:String, grouped:Bool = false)
	{
		super();
		if (resourceManager == null)
			resourceManager = MiniAudio.init_resource();

		if (engine == null)
			engine = MiniAudio.init(resourceManager);

		if (grouped && group == null)
			createGroup();

		sound = MiniAudio.loadSound(engine, filePath, (grouped ? group : null));
		if (sound == null)
		{
			trace("CAN'T LOAD SOUND " + filePath);
			return;
		}

		if (StringTools.endsWith(filePath, ".ogg"))
		{
			var vorb = VorbisFile.fromFile(filePath);
			_length = vorb.timeTotal() * 1000;
			vorb.clear();
			vorb = null;
			trace("THIS IS OGG");
		}
		else
		{
			_length = cast(MiniAudio.getLength(sound) * 1000, Float);
			trace("THIS IS OTHER");
		}
		MiniAudio.setTime(sound, 0);

		addedSounds.push(this);
	}

	public override function destroy()
	{
		if (sound != null)
		{
			MiniAudio.stopSound(sound);
			MiniAudio.destroySound(sound);
		}
		sound = null;
		addedSounds.remove(this);
		super.destroy();
	}

	static public function destroyEngine()
	{
		if (resourceManager != null)
			MiniAudio.uninit_resource(resourceManager);
		resourceManager = null;
		if (engine != null)
			MiniAudio.uninit(engine);
		engine = null;
		if (group != null)
			destroyGroup();
		group = null;
	}

	static public function destroyEverything()
	{
		if (addedSounds != null)
		{
			while (addedSounds.length > 0)
			{
				addedSounds[0].stop();
				addedSounds[0].destroy();
			}
		}
		addedSounds = null;
		destroyEngine();
	}

	public override function update(elapsed:Float):Void
	{
		if (prevGlobalVol != FlxG.sound.volume)
			MiniAudio.setVolume(sound, _volume * FlxG.sound.volume);
		prevGlobalVol = FlxG.sound.volume;
		super.update(elapsed);
	}

	public function play()
	{
		if (MiniAudio.startSound(sound) != 0)
			trace("CAN'T PLAY SOUND");
	}

	public function pause()
	{
		MiniAudio.pauseSound(sound);
	}

	public function stop()
	{
		MiniAudio.stopSound(sound);
	}

	public static function createGroup()
	{
		if (group != null)
			destroyGroup();
		group = MiniAudio.makeGroup(engine);
	}

	public static function destroyGroup()
	{
		if (group != null)
			MiniAudio.killGroup(group);
		else
			trace("NO GROUP TO DESTROY");
		group = null;
	}

	public static function playGroup()
	{
		if (group != null)
			MiniAudio.startGroup(group);
		else
			trace("NO GROUP TO PLAY");
	}

	public static function pauseGroup()
	{
		if (group != null)
			MiniAudio.haltGroup(group);
		else
			trace("NO GROUP TO PAUSE");
	}

	function get_playing():Bool
	{
		return cast(MiniAudio.isPlaying(sound), Bool);
	}

	function get_isDone():Bool
	{
		return cast(MiniAudio.isDone(sound), Bool);
	}

	function get_length():Float
	{
		return _length;
	}

	function get_volume():Float
	{
		return _volume;
	}

	function set_volume(newVol:Float):Float
	{
		_volume = newVol;
		MiniAudio.setVolume(sound, _volume * FlxG.sound.volume);
		return newVol;
	}

	function get_time():Float
	{
		return cast(MiniAudio.getTime(sound) * 1000, Float);
	}

	function set_time(newTime:Float):Float
	{
		MiniAudio.setTime(sound, newTime / 1000);
		return newTime;
	}

	function get_speed():Float
	{
		return cast(MiniAudio.getPitch(sound), Float);
	}

	function set_speed(newSpeed:Float):Float
	{
		MiniAudio.setPitch(sound, newSpeed);
		return newSpeed;
	}

	function get_looping():Bool
	{
		return cast(MiniAudio.getLooping(sound), Bool);
	}

	function set_looping(shouldLoop:Bool):Bool
	{
		MiniAudio.setLooping(sound, shouldLoop);
		return shouldLoop;
	}
}
