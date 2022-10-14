package;

import flixel.util.FlxDestroyUtil;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class Boyfriend3D extends Character3D
{
	override function update(elapsed:Float)
	{
		if (!debugMode)
		{
			if (getCurAnim().startsWith('sing'))
			{
				holdTimer += elapsed;
			}
			else
				holdTimer = 0;
		}

		super.update(elapsed);
	}

	override public function dance(?ignoreDebug:Bool = false)
	{
		if (!debugMode || ignoreDebug)
		{
			switch (curCharacter)
			{
				default:
					if (!getCurAnim().startsWith('sing') || getCurAnim().endsWith('End'))
					{
						playAnim('idle', true);
					}
			}
		}
	}
}
