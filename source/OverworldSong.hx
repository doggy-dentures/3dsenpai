import flixel.FlxSprite;

class OverworldSong extends OverworldPortal
{
	var song:String;

	override public function new(song:String)
	{
		super();
		this.song = song;
	}

    override public function create()
    {
        bg = new FlxSprite().loadGraphic(Paths.image('ow/' + song.charAt(0).toLowerCase()));
        super.create();
    }

    override function accept()
    {
        var poop = Highscore.formatSong(song, 1);
		PlayState.SONG = Song.loadFromJson(poop, song);
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = 1;
		PlayState.loadEvents = true;
		PlayState.returnLocation = "main";
		PlayState.storyWeek = 6;
        super.accept();
    }
}
