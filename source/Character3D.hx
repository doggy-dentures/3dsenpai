package;

import flixel.FlxBasic;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.addons.display.FlxNestedSprite;
import flixel.util.FlxDestroyUtil;
import haxe.macro.Type.AnonStatus;
import flixel.system.FlxAssets.FlxGraphicAsset;
import openfl.display.BitmapData;
import flixel.FlxG;
import openfl.display3D.Context3DTextureFormat;
import openfl.Assets;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class Character3D extends FlxBasic
{
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';

	public var holdTimer:Float = 0;

	public var canAutoAnim:Bool = true;
	public var canAutoIdle:Bool = true;

	// 3D
	public var modelView:ModelView;
	public var beganLoading:Bool = false;
	public var modelName:String = "";
	public var modelScale:Float = 1;
	public var model:ModelThing;
	public var initYaw:Float = 0;
	public var initPitch:Float = 0;
	public var initRoll:Float = 0;
	public var xOffset:Float = 0;
	public var yOffset:Float = 0;
	public var zOffset:Float = 0;
	public var ambient:Float = 1;
	public var specular:Float = 1;
	public var diffuse:Float = 1;
	public var animSpeed:Map<String, Float> = new Map<String, Float>();
	public var noLoopList:Array<String> = [];
	public var geoMap:Map<String, String> = new Map<String, String>();
	public var atf:Bool = false;
	public var light:Bool = false;
	public var jointsPerVertex:Int = 4;

	public function new(modelView:ModelView, ?character:String = "bf", ?isPlayer:Bool = false)
	{
		super();

		curCharacter = character;
		this.isPlayer = isPlayer;

		var antialias = true;

		switch (curCharacter)
		{
			case 'bf':
				modelName = 'bf';
				modelScale = 1;
				animSpeed = ["default" => 1];
				noLoopList = ["idle", "singUP", "singLEFT", "singRIGHT", "singDOWN"];
				ambient = 0;
				specular = 0;
				diffuse = 1;
				initYaw = 65;
				zOffset = 150;
				geoMap = [
					"singUP" => "singUP",
					"singRIGHT" => "singRIGHT",
					"singDOWN" => "singDOWN",
					"idle" => "default",
					"idleEnd" => "default",
					"singLEFT" => "singUP"
				];
				atf = true;
			case 'gf':
				modelName = 'gf';
				modelScale = 1;
				animSpeed = ["default" => 1];
				noLoopList = ["danceLEFT", "danceRIGHT"];
				ambient = 0;
				specular = 0;
				diffuse = 1;
				xOffset = -100;
				yOffset = -20;
				atf = true;
			case 'senpai':
				modelName = 'senpai';
				modelScale = 1;
				animSpeed = ["default" => 1];
				noLoopList = ["idle", "singUP", "singLEFT", "singRIGHT", "singDOWN"];
				ambient = 0;
				specular = 0;
				diffuse = 1;
				initYaw = -65;
				zOffset = -150;
				yOffset = 70;
				geoMap = [
					"singUP" => "singUP",
					"singRIGHT" => "singRIGHT",
					"singDOWN" => "singDOWN",
					"singLEFT" => "singLEFT",
					"idle" => "default",
					"idleEnd" => "default"
				];
				antialias = false;
			case 'senpai-angry':
				modelName = 'senpai-angry';
				modelScale = 1;
				animSpeed = ["default" => 1];
				noLoopList = ["idle", "singUP", "singLEFT", "singRIGHT", "singDOWN"];
				ambient = 0;
				specular = 0;
				diffuse = 1;
				initYaw = -65;
				zOffset = -150;
				yOffset = 70;
				geoMap = [
					"singUP" => "singUP",
					"singRIGHT" => "singRIGHT",
					"singDOWN" => "singDOWN",
					"singLEFT" => "singLEFT",
					"idle" => "default",
					"idleEnd" => "default"
				];
				antialias = false;
			case 'hydra':
				modelName = 'hydra';
				modelScale = 1;
				animSpeed = ["default" => 1];
				noLoopList = ["idle", "singUP", "singLEFT", "singRIGHT", "singDOWN"];
				ambient = 0.5;
				specular = 0.5;
				diffuse = 1;
				initYaw = 0;
				xOffset = -150;
				yOffset = 120;
				atf = true;
				light = true;
				jointsPerVertex = 1;
		}

		this.modelView = modelView;
		model = new ModelThing(modelView, modelName, 'awd', animSpeed, noLoopList, modelScale, initYaw, initPitch, initRoll, xOffset, yOffset, zOffset, false,
			antialias, atf, ambient, specular, light, jointsPerVertex);

		dance();
	}

	override function update(elapsed:Float)
	{
		if (model == null || !model.fullyLoaded)
			return;

		if (PlayState.instance.endingSong)
			return;

		if (model != null && model.fullyLoaded && modelView != null)
		{
			model.update();
		}

		if (!isPlayer)
		{
			if (getCurAnim().startsWith('sing'))
			{
				holdTimer += elapsed;
			}

			var dadVar:Float = 4;

			if (curCharacter == 'dad')
				dadVar = 6.1;
			if (holdTimer >= Conductor.stepCrochet * dadVar * 0.001)
			{
				idleEnd();
				holdTimer = 0;
			}
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(?ignoreDebug:Bool = false)
	{
		if (PlayState.instance.endingSong)
			return;

		if (!model.fullyLoaded)
			return;

		if (!debugMode || ignoreDebug)
		{
			switch (curCharacter)
			{
				case 'gf' | 'gf-car' | 'gf-christmas' | 'gf-pixel':
					if (!getCurAnim().startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRIGHT', true);
						else
							playAnim('danceLEFT', true);
					}
				default:
					if (holdTimer == 0)
					{
						if (model == null)
						{
							trace("NO DANCE - NO MODEL");
							return;
						}
						if (!model.fullyLoaded)
						{
							trace("NO DANCE - NO FULLY LOAD");
							return;
						}
						if (!noLoopList.contains('idle'))
							return;
						playAnim('idle', true);
					}
			}
		}
		else if (holdTimer == 0)
		{
			if (model == null)
			{
				trace("NO DANCE - NO MODEL");
				return;
			}
			if (!model.fullyLoaded)
			{
				trace("NO DANCE - NO FULLY LOAD");
				return;
			}
			if (!noLoopList.contains('idle'))
				return;
			playAnim('idle', true);
		}
	}

	public function idleEnd(?ignoreDebug:Bool = false)
	{
		if (PlayState.instance.endingSong)
			return;

		if (!model.fullyLoaded)
			return;

		if ((!debugMode || ignoreDebug))
		{
			if (animExists(getCurAnim() + "End"))
				playAnim(getCurAnim() + "End", true, false);
			else if (animExists('idleEnd'))
				playAnim('idleEnd', true, false);
			else
				playAnim('idle', true);
		}
	}

	var curAtlasAnim:String;

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (PlayState.instance.endingSong)
			return;

		if (!model.fullyLoaded)
			return;

		if (AnimName.endsWith('-alt') && !animExists(AnimName))
		{
			AnimName = AnimName.substring(0, AnimName.length - 4);
		}

		if (AnimName.contains('sing'))
			canAutoIdle = true;

		var geo:String = "";
		if (geoMap[AnimName] != null)
			geo = geoMap[AnimName];

		if (AnimName.endsWith('miss'))
		{
			if (!animExists(AnimName))
				AnimName = AnimName.substring(0, AnimName.length - 4);
			geo = "miss";
			model.modelMaterial.colorTransform.redMultiplier = 0.2;
			model.modelMaterial.colorTransform.greenMultiplier = 0.2;
			model.modelMaterial.colorTransform.blueMultiplier = 0.75;
		}
		else
		{
			model.modelMaterial.colorTransform.redMultiplier = 1;
			model.modelMaterial.colorTransform.greenMultiplier = 1;
			model.modelMaterial.colorTransform.blueMultiplier = 1;
		}

		if (model != null && model.fullyLoaded)
		{
			model.playAnim(AnimName, Force, Frame, geo);
		}
	}

	public function getCurAnim()
	{
		if (model != null && model.fullyLoaded)
			return model.currentAnim;
		else
			return "";
	}

	public function animExists(anim:String)
	{
		if (model != null && model.fullyLoaded)
			return model.animationSetSkeleton.hasAnimation(anim);
		else
			return false;
	}

	override public function destroy()
	{
		if (model != null)
			model.destroy();
		model = null;
		modelView = null;
		if (animSpeed != null)
		{
			animSpeed.clear();
			animSpeed = null;
		}
		super.destroy();
	}
}
