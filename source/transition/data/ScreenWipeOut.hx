package transition.data;

import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxGradient;

/**
    Recreation of the normal FNF transition out.
**/
class ScreenWipeOut extends BasicTransition{

    var blockThing:FlxSprite;
    var time:Float;

    override public function new(_time:Float){
        
        super();

        time = _time;

        blockThing = FlxGradient.createGradientFlxSprite(1, 1024, [FlxColor.BLACK, FlxColor.BLACK, 0x00000000]);
        blockThing.antialiasing = true;
        blockThing.setGraphicSize(FlxG.width, FlxG.height*2);
        blockThing.updateHitbox();
        blockThing.graphic.bitmap.disposeImage();
        blockThing.y -= blockThing.height;
        add(blockThing);

    }

    override public function play(){
        FlxTween.tween(blockThing, {y: 0}, time, {onComplete: function(tween){
            end();
            flixel.util.FlxDestroyUtil.destroy(tween);
        }});
    }

    override public function destroy()
    {
        blockThing = flixel.util.FlxDestroyUtil.destroy(blockThing);
        super.destroy();
    }

}