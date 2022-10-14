import cpp.ConstCharStar;
import cpp.RawPointer;

@:buildXml('<include name="../../../../source/ma/MiniAudioBuild.xml" />')
@:include("miniaudio.h")
@:unreflective
@:structAccess
@:keep
@:native("ma_engine")
extern class MAEngine {}

@:buildXml('<include name="../../../../source/ma/MiniAudioBuild.xml" />')
@:include("miniaudio.h")
@:unreflective
@:structAccess
@:keep
@:native("ma_sound")
extern class MASound {}

@:buildXml('<include name="../../../../source/ma/MiniAudioBuild.xml" />')
@:include("miniaudio.h")
@:unreflective
@:structAccess
@:keep
@:native("ma_sound_group")
extern class MAGroup {}

@:buildXml('<include name="../../../../source/ma/MiniAudioBuild.xml" />')
@:include("miniaudio.h")
@:unreflective
@:structAccess
@:keep
@:native("ma_resource_manager")
extern class MAResMan {}

@:buildXml('<include name="../../../../source/ma/MiniAudioBuild.xml" />')
@:include("audiostuff.cpp")
@:unreflective
@:keep
extern class MiniAudio
{
	@:native("init") public static function init(resourceManager:RawPointer<MAResMan>):RawPointer<MAEngine>;
	@:native("uninit") public static function uninit(engine:RawPointer<MAEngine>):Void;
	@:native("init_resource") public static function init_resource():RawPointer<MAResMan>;
	@:native("uninit_resource") public static function uninit_resource(resourceManager:RawPointer<MAResMan>):Void;
	@:native("loadSound") public static function loadSound(engine:RawPointer<MAEngine>, path:ConstCharStar, group:RawPointer<MAGroup> = null):RawPointer<MASound>;
	@:native("startSound") public static function startSound(sound:RawPointer<MASound>):Int;
	@:native("stopSound") public static function stopSound(sound:RawPointer<MASound>):Int;
	@:native("pauseSound") public static function pauseSound(sound:RawPointer<MASound>):Int;
	@:native("destroySound") public static function destroySound(sound:RawPointer<MASound>):Void;
	@:native("setVolume") public static function setVolume(sound:RawPointer<MASound>, vol:Float):Void;
	@:native("getVolume") public static function getVolume(sound:RawPointer<MASound>):Float;
	@:native("isPlaying") public static function isPlaying(sound:RawPointer<MASound>):Bool;
	@:native("isDone") public static function isDone(sound:RawPointer<MASound>):Bool;
	@:native("setPitch") public static function setPitch(sound:RawPointer<MASound>, vol:Float):Void;
	@:native("getPitch") public static function getPitch(sound:RawPointer<MASound>):Float;
	@:native("getTime") public static function getTime(sound:RawPointer<MASound>):Float;
	@:native("getLength") public static function getLength(sound:RawPointer<MASound>):Float;
	@:native("setTime") public static function setTime(sound:RawPointer<MASound>, timeInSec:Float):Void;
	@:native("setLooping") public static function setLooping(sound:RawPointer<MASound>, shouldLoop:Bool):Void;
	@:native("getLooping") public static function getLooping(sound:RawPointer<MASound>):Bool;
	@:native("makeGroup") public static function makeGroup(engine:RawPointer<MAEngine>):RawPointer<MAGroup>;
	@:native("startGroup") public static function startGroup(group:RawPointer<MAGroup>):Int;
	@:native("haltGroup") public static function haltGroup(group:RawPointer<MAGroup>):Int;
	@:native("killGroup") public static function killGroup(group:RawPointer<MAGroup>):Void;
}