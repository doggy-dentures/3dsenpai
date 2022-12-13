package;

import openfl.net.SharedObject;
import haxe.Unserializer;
import sys.io.File;
import sys.FileSystem;
import openfl.system.System;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.FPS;
import openfl.display.Sprite;

class Main extends Sprite
{
	public static var fpsDisplay:FPS_Mem;

	public static var novid:Bool = false;
	public static var flippymode:Bool = false;

	public static var goodThing:Bool = false;

	public function new()
	{
		super();

		#if sys
		novid = Sys.args().contains("-novid");
		flippymode = Sys.args().contains("-flippymode");
		#end

		addChild(new FlxGame(0, 0, Startup, 1, 144, 144, true));

		#if !mobile
		fpsDisplay = new FPS_Mem(10, 3, 0xFFFFFF);
		fpsDisplay.visible = true;
		addChild(fpsDisplay);
		switch (FlxG.save.data.fpsDisplayValue)
		{
			case 0:
				Main.fpsDisplay.visible = true;
				Main.fpsDisplay.showMem = true;
			case 1:
				Main.fpsDisplay.visible = true;
				Main.fpsDisplay.showMem = false;
			case 2:
				Main.fpsDisplay.visible = false;
		}
		#end

		FlxG.signals.postStateSwitch.add(function()
		{
			System.gc();
		});

		// On web builds, video tends to lag quite a bit, so this just helps it run a bit faster.
		#if web
		VideoHandler.MAX_FPS = 30;
		#end

		trace("-=Args=-");
		trace("novid: " + novid);
		trace("flippymode: " + flippymode);
	}
}
