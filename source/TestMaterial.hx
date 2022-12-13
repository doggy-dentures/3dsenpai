import openfl.display3D.textures.TextureBase;
import away3d.cameras.Camera3D;
import away3d.core.base.IRenderable;
import away3d.core.managers.Stage3DProxy;
import away3d.materials.MaterialBase;
import away3d.materials.passes.MaterialPassBase;
import away3d.textures.Texture2DBase;
import openfl.Assets;
import openfl.Vector;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.geom.Matrix3D;

class TestMaterial extends MaterialBase
{
	var passthing:TrivialColorPass;

	public function new()
	{
		super();
		passthing = new TrivialColorPass();
		addPass(passthing);
	}

	public function set_texture(tex:Texture2DBase)
	{
		passthing.set_texture(tex);
	}

	public function set_screenTex(tex:TextureBase)
	{
		passthing.set_screenTex(tex);
	}

	public function set_fragment(x:Float, y:Float, z:Float, w:Float)
	{
		passthing.set_fragment(x, y, z, w);
	}
}

class TrivialColorPass extends MaterialPassBase
{
	var _texture:Texture2DBase;
	// var _texture2:Texture2DBase;
	var _fragmentData:Vector<Float> = new Vector<Float>();
	var screenTex:TextureBase;

	var _matrix:Matrix3D = new Matrix3D();

	override function getVertexCode()
	{
		return "m44 op, va0, vc0\n" + "mov v0, va1";
	}

	override function getFragmentCode(fragmentAnimatorCode:String):String
	{
		// return "ifg v0.x, 0\ntex oc, v0, fs1 <2d, clamp, nearest, nomip>\neif";
		return Assets.getText("assets/agal/test.txt");
	}

	override function activate(stage3DProxy:Stage3DProxy, camera:Camera3D)
	{
		super.activate(stage3DProxy, camera);
		@:privateAccess
		stage3DProxy._context3D.setTextureAt(0, _texture.getTextureForStage3D(stage3DProxy));
		@:privateAccess
		// stage3DProxy._context3D.setTextureAt(1, _texture2.getTextureForStage3D(stage3DProxy));
		@:privateAccess
		stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentData, 1);
	}

	override function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D)
	{
		@:privateAccess
		var context = stage3DProxy._context3D;
		_matrix.copyFrom(renderable.sceneTransform);
		_matrix.append(viewProjection);

		renderable.activateVertexBuffer(0, stage3DProxy);
		renderable.activateUVBuffer(1, stage3DProxy);

		@:privateAccess
		stage3DProxy._context3D.setTextureAt(1, screenTex);

		context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _matrix, true);
		context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
	}

	override function deactivate(stage3DProxy:Stage3DProxy)
	{
		super.deactivate(stage3DProxy);

		@:privateAccess
		var context:Context3D = stage3DProxy._context3D;

		context.setTextureAt(0, null);
		context.setTextureAt(1, null);
		context.setVertexBufferAt(1, null);
	}

	public function get_texture():Texture2DBase
	{
		return _texture;
	}

	public function set_texture(value:Texture2DBase)
	{
		return _texture = value;
	}


	public function set_screenTex(value:TextureBase)
	{
		return screenTex = value;
	}

	public function set_fragment(x:Float, y:Float, z:Float, w:Float)
	{
		_fragmentData[0] = x;
		_fragmentData[1] = y;
		_fragmentData[2] = z;
		_fragmentData[3] = w;
	}
}
