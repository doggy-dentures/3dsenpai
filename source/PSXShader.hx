import flixel.system.FlxAssets.FlxShader;

class PSXShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

        float to15bit(float col, float low)
        {
            float lower = floor(col * 32) / 32;
            float higher = ceil(col * 32) / 32;
            return lower * low + higher * (1 - low);
        }

		void main()
		{
            vec2 pixel = vec2(1.0,1.0) / openfl_TextureSize;
			
            vec2 p = openfl_TextureCoordv;
			
            vec4 source = flixel_texture2D(bitmap, p);

            float xPixel = mod(floor(p.x / pixel.x), 2.0);
            float yPixel = mod(floor(p.y / pixel.y), 2.0);
            float checker = mod(xPixel + yPixel, 2.0);

            vec4 col = vec4(to15bit(source.r, checker),to15bit(source.g, checker),to15bit(source.b, checker), source.a);

            gl_FragColor = col;
		}')
	public function new()
	{
		super();
	}
}
