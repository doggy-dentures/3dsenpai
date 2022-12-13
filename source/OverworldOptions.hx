import flixel.FlxG;
import flixel.FlxSprite;

class OverworldOptions extends OverworldPortal
{
    override public function create()
    {
        bg = new FlxSprite().loadGraphic(Paths.image('ow/options'));
        super.create();
    }

    override function accept()
    {
        cast(FlxG.state, Overworld).options = true;
        super.accept();
    }
}
