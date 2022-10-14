package transition.data;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

/**
    Transition animation made to test the new transition system.
**/
class WeirdBounceOut extends BasicTransition{

    var blockThing:FlxSprite;
    var time:Float;

    override public function new(_time:Float){
        
        super();

        time = _time;

        blockThing = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
        blockThing.setGraphicSize(FlxG.width, FlxG.height);
        blockThing.updateHitbox();
        blockThing.graphic.bitmap.disposeImage();
        blockThing.x -= blockThing.width;
        add(blockThing);

    }

    override public function play(){
        FlxTween.tween(blockThing, {x: 0}, time, {ease: FlxEase.quartOut, onComplete: function(tween){
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