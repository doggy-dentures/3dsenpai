import openfl.display3D.textures.TextureBase;
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

class TVModel extends ModelThing
{
	public var customMat:TestMaterial;

	public var texture:TextureBase;

	override public function new(texture:TextureBase, view:ModelView, modelName:String, modelType:String, animSpeed:Map<String, Float>,
			noLoopList:Array<String>, modelScale:Float, initYaw:Float, initPitch:Float, initRoll:Float, xOffset:Float, yOffset:Float, zOffset:Float,
			flipSingAnims:Bool, antialiasing:Bool, atf:Bool = false)
	{
		super(view, modelName, modelType, animSpeed, noLoopList, modelScale, initYaw, initPitch, initRoll, xOffset, yOffset, zOffset, flipSingAnims,
			antialiasing, atf, 0.5, 0.5, true);

		customMat = new TestMaterial();
		customMat.set_texture(atfTex);
		customMat.set_screenTex(texture);
		customMat.set_fragment(0.5, 0.28125, 0, 0);
		this.texture = texture;
	}

	public function screenTex(tex:TextureBase)
	{
		customMat.set_screenTex(tex);
	}

	override private function onResourceCompleteAWD(event:LoaderEvent):Void
	{
		if (StringTools.endsWith(event.url, modelName + ".awd"))
		{
			trace("DONE COMPLETE TV");
			mesh.material = customMat;
			render(xOffset, yOffset, zOffset);
			begoneEventListeners();
			System.gc();
			LoadingCount.increment();
		}
	}

	override public function destroy()
	{
		customMat.dispose();
		texture = null;
		super.destroy();
	}
}
