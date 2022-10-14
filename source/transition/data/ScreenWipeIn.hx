package transition.data;

import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxGradient;

/**
    Recreation of the normal FNF transition in.
**/
class ScreenWipeIn extends BasicTransition{

    var blockThing:FlxSprite;
    var time:Float;

    override public function new(_time:Float){
        
        super();

        time = _time;

        blockThing = FlxGradient.createGradientFlxSprite(1, 1024, [0x00000000, FlxColor.BLACK, FlxColor.BLACK]);
        blockThing.antialiasing = true;
        blockThing.setGraphicSize(FlxG.width, FlxG.height*2);
        blockThing.updateHitbox();
        blockThing.graphic.bitmap.disposeImage();
        blockThing.y -= blockThing.height/2;
        add(blockThing);

    }

    override public function play(){
        FlxTween.tween(blockThing, {y: blockThing.height}, time, {onComplete: function(tween){
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