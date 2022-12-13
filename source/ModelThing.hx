package;

import away3d.textures.ATFTexture;
import away3d.animators.*;
import away3d.animators.data.Skeleton;
import away3d.animators.nodes.SkeletonClipNode;
import away3d.animators.nodes.VertexClipNode;
import away3d.animators.transitions.CrossfadeTransition;
import away3d.containers.*;
import away3d.controllers.*;
import away3d.core.base.Geometry;
import away3d.debug.*;
import away3d.entities.*;
import away3d.events.*;
import away3d.library.*;
import away3d.library.assets.*;
import away3d.lights.*;
import away3d.loaders.parsers.*;
import away3d.materials.*;
import away3d.materials.lightpickers.*;
import away3d.materials.methods.*;
import away3d.primitives.*;
import away3d.textures.BitmapCubeTexture;
import away3d.textures.BitmapTexture;
import away3d.tools.commands.Explode;
import away3d.tools.utils.Bounds;
import away3d.utils.Cast;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.Assets;
import openfl.Vector;
import openfl.display.*;
import openfl.events.*;
import openfl.filters.*;
import openfl.geom.*;
import openfl.net.URLRequest;
import openfl.system.System;
import openfl.text.*;
import openfl.ui.*;
import openfl.utils.ByteArray;
import sys.FileSystem;

class ModelThing
{
	public var modelMaterial:TextureMaterial;

	public var mesh:Mesh;

	private var scale:Float;

	private var skeletonAnimator:SkeletonAnimator;

	public var animationSetSkeleton:SkeletonAnimationSet;

	private var stateTransition:CrossfadeTransition;
	private var skeleton:Skeleton;
	private var animationMap:Map<String, ByteArray>;

	public var modelType:String;
	public var modelName:String;

	public var modelView:ModelView;

	public var fullyLoaded:Bool = false;
	public var animSpeed:Map<String, Float>;
	public var noLoopList:Array<String>;

	public var currentAnim:String = "";
	public var currentTime(get, never):Int;

	public var initYaw:Float;
	public var initPitch:Float;
	public var initRoll:Float;

	public var xOffset:Float = 0;
	public var yOffset:Float = 0;
	public var zOffset:Float = 0;

	var nodeCount:Int = 0;
	var nodesProcessed:Int = 0;

	var flipSingAnims:Bool = false;

	public var bitmapTexture:BitmapTexture;

	var atfBytes:ByteArray;
	var atfTex:ATFTexture;

	var geos:Map<String, Geometry> = [];

	public function new(view:ModelView, modelName:String, modelType:String, animSpeed:Map<String, Float>, noLoopList:Array<String>, modelScale:Float,
			initYaw:Float, initPitch:Float, initRoll:Float, xOffset:Float, yOffset:Float, zOffset:Float, flipSingAnims:Bool, antialiasing:Bool,
			atf:Bool = false, ambient:Float = 0, specular:Float = 0, light:Bool = false, jointsPerVertex:Int = 4)
	{
		this.modelType = modelType;
		this.animSpeed = animSpeed;
		this.noLoopList = noLoopList;
		this.scale = modelScale;
		this.initYaw = initYaw;
		this.initPitch = initPitch;
		this.initRoll = initRoll;
		this.xOffset = xOffset;
		this.yOffset = yOffset;
		this.zOffset = zOffset;
		this.flipSingAnims = flipSingAnims;
		this.modelName = modelName;

		if (!Assets.exists('assets/models/' + modelName + '/' + modelName + '.awd'))
		{
			trace("ERROR: MODEL OF NAME '" + modelName + ".awd' CAN'T BE FOUND!");
			return;
		}
		animationSetSkeleton = new SkeletonAnimationSet(jointsPerVertex);
		stateTransition = new CrossfadeTransition(0.1);

		modelView = view;
		modelView.cameraController.panAngle = 90;
		modelView.cameraController.tiltAngle = 0;

		Asset3DLibrary.enableParser(AWDParser);
		Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetCompleteAWD);
		Asset3DLibrary.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceCompleteAWD);
		// Asset3DLibrary.loadData(modelBytes);
		LoadingCount.expand();
		Asset3DLibrary.load(new URLRequest('assets/models/' + modelName + '/' + modelName + '.awd'));

		if (atf)
		{
			if (!Assets.exists('assets/models/' + modelName + '/' + modelName + '.atf'))
			{
				trace("ERROR: TEXTURE OF NAME '" + modelName + "'.atf CAN'T BE FOUND!");
				return;
			}
			atfBytes = ByteArray.fromFile('assets/models/' + modelName + '/' + modelName + '.atf');
			atfTex = new ATFTexture(atfBytes);
			modelMaterial = new TextureMaterial(atfTex);
		}
		else
		{
			if (!Assets.exists('assets/models/' + modelName + '/' + modelName + '.png'))
			{
				trace("ERROR: TEXTURE OF NAME '" + modelName + "'.png CAN'T BE FOUND!");
				return;
			}
			bitmapTexture = Cast.bitmapTexture('assets/models/' + modelName + '/' + modelName + '.png');
			modelMaterial = new TextureMaterial(bitmapTexture, antialiasing);
		}

		if (light)
		{
			modelMaterial.lightPicker = modelView.lightPicker;
			modelMaterial.shadowMethod = modelView.shadowMapMethod;
		}
		modelMaterial.gloss = 30;
		modelMaterial.alpha = 1.0;
		modelMaterial.ambient = ambient;
		modelMaterial.specular = specular;
	}

	private function onAssetCompleteAWD(event:Asset3DEvent):Void
	{
		if (event.asset.assetType == Asset3DType.SKELETON)
		{
			trace("SKELLY");
			if (StringTools.startsWith(event.asset.name, modelName + "_"))
			{
				skeleton = cast(event.asset, Skeleton);
				System.gc();
			}
		}
		else if (event.asset.assetType == Asset3DType.ANIMATION_NODE)
		{
			if (StringTools.startsWith(event.asset.name, modelName + "_"))
			{
				var node:SkeletonClipNode = cast(event.asset, SkeletonClipNode);
				trace("NODE: " + node.name);
				node.name = StringTools.replace(node.name, modelName + "_", "");
				trace(node.name);
				animationSetSkeleton.addAnimation(node);
				if (noLoopList.contains(node.name))
					node.looping = false;
				System.gc();
			}
		}
		else if (event.asset.assetType == Asset3DType.MESH)
		{
			if (StringTools.startsWith(event.asset.name, modelName + "_"))
			{
				mesh = cast(event.asset, Mesh);
				trace("MESH: " + mesh.name);
				mesh.material = modelMaterial;
				mesh.castsShadows = true;
				mesh.scaleX = scale;
				mesh.scaleY = scale;
				mesh.scaleZ = scale;
				mesh.yaw(initYaw);
				mesh.pitch(initPitch);
				mesh.roll(initRoll);
				System.gc();
			}
		}
		else if (event.asset.assetType == Asset3DType.GEOMETRY)
		{
			if (StringTools.startsWith(event.asset.name, modelName + "_"))
			{
				var geo = cast(event.asset, Geometry);
				trace("GEO: " + geo.name);
				geo.name = StringTools.replace(geo.name, modelName + "_", "");
				geos.set(geo.name, geo);
				System.gc();
			}
		}
	}

	private function onResourceCompleteAWD(event:LoaderEvent):Void
	{
		if (StringTools.endsWith(event.url, modelName + ".awd"))
		{
			trace("DONE COMPLETE");
			if (skeleton != null)
			{
				skeletonAnimator = new SkeletonAnimator(animationSetSkeleton, skeleton);
				mesh.animator = skeletonAnimator;
			}
			render(xOffset, yOffset, zOffset);
			begoneEventListeners();
			System.gc();
			LoadingCount.increment();
		}
	}

	public function render(xPos:Float = 0, yPos:Float = 0, zPos:Float = 0):Void
	{
		mesh.y = yPos;
		mesh.x = xPos;
		mesh.z = zPos;
		modelView.addModel(mesh);
		fullyLoaded = true;

		if (flipSingAnims)
		{
			var lefts = ['singLEFT', 'singLEFTmiss', 'singLEFTEnd', 'singLEFTmissEnd'];
			var rights = ['singRIGHT', 'singRIGHTmiss', 'singRIGHTEnd', 'singRIGHTmissEnd'];
			for (i in 0...rights.length)
			{
				if (animationSetSkeleton.hasAnimation(rights[i]) && animationSetSkeleton.hasAnimation(lefts[i]))
				{
					var right = animationSetSkeleton.getAnimation(rights[i]);
					var left = animationSetSkeleton.getAnimation(lefts[i]);
					@:privateAccess
					animationSetSkeleton._animationDictionary[rights[i]] = left;
					@:privateAccess
					animationSetSkeleton._animationDictionary[lefts[i]] = right;
				}
			}
		}

		if (animationSetSkeleton.hasAnimation('idleEnd'))
			playAnim("idleEnd");
		else if (animationSetSkeleton.hasAnimation('idle'))
			playAnim('idle');
		else if (animationSetSkeleton.hasAnimation('danceRIGHT'))
			playAnim('danceRIGHT');
	}

	public function update()
	{
	}

	public function playAnim(anim:String = "", force:Bool = false, offset:Int = 0, geo:String = "")
	{
		if (fullyLoaded)
		{
			if (animationSetSkeleton.animationNames.indexOf(anim) != -1)
			{
				if (force || currentAnim != anim)
				{
					var newSpeed:Float = 1.0;
					if (animSpeed.exists(anim))
						newSpeed = animSpeed[anim];
					else
						newSpeed = animSpeed["default"];
					if (skeletonAnimator == null)
					{
						trace("WTF LAME");
						return;
					}

					if (geo != "")
					{
						if (geos[geo] != null)
						{
							mesh.geometry = geos[geo];
						}
						else
						{
							trace("GEO NAME OF " + geo + " NOT FOUND FOR " + modelName);
						}
					}

					skeletonAnimator.playbackSpeed = newSpeed;
					skeletonAnimator.play(anim, stateTransition, offset);
					currentAnim = anim;
				}
			}
			// else
			// 	trace("ANIMATION NAME " + anim + " NOT FOUND.");
		}
		else
			trace("MODEL NOT FULLY LOADED. NO ANIMATION WILL PLAY.");
	}

	public function destroy()
	{
		begoneEventListeners();
		if (mesh != null)
		{
			if (mesh.geometry != null)
				mesh.geometry.dispose();
			mesh.geometry = null;
			mesh.material = null;
			mesh.disposeWithChildren();
		}
		mesh = null;

		for (geo in geos)
		{
			if (geo != null)
				geo.dispose();
		}
		geos.clear();
		geos = null;

		if (animationSetSkeleton != null)
		{
			animationSetSkeleton.dispose();
		}
		animationSetSkeleton = null;
		if (skeleton != null)
		{
			skeleton.dispose();
		}
		skeleton = null;
		if (skeletonAnimator != null)
		{
			skeletonAnimator.stop();
			skeletonAnimator.dispose();
		}
		skeletonAnimator = null;
		stateTransition = null;

		animationMap = null;

		if (bitmapTexture != null)
		{
			if (bitmapTexture.bitmapData != null)
			{
				bitmapTexture.bitmapData.disposeImage();
				bitmapTexture.bitmapData.dispose();
			}
			bitmapTexture.dispose();
			bitmapTexture = null;
		}
		if (atfTex != null)
		{
			atfTex.dispose();
		}
		atfTex = null;
		if (atfBytes != null)
		{
			atfBytes.clear();
		}
		atfBytes = null;
		if (modelMaterial != null)
		{
			if (modelMaterial.texture != null)
			{
				modelMaterial.texture.dispose();
			}
			if (modelMaterial.ambientTexture != null)
				modelMaterial.ambientTexture.dispose();
			modelMaterial.texture = null;
			modelMaterial.ambientTexture = null;

			modelMaterial.dispose();
		}
		modelMaterial = null;
		modelView = null;
		if (noLoopList != null)
			noLoopList.resize(0);
		noLoopList = null;
		animSpeed.clear();
		animSpeed = null;
		System.gc();
	}

	public function begoneEventListeners()
	{
		trace("DEAD");
		// Asset3DLibrary.stopLoad();
		Asset3DLibrary.removeEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetCompleteAWD);
		Asset3DLibrary.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceCompleteAWD);
	}

	public function addYaw(angle:Float)
	{
		mesh.yaw(angle);
	}

	public function addPitch(angle:Float)
	{
		mesh.pitch(angle);
	}

	public function addRoll(angle:Float)
	{
		mesh.roll(angle);
	}

	public function get_currentTime()
	{
		if (skeletonAnimator == null)
			return 0;
		return skeletonAnimator.time;
	}
}
