package;

import away3d.animators.*;
import away3d.containers.*;
import away3d.controllers.*;
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
import away3d.utils.Cast;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxDestroyUtil;
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLFramebuffer;
import lime.utils.UInt8Array;
import openfl.Assets;
import openfl.Vector;
import openfl.display.*;
import openfl.display3D.textures.RectangleTexture;
import openfl.events.*;
import openfl.filters.*;
import openfl.geom.*;
import openfl.text.*;
import openfl.ui.*;
import openfl.utils.ByteArray;
import sys.io.FileOutput;

class ModelView
{
	public var view:View3D;
	public var cameraController:HoverController;

	public var lookAtObject:ObjectContainer3D;

	public var light:DirectionalLight;
	public var lightPicker:StaticLightPicker;
	public var shadowMapMethod:ShadowMapMethodBase;
	public var distance(get, set):Float;
	public var pan(get, set):Float;
	public var tilt(get, set):Float;

	public function new(ambient:Float, specular:Float, diffuse:Float, near:Float, far:Float)
	{
		view = new View3D();
		view.backgroundAlpha = 0;

		FlxG.game.stage.addChild(view);

		lookAtObject = new ObjectContainer3D();
		lookAtObject.x = lookAtObject.y = lookAtObject.z = 0;
		view.scene.addChild(lookAtObject);

		cameraController = new HoverController(view.camera, lookAtObject, 90, 0, 300);
		cameraController.wrapPanAngle = true;
		view.camera.lens.near = near;
		view.camera.lens.far = far;

		light = new DirectionalLight(0., -0.7, -0.7);
		lightPicker = new StaticLightPicker([light]);
		view.scene.addChild(light);
		light.ambient = ambient;
		light.specular = specular;
		light.diffuse = diffuse;

		shadowMapMethod = new FilteredShadowMapMethod(light);
	}

	public function update()
	{
		view.render();
	}

	public function addModel(model:Mesh)
	{
		view.scene.addChild(model);
	}

	public function setCamLookAt(x:Float, y:Float, z:Float)
	{
		lookAtObject.x = x;
		lookAtObject.y = y;
		lookAtObject.z = z;
	}

	public function set_pan(pan:Float)
	{
		return cameraController.panAngle = pan;
	}

	public function get_pan():Float
	{
		return cameraController.panAngle;
	}

	public function set_tilt(tilt:Float)
	{
		return cameraController.tiltAngle = tilt;
	}

	public function get_tilt():Float
	{
		return cameraController.tiltAngle;
	}

	public function set_distance(dist:Float)
	{
		return cameraController.distance = dist;
	}

	public function get_distance():Float
	{
		return cameraController.distance;
	}

	public function setCamPos(x:Float, y:Float, z:Float)
	{
		view.camera.x = x;
		view.camera.y = y;
		view.camera.z = z;
	}

	public function destroy()
	{
		cameraController = null;
		if (lookAtObject != null)
			lookAtObject.dispose();
		lookAtObject = null;
		if (view.camera != null)
		{
			view.camera.disposeWithChildren();
			view.camera.disposeAsset();
		}
		if (light != null)
			light.disposeWithChildren();
		light = null;
		if (lightPicker != null)
			lightPicker.dispose();
		lightPicker = null;
		if (shadowMapMethod != null)
			shadowMapMethod.dispose();
		shadowMapMethod = null;
		for (i in view.scene.numChildren - 1...-1)
		{
			if (view.scene.getChildAt(i) != null)
			{
				view.scene.getChildAt(i).disposeWithChildren();
				view.scene.removeChildAt(i);
			}
		}
		FlxG.game.stage.removeChild(view);
		view.dispose();
		view = null;
	}
}
