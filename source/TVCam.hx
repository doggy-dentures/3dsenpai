import openfl.display.DisplayObject;
import flixel.FlxG;
import flixel.util.FlxAxes;
import openfl.geom.Rectangle;
import flixel.FlxCamera;

class TVCam extends FlxCamera
{
	override function transformObject(object:DisplayObject):DisplayObject
	{
		object.scaleX *= totalScaleX;
		object.scaleY *= totalScaleY;

		object.x -= scroll.x * totalScaleX;
		object.y -= scroll.y * totalScaleY;

		object.x -= 0.5 * width * (scaleX - initialZoom) * 1;
		object.y -= 0.5 * height * (scaleY - initialZoom) * 1;

		return object;
	}

	override function updateShake(elapsed:Float):Void
	{
		if (_fxShakeDuration > 0)
		{
			_fxShakeDuration -= elapsed;
			if (_fxShakeDuration <= 0)
			{
				if (_fxShakeComplete != null)
				{
					_fxShakeComplete();
				}
			}
			else
			{
				if (_fxShakeAxes != FlxAxes.Y)
				{
					flashSprite.x += FlxG.random.float(-_fxShakeIntensity * width, _fxShakeIntensity * width) * zoom * 1;
				}
				if (_fxShakeAxes != FlxAxes.X)
				{
					flashSprite.y += FlxG.random.float(-_fxShakeIntensity * height, _fxShakeIntensity * height) * zoom * 1;
				}
			}
		}
	}

	override function updateFlashSpritePosition():Void
	{
		if (flashSprite != null)
		{
			// flashSprite.x = x * 1 + _flashOffset.x;
			// flashSprite.y = y * 1 + _flashOffset.y;
			flashSprite.x = -width * 2;
			flashSprite.y = -height * 2;
		}
	}

	override function updateFlashOffset():Void
	{
		_flashOffset.x = width * 0.5 * 1 * initialZoom;
		_flashOffset.y = height * 0.5 * 1 * initialZoom;
	}

	override function updateScrollRect():Void
	{
		var rect:Rectangle = (_scrollRect != null) ? _scrollRect.scrollRect : null;

		if (rect != null)
		{
			rect.x = rect.y = 0;

			rect.width = width * initialZoom * 1;
			rect.height = height * initialZoom * 1;

			_scrollRect.scrollRect = rect;

			_scrollRect.x = -0.5 * rect.width;
			_scrollRect.y = -0.5 * rect.height;
		}
	}

	override function updateInternalSpritePositions():Void
	{
		if (FlxG.renderBlit)
		{
			if (_flashBitmap != null)
			{
				_flashBitmap.x = 0;
				_flashBitmap.y = 0;
			}
		}
		else
		{
			if (canvas != null)
			{
				canvas.x = -0.5 * width * (scaleX - initialZoom) * 1;
				canvas.y = -0.5 * height * (scaleY - initialZoom) * 1;

				canvas.scaleX = totalScaleX;
				canvas.scaleY = totalScaleY;

				#if FLX_DEBUG
				if (debugLayer != null)
				{
					debugLayer.x = canvas.x;
					debugLayer.y = canvas.y;

					debugLayer.scaleX = totalScaleX;
					debugLayer.scaleY = totalScaleY;
				}
				#end
			}
		}
	}

	override public function setScale(X:Float, Y:Float):Void
	{
		scaleX = X;
		scaleY = Y;

		totalScaleX = scaleX * 1;
		totalScaleY = scaleY * 1;

		if (FlxG.renderBlit)
		{
			updateBlitMatrix();

			if (_useBlitMatrix)
			{
				_flashBitmap.scaleX = initialZoom * 1;
				_flashBitmap.scaleY = initialZoom * 1;
			}
			else
			{
				_flashBitmap.scaleX = totalScaleX;
				_flashBitmap.scaleY = totalScaleY;
			}
		}

		calcOffsetX();
		calcOffsetY();

		updateScrollRect();
		updateInternalSpritePositions();

		FlxG.cameras.cameraResized.dispatch(this);
	}
}
