class LoadingCount
{
	static var resourcesToLoad:Int = 0;
	static var resourcesComplete:Int = 0;

	public static function reset()
	{
		resourcesToLoad = 0;
		resourcesComplete = 0;
	}

	public static function expand(amt:Int = 1)
	{
		resourcesToLoad += amt;
	}

	public static function increment(amt:Int = 1)
	{
		resourcesComplete += amt;
	}

    public static function isDone()
    {
        return resourcesToLoad == resourcesComplete;
    }
}
