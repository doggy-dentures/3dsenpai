import transition.data.ScreenWipeIn;
import transition.CustomTransition;
import transition.data.BasicTransition;
import openfl.utils.ByteArray;
import away3d.textures.ATFTexture;
import config.Config;
import transition.data.WeirdBounceOut;
import config.ConfigMenu;
import transition.data.IconOut;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.system.FlxSound;
import away3d.materials.methods.OutlineMethod;
import away3d.primitives.SkyBox;
import away3d.textures.BitmapCubeTexture;
import flixel.util.FlxDestroyUtil;
import away3d.textures.BitmapTexture;
import haxe.Json;
import openfl.Assets;
import flixel.FlxCamera;
import away3d.controllers.HoverController;
import lime.app.Application;
import away3d.materials.TextureMaterial;
import away3d.utils.Cast;
import openfl.net.URLRequest;
import away3d.library.assets.Asset3DType;
import away3d.events.LoaderEvent;
import away3d.events.Asset3DEvent;
import away3d.loaders.parsers.AWDParser;
import away3d.library.Asset3DLibrary;
import away3d.entities.Mesh;
import flixel.math.FlxPoint;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.tile.FlxTilemap;
import flixel.addons.editors.ogmo.FlxOgmo3Loader;
import flixel.FlxState;

class Overworld extends UIStateExt
{
	var map:FlxOgmo3Loader;
	var floor:FlxTilemap;
	var walllayers:Array<FlxTilemap> = [];
	var player:OPlayer;
	var portals:Array<PortalSpr> = [];
	var stairs:Array<FloorSpr> = [];
	var pass:FlxSprite;
	var gate:FlxSprite;

	var view:ModelView;
	var block:Mesh;
	var bf:ModelThing;
	var cam2d:FlxCamera;

	var steps:FlxSound;

	var skybox:SkyBox;
	var skyboxTex:BitmapCubeTexture;

	var planeBitmap:BitmapTexture;
	var planeMat:TextureMaterial;

	var bmMap:Map<String, BitmapTexture> = [];
	var texMap:Map<String, TextureMaterial> = [];
	var tileToTexData:Map<Int, OWTile> = [];
	var meshClones:Array<Mesh> = [];

	var objs:Array<BasicObj> = [];
	var objMap:Map<String, BasicObj> = [];

	var xOffset:Float = 35;
	var zOffset:Float = -35;
	var yOffset:Float = 0;
	var curFloor:Int = 0;
	var curStair:FloorSpr;

	var yTween:FlxTween;

	var black:FlxSprite;

	var paused:Bool = false;

	var tmpIgnore:Map<String, Bool> = [];

	public var selected:Bool = false;
	public var options:Bool = false;

	public var didPass:Bool = false;

	var mouseSpr:FlxSprite;
	var wasdSpr:FlxSprite;
	var waitTmr:FlxTimer;

	var wtf:FlxSprite;

	override public function create()
	{
		customTransIn = new BasicTransition();

		super.create();

		if (Config.noFpsCap)
			openfl.Lib.current.stage.frameRate = 999;
		else
			openfl.Lib.current.stage.frameRate = 144;

		PlayState.seenDialogue = false;

		FlxG.fixedTimestep = false;

		persistentDraw = true;
		persistentUpdate = true;

		LoadingCount.reset();

		bgColor = FlxColor.TRANSPARENT;

		view = new ModelView(0, 0, 1, 1, Config.lowRes ? 3000 : 6000, Config.lowRes);

		if (Config.lowRes)
		{
			add(view.sprite);
			var lowest = Math.min(FlxG.width / view.sprite.width, FlxG.height / view.sprite.height);
			view.sprite.scale.set(lowest, lowest);
			view.sprite.updateHitbox();
			view.sprite.screenCenter(XY);
			view.sprite.shader = new PSXShader();
		}
		else
		{
			view.view.width = FlxG.scaleMode.gameSize.x;
			view.view.height = FlxG.scaleMode.gameSize.y;
			view.view.x = FlxG.stage.stageWidth / 2 - FlxG.scaleMode.gameSize.x / 2;
			view.view.y = FlxG.stage.stageHeight / 2 - FlxG.scaleMode.gameSize.y / 2;
		}

		Asset3DLibrary.enableParser(AWDParser);
		Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		Asset3DLibrary.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		LoadingCount.expand();
		Asset3DLibrary.load(new URLRequest("assets/models/cube/cube.awd"));

		skyboxTex = new BitmapCubeTexture(Cast.bitmapData("assets/models/skybox3/px.png"), Cast.bitmapData("assets/models/skybox3/nx.png"),
			Cast.bitmapData("assets/models/skybox3/py.png"), Cast.bitmapData("assets/models/skybox3/ny.png"), Cast.bitmapData("assets/models/skybox3/pz.png"),
			Cast.bitmapData("assets/models/skybox3/nz.png"));

		skybox = new SkyBox(skyboxTex);
		view.view.scene.addChild(skybox);

		bf = new ModelThing(view, "bfo", "awd", ["default" => 1], ["hey"], 1, 0, 0, 0, 0, 0, 0, false, true, true);

		if (!Config.noMouse)
		{
			Application.current.window.mouseLock = true;
			Application.current.window.onMouseMoveRelative.add(onMouseMove);
		}

		cam2d = new FlxCamera(0, 0, 320, 180);
		cam2d.zoom = 0.25;
		cam2d.visible = false;
		FlxG.cameras.add(cam2d);

		map = new FlxOgmo3Loader("assets/agal/overworld.ogmo", "assets/agal/overworld.json");
		floor = map.loadTilemap("assets/agal/overworld.png", "floor");
		floor.follow();
		floor.setTileProperties(0, ANY);
		// walls.setTileProperties(1, NONE);
		add(floor);
		floor.cameras = [cam2d];

		for (i in 0...7)
		{
			var newwall = map.loadTilemap("assets/agal/overworld.png", "walls" + i);
			newwall.active = false;
			newwall.visible = false;
			add(newwall);
			walllayers.push(newwall);
		}

		player = new OPlayer(0, 0, view.cameraController);
		add(player);
		player.cameras = [cam2d];
		cam2d.follow(player, TOPDOWN, 1);

		map.loadEntities(placeEntities, "ent");

		var jsonData = Assets.getText("assets/agal/tiledata.json");
		var tileData:OWData = Json.parse(jsonData);
		for (instance in tileData.data)
		{
			if (instance.collide)
				floor.setTileProperties(instance.id, ANY);
			else
				floor.setTileProperties(instance.id, NONE);
			tileToTexData[instance.id] = instance;
		}

		steps = new FlxSound().loadEmbedded(Paths.sound('step'), true);
		add(steps);

		if (Main.goodThing)
			didPass = true;

		mouseSpr = new FlxSprite().loadGraphic(Paths.image('mouse'));
		mouseSpr.scale.set(2, 2);
		mouseSpr.updateHitbox();
		mouseSpr.setPosition(10, FlxG.height - mouseSpr.height - 10);
		add(mouseSpr);

		wasdSpr = new FlxSprite().loadGraphic(Paths.image('wasd'));
		wasdSpr.scale.set(2, 2);
		wasdSpr.updateHitbox();
		wasdSpr.setPosition(mouseSpr.x + mouseSpr.width + 10, mouseSpr.y + mouseSpr.height / 2 - wasdSpr.height / 2);
		add(wasdSpr);

		if (Config.noMouse)
		{
			mouseSpr.visible = false;
		}

		black = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		black.setGraphicSize(FlxG.width, FlxG.height);
		black.updateHitbox();
		add(black);

		wtf = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		wtf.alpha = 0.00001;
		add(wtf);
	}

	function onLoaded()
	{
		trace("GOOD");
		planeBitmap = Cast.bitmapTexture("assets/models/cube/cube.png");
		planeMat = new TextureMaterial(planeBitmap, false, false);

		block.showBounds = false;

		bf.mesh.showBounds = false;
		bf.playAnim('stand', true);

		var wallsToParse:Array<FlxTilemap> = walllayers;

		for (i in 0...wallsToParse.length)
		{
			var wall = wallsToParse[i];

			var width = wall.widthInTiles;
			var height = wall.heightInTiles;

			for (x in 0...width)
			{
				for (y in 0...height)
				{
					var id = wall.getTile(x, y);
					if (id > 0)
					{
						var mat = planeMat;
						if (tileToTexData.exists(id))
						{
							var instance = tileToTexData[id];

							if (texMap.exists(instance.tex))
							{
								mat = texMap[instance.tex];
							}
							else
							{
								var aa = instance.aa;
								var alpha = instance.alpha;
								var bm = Cast.bitmapTexture("assets/models/cube/" + instance.tex + ".png");
								bmMap[instance.tex] = bm;
								var newmat = new TextureMaterial(bm, aa, false);
								newmat.alphaPremultiplied = false;
								newmat.alphaBlending = alpha;
								texMap[instance.tex] = newmat;
								mat = newmat;
							}
						}
						var blockCopy = new Mesh(block.geometry, mat);
						blockCopy.showBounds = false;
						view.addModel(blockCopy);
						blockCopy.x = -150 * x;
						blockCopy.z = 150 * y;
						blockCopy.y = -75 + 150 * i;
						meshClones.push(blockCopy);
					}
				}
			}
		}

		for (obj in objs)
		{
			if (obj.hasReference)
			{
				obj.placeFromReference();
			}
		}

		view.cameraController.lookAtObject = bf.mesh;
		view.cameraController.panAngle = 0;
		view.cameraController.tiltAngle = Config.noMouse ? 20 : 0;
		view.cameraController.minTiltAngle = 0;
		view.cameraController.maxTiltAngle = 50;
		view.distance = 400;

		FlxG.sound.playMusic(Paths.music('beep'), 0.6);

		black.visible = false;

		CustomTransition.transition(new ScreenWipeIn(0.8));

		waitTmr = new FlxTimer().start(0.5);
	}

	var doneLoading = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		FlxG.collide(player, floor);

		if (LoadingCount.isDone() && !doneLoading)
		{
			onLoaded();
			doneLoading = true;
		}

		if (!doneLoading)
			return;

		if (!didPass)
		{
			FlxG.collide(player, gate);
		}

		if (LoadingCount.isDone() && bf != null && bf.mesh != null)
		{
			bf.mesh.x = -player.x * (150 / 128) + xOffset;
			bf.mesh.z = player.y * (150 / 128) + zOffset;
			bf.mesh.y = -(bf.mesh.bounds.max.y) + 30 + yOffset;
			bf.mesh.rotationY = view.cameraController.panAngle + 90;
		}

		#if debug
		if (FlxG.keys.justPressed.Q)
		{
			cam2d.visible = !cam2d.visible;
		}
		#end

		if (FlxG.keys.justPressed.ESCAPE && !selected && !paused)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			switchState(new MainMenuState());
		}

		// if (FlxG.keys.justPressed.O)
		// {
		// 	xOffset--;
		// 	trace("XOFFSET: " + xOffset);
		// }
		// if (FlxG.keys.justPressed.P)
		// {
		// 	xOffset++;
		// 	trace("XOFFSET: " + xOffset);
		// }
		// if (FlxG.keys.justPressed.K)
		// {
		// 	zOffset--;
		// 	trace("ZOFFSET: " + zOffset);
		// }
		// if (FlxG.keys.justPressed.L)
		// {
		// 	zOffset++;
		// 	trace("ZOFFSET: " + zOffset);
		// }

		if (!selected)
		{
			if (!Config.noMouse)
			{
				// if (FlxG.keys.anyJustPressed([W, S, A, D, UP, DOWN, LEFT, RIGHT])
				// 	|| FlxG.keys.anyJustReleased([W, S, A, D, UP, DOWN, LEFT, RIGHT]))
				if (Math.abs(player.x - player.last.x) / FlxG.elapsed >= tolerance
					|| Math.abs(player.y - player.last.y) / FlxG.elapsed >= tolerance)
				{
					refreshMovementStuff();
				}
			}
			else
			{
				if (FlxG.keys.anyJustPressed([W, S, UP, DOWN]) || FlxG.keys.anyJustReleased([W, S, UP, DOWN]))
				{
					refreshMovementStuff();
				}
			}

			if (wasdSpr.visible && !waitTmr.active && FlxG.keys.anyPressed([W, S, A, D, UP, DOWN, LEFT, RIGHT]))
			{
				wasdSpr.visible = false;
			}

			if (Math.abs(player.x - player.last.x) / FlxG.elapsed < tolerance
				&& Math.abs(player.y - player.last.y) / FlxG.elapsed < tolerance
				&& bf.currentAnim != 'stand')
			{
				bf.playAnim('stand', true);
				steps.stop();
			}

			for (ent in portals)
			{
				var entHit = ent.getHitbox();
				var playerHit = player.getHitbox();
				var inter = entHit.intersection(playerHit);
				if (inter.width * inter.height > 3000)
				{
					if (tmpIgnore[ent.song] == false)
					{
						paused = true;
						player.paused = true;
						if (ent.song == 'options')
							openSubState(new OverworldOptions());
						else
							openSubState(new OverworldSong(ent.song));
					}
					tmpIgnore[ent.song] = true;
				}
				else
				{
					tmpIgnore[ent.song] = false;
				}
				entHit.put();
				playerHit.put();
				inter.put();
			}

			if (!didPass)
			{
				var entHit = pass.getHitbox();
				var playerHit = player.getHitbox();
				var inter = entHit.intersection(playerHit);
				if (inter.width * inter.height > 3000)
				{
					if (tmpIgnore['pass'] == false)
					{
						paused = true;
						player.paused = true;
						openSubState(new SecretPass());
					}
					tmpIgnore['pass'] = true;
				}
				else
				{
					tmpIgnore['pass'] = false;
				}
				entHit.put();
				playerHit.put();
				inter.put();
			}
		}

		for (ent in stairs)
		{
			var oldFloor = curFloor;
			var playerHit = player.getHitbox();
			var entPntL = FlxPoint.get(ent.x + stairTolerance, ent.y + ent.height / 2);
			var entPntR = FlxPoint.get(ent.x + ent.width - stairTolerance, ent.y + ent.height / 2);
			var entPntU = FlxPoint.get(ent.x + ent.width / 2, ent.y + stairTolerance);
			var entPntD = FlxPoint.get(ent.x + ent.width / 2, ent.y + ent.height - stairTolerance);
			if (curStair != ent)
			{
				if (ent.lStep > -1 && playerHit.containsPoint(entPntL))
				{
					curFloor = ent.lStep;
					curStair = ent;
				}
				if (ent.rStep > -1 && playerHit.containsPoint(entPntR))
				{
					curFloor = ent.rStep;
					curStair = ent;
				}
				if (ent.dStep > -1 && playerHit.containsPoint(entPntD))
				{
					curFloor = ent.dStep;
					curStair = ent;
				}
				if (ent.uStep > -1 && playerHit.containsPoint(entPntU))
				{
					curFloor = ent.uStep;
					curStair = ent;
				}

				if (curStair == ent)
				{
					if (yTween != null && yTween.active)
					{
						yTween.cancel();
						yTween.destroy();
					}
					var time = (curFloor > oldFloor ? 0.07 : 0.15);
					yTween = FlxTween.num(yOffset, 150 * (curFloor + 1), time, null, yTweenFunc);
				}
			}
			entPntL.put();
			entPntR.put();
			entPntU.put();
			entPntD.put();
			playerHit.put();
		}

		// if (view != null)
		// {
		// 	view.update();
		// }
	}

	override public function draw()
	{
		super.draw();
		if (view != null)
		{
			view.update();
		}
	}

	function yTweenFunc(val:Float)
	{
		yOffset = val;
	}

	static var tolerance = 5;
	static var stairTolerance = 10;

	function refreshMovementStuff()
	{
		var forward = FlxG.keys.pressed.W || FlxG.keys.pressed.UP;
		var backward = FlxG.keys.pressed.S || FlxG.keys.pressed.DOWN;
		var left = FlxG.keys.pressed.A || FlxG.keys.pressed.LEFT;
		var right = FlxG.keys.pressed.D || FlxG.keys.pressed.RIGHT;

		var offset:Int = 0;
		if (bf.currentAnim != 'stand')
			offset = bf.currentTime;

		switch (Config.noMouse)
		{
			case false:
				if ((forward || backward) && !left && !right)
				{
					if (bf.currentAnim != 'run')
						bf.playAnim('run', true, offset);
					steps.play();
				}
				else if (right)
				{
					if (!backward && bf.currentAnim != 'right')
						bf.playAnim('right', true, offset);
					else if (backward && bf.currentAnim != 'left')
						bf.playAnim('left', true, offset);
					steps.play();
				}
				else if (left)
				{
					if (!backward && bf.currentAnim != 'left')
						bf.playAnim('left', true, offset);
					else if (backward && bf.currentAnim != 'right')
						bf.playAnim('right', true, offset);
					steps.play();
				}
			case true:
				if ((forward || backward))
				{
					if (bf.currentAnim != 'run')
						bf.playAnim('run', true, offset);
					steps.play();
				}
		}
	}

	private function onAssetComplete(event:Asset3DEvent):Void
	{
		if (event.asset.assetType == Asset3DType.MESH)
		{
			if (event.asset.name == 'cube_mesh')
			{
				block = cast event.asset;
				trace("DOING STUFF");
			}
		}
	}

	private function onResourceComplete(event:LoaderEvent):Void
	{
		if (StringTools.endsWith(event.url, "cube.awd"))
		{
			trace("DONE COMPLETE");
			LoadingCount.increment();
		}
	}

	function onMouseMove(x:Float, y:Float)
	{
		if (!paused && !selected && doneLoading)
		{
			view.cameraController.panAngle += x * 0.2;
			view.cameraController.tiltAngle += y * 0.2;
			if (mouseSpr.visible && !waitTmr.active)
				mouseSpr.visible = false;
		}
	}

	function placeEntities(entity:EntityData)
	{
		switch (entity.name)
		{
			case "player":
				player.setPosition(entity.x, entity.y);
				// curFloor = entity.values.floor;
				yOffset = 150 * (entity.values.floor + 1);
			case "portal":
				var spr = new PortalSpr();
				spr.makeGraphic(1, 1);
				spr.setGraphicSize(128, 128);
				spr.updateHitbox();
				spr.setPosition(entity.x, entity.y);
				spr.song = entity.values.song;
				portals.push(spr);
				spr.cameras = [cam2d];
				add(spr);
			case "pass":
				var spr = new FlxSprite();
				spr.makeGraphic(1, 1, FlxColor.PINK);
				spr.setGraphicSize(128, 128);
				spr.updateHitbox();
				spr.setPosition(entity.x, entity.y);
				pass = spr;
				spr.cameras = [cam2d];
				add(spr);
			case "passgate":
				var spr = new FlxSprite();
				spr.makeGraphic(1, 1, FlxColor.PINK);
				spr.setGraphicSize(128, 128);
				spr.updateHitbox();
				spr.setPosition(entity.x, entity.y);
				gate = spr;
				spr.cameras = [cam2d];
				spr.immovable = true;
				add(spr);
			case "stair":
				var spr = new FloorSpr();
				spr.makeGraphic(1, 1);
				spr.color = FlxColor.BLACK;
				spr.setGraphicSize(128, 128);
				spr.updateHitbox();
				spr.setPosition(entity.x, entity.y);
				spr.lStep = entity.values.lStep;
				spr.rStep = entity.values.rStep;
				spr.uStep = entity.values.uStep;
				spr.dStep = entity.values.dStep;
				stairs.push(spr);
				spr.cameras = [cam2d];
				add(spr);
			case "obj":
				var obj = new BasicObj();
				if (objMap.exists(entity.values.name))
				{
					obj.referenceObj(objMap[entity.values.name], entity.x, entity.values.floor, entity.y, entity.values.scaleX, entity.values.scaleY,
						entity.values.scaleZ, entity.values.yaw);
				}
				else
				{
					obj.fromString(entity.values.name, view, entity.x, entity.values.floor, entity.y, entity.values.scaleX, entity.values.scaleY,
						entity.values.scaleZ, entity.values.yaw);
					objMap[entity.values.name] = obj;
				}
				objs.push(obj);
		}
	}

	override public function onResize(x:Int, y:Int)
	{
		super.onResize(x, y);
		// if (view != null && !Config.lowRes)
		// {
		// 	view.view.width = FlxG.scaleMode.gameSize.x;
		// 	view.view.height = FlxG.scaleMode.gameSize.y;
		// 	view.view.x = FlxG.stage.stageWidth / 2 - FlxG.scaleMode.gameSize.x / 2;
		// 	view.view.y = FlxG.stage.stageHeight / 2 - FlxG.scaleMode.gameSize.y / 2;
		// }
	}

	override public function closeSubState()
	{
		if (paused)
		{
			paused = false;
			player.paused = false;
			refreshMovementStuff();
		}
		if (selected)
		{
			bf.playAnim('hey', true);
			view.lookAtObject.x = bf.mesh.x;
			view.lookAtObject.y = bf.mesh.y;
			view.lookAtObject.z = bf.mesh.z;
			view.cameraController.lookAtObject = view.lookAtObject;
			FlxTween.tween(view.cameraController, {'tiltAngle': 5}, 0.5);
			FlxTween.tween(view.cameraController, {'distance': 200}, 0.5);
			FlxTween.tween(view.lookAtObject, {'y': bf.mesh.y + 25}, 0.5);

			new FlxTimer().start(1, function(tmr)
			{
				if (options)
				{
					customTransOut = new WeirdBounceOut(0.6);
					ConfigMenu.exitTo = Overworld;
					switchState(new ConfigMenu());
				}
				else
				{
					customTransOut = new IconOut(0.6);
					// customTransOut = new WeirdBounceOut(0.6);
					switchState(new PlayState());
				}
			});
		}
		super.closeSubState();
	}

	override public function switchTo(state:FlxState)
	{
		Asset3DLibrary.removeEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		Asset3DLibrary.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		Application.current.window.onMouseMoveRelative.remove(onMouseMove);
		Application.current.window.mouseLock = false;
		FlxG.sound.music.stop();
		return super.switchTo(state);
	}

	override public function destroy()
	{
		floor = FlxDestroyUtil.destroy(floor);
		walllayers = FlxDestroyUtil.destroyArray(walllayers);
		if (steps != null && steps.playing)
			steps.stop();
		steps = FlxDestroyUtil.destroy(steps);
		player = FlxDestroyUtil.destroy(player);
		portals = FlxDestroyUtil.destroyArray(portals);
		pass = FlxDestroyUtil.destroy(pass);
		gate = FlxDestroyUtil.destroy(gate);
		if (block != null)
		{
			if (block.geometry != null)
				block.geometry.dispose();
			block.geometry = null;
			block.dispose();
		}
		block = null;
		if (planeMat != null)
		{
			planeMat.dispose();
		}
		planeMat = null;
		if (planeBitmap != null)
		{
			if (planeBitmap.bitmapData != null)
				planeBitmap.bitmapData.dispose();
			planeBitmap.dispose();
		}
		planeBitmap = null;
		for (key in texMap.keys())
		{
			if (texMap[key] != null)
				texMap[key].dispose();
		}
		texMap.clear();
		for (key in bmMap.keys())
		{
			if (bmMap[key] != null)
			{
				if (bmMap[key].bitmapData != null)
					bmMap[key].bitmapData.dispose();
				bmMap[key].dispose();
			}
		}
		bmMap.clear();
		if (bf != null)
		{
			bf.destroy();
		}
		bf = null;
		for (mesh in meshClones)
		{
			if (mesh != null)
				mesh.dispose();
		}
		meshClones = null;
		if (skybox != null)
			skybox.disposeWithChildren();
		skybox = null;
		if (skyboxTex != null)
		{
			skyboxTex.dispose();
			for (i in [
				skyboxTex.positiveX,
				skyboxTex.negativeX,
				skyboxTex.positiveY,
				skyboxTex.negativeY,
				skyboxTex.positiveZ,
				skyboxTex.negativeZ
			])
			{
				if (i != null)
				{
					i.dispose();
				}
			}
		}
		skyboxTex = null;
		objs = FlxDestroyUtil.destroyArray(objs);

		if (view != null)
		{
			if (view.cameraController != null)
				view.cameraController.lookAtObject = null;
			view.destroy();
		}
		view = null;
		FlxG.cameras.remove(cam2d);
		super.destroy();
	}
}

class OPlayer extends FlxSprite
{
	static inline var SPEED:Float = 500;

	var cam:HoverController;

	var up:Bool = false;
	var down:Bool = false;
	var left:Bool = false;
	var right:Bool = false;

	public var paused:Bool = false;

	public function new(x:Float = 0, y:Float = 0, hover:HoverController)
	{
		super(x, y);
		makeGraphic(1, 1, FlxColor.BLUE);
		setGraphicSize(65, 65);
		updateHitbox();
		drag.x = drag.y = 1600;
		cam = hover;
	}

	function updateMovement()
	{
		up = FlxG.keys.anyPressed([UP, W]);
		down = FlxG.keys.anyPressed([DOWN, S]);
		left = Config.noMouse ? false : FlxG.keys.anyPressed([LEFT, A]);
		right = Config.noMouse ? false : FlxG.keys.anyPressed([RIGHT, D]);

		if (up && down)
			down = false;
		if (left && right)
			right = false;

		if (up || down || left || right)
		{
			var newAngle:Float = 0;
			if (up)
			{
				newAngle = -90;
				if (left)
					newAngle -= 45;
				else if (right)
					newAngle += 45;
			}
			else if (down)
			{
				newAngle = 90;
				if (left)
					newAngle += 45;
				else if (right)
					newAngle -= 45;
			}
			else if (left)
				newAngle = 180;
			else if (right)
				newAngle = 0;

			velocity.set(SPEED, 0);
			velocity.rotate(FlxPoint.weak(0, 0), newAngle + cam.panAngle);
		}

		if (Config.noMouse)
		{
			left = FlxG.keys.anyPressed([LEFT, A]);
			right = FlxG.keys.anyPressed([RIGHT, D]);

			if (left && right)
				right = false;

			if (left)
				cam.panAngle -= FlxG.elapsed * 100;
			else if (right)
				cam.panAngle += FlxG.elapsed * 100;
		}
	}

	override public function update(elapsed:Float)
	{
		if (!paused && LoadingCount.isDone())
			updateMovement();
		super.update(elapsed);
	}
}

typedef OWData =
{
	var data:Array<OWTile>;
}

typedef OWTile =
{
	var id:Int;
	var tex:String;
	var collide:Bool;
	var aa:Bool;
	var alpha:Bool;
}

class PortalSpr extends FlxSprite
{
	public var song:String;
}

class FloorSpr extends FlxSprite
{
	public var uStep:Int;
	public var lStep:Int;
	public var dStep:Int;
	public var rStep:Int;
	// public var didStep:Bool = false;
}

class BasicObj implements IFlxDestroyable
{
	public var mesh:Mesh;
	public var mat:TextureMaterial;
	public var bm:ATFTexture;
	public var name:String;
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var scaleX:Float = 1;
	public var scaleY:Float = 1;
	public var scaleZ:Float = 1;
	public var yaw:Float = 0;
	public var hasReference:Bool = false;

	// var yOffset:Float = 0;
	var reference:BasicObj = null;
	var view:ModelView;

	public function new()
	{
	}

	public function fromString(name:String, view:ModelView, x:Float, y:Float, z:Float, scaleX:Float = 1, scaleY:Float = 1, scaleZ:Float = 1, yaw = 0,
			smooth:Bool = false)
	{
		LoadingCount.expand();
		this.name = name;
		this.x = x;
		this.y = y;
		this.z = z;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
		this.scaleZ = scaleZ;
		this.yaw = yaw;
		this.view = view;
		Asset3DLibrary.addEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		Asset3DLibrary.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		Asset3DLibrary.load(new URLRequest("assets/models/" + name + "/" + name + ".awd"));
		var bytes = ByteArray.fromFile("assets/models/" + name + "/" + name + ".atf");
		bm = new ATFTexture(bytes);
		mat = new TextureMaterial(bm, smooth);
		// if (Assets.exists("assets/models/" + name + "/offset.txt"))
		// {
		// 	var txt = Assets.getText("assets/models/" + name + "/offset.txt");
		// 	yOffset = Std.parseFloat(txt);
		// }
		// return this;
	}

	public function referenceObj(obj:BasicObj, x:Float, y:Float, z:Float, scaleX:Float = 1, scaleY:Float = 1, scaleZ:Float = 1, yaw:Float = 0)
	{
		this.reference = obj;
		this.x = x;
		this.y = y;
		this.z = z;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
		this.scaleZ = scaleZ;
		this.yaw = yaw;
		hasReference = true;
	}

	public function placeFromReference()
	{
		view = reference.view;
		// yOffset = reference.yOffset;
		mat = reference.mat;
		bm = reference.bm;
		name = reference.name;
		mesh = new Mesh(reference.mesh.geometry, reference.mat);
		mesh.scaleX = scaleX;
		mesh.scaleY = scaleY;
		mesh.scaleZ = scaleZ;
		mesh.yaw(yaw);
		mesh.x = -x * (150 / 128);
		// mesh.y = (mesh.bounds.max.y - mesh.bounds.min.y) / 2 + 150 * y + yOffset;
		mesh.y = (mesh.y - mesh.bounds.min.y) * scaleY;
		mesh.y += 150 * y;
		mesh.z = z * (150 / 128);
		view.addModel(mesh);
	}

	private function onAssetComplete(event:Asset3DEvent):Void
	{
		if (event.asset.assetType == Asset3DType.MESH)
		{
			if (StringTools.startsWith(event.asset.name, name + "_"))
			{
				// block = cast event.asset;
				// trace("DOING STUFF");
				mesh = cast event.asset;
				mesh.material = mat;
			}
		}
	}

	private function onResourceComplete(event:LoaderEvent):Void
	{
		if (StringTools.endsWith(event.url, name + ".awd"))
		{
			// trace("DONE COMPLETE");
			// LoadingCount.increment();
			removeListeners();
			mesh.scaleX = scaleX;
			mesh.scaleY = scaleY;
			mesh.scaleZ = scaleZ;
			mesh.yaw(yaw);
			mesh.x = -x * (150 / 128);
			mesh.y = (mesh.y - mesh.bounds.min.y) * scaleY;
			mesh.y += 150 * y;
			mesh.z = z * (150 / 128);
			view.addModel(mesh);
			LoadingCount.increment();
		}
	}

	public function removeListeners()
	{
		Asset3DLibrary.removeEventListener(Asset3DEvent.ASSET_COMPLETE, onAssetComplete);
		Asset3DLibrary.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
	}

	public function destroy()
	{
		removeListeners();
		if (mesh != null)
		{
			if (!hasReference && mesh.geometry != null)
			{
				mesh.geometry.dispose();
			}
			mesh.dispose();
		}
		mesh = null;
		if (!hasReference && mat != null)
		{
			mat.dispose();
		}
		mat = null;
		if (!hasReference && bm != null)
		{
			bm.atfData.data.clear();
			bm.dispose();
		}
		bm = null;
	}
}
