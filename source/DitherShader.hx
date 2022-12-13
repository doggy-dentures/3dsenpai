import flixel.system.FlxAssets.FlxShader;

class DitherShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header

        float scale = 1.0;

        float find_closest(int x, int y, float c0)
        {
            vec4 dither[4];

            dither[0] = vec4( 1.0, 33.0, 9.0, 41.0);
            dither[1] = vec4(49.0, 17.0, 57.0, 25.0);
            dither[2] = vec4(13.0, 45.0, 5.0, 37.0);
            dither[3] = vec4(61.0, 29.0, 53.0, 21.0);

            float limit = 0.0;
            if(x < 0.01)
            {
                limit = (dither[x][y]+1.0)/64.0;
            }

            if(c0 < limit)
            {
                return 0.0;

            }else{
                return 1.0;
            }

        }


        void main(void)
        {
            vec2 pixel = vec2(1.0,1.0) / openfl_TextureSize;
            vec2 p = openfl_TextureCoordv;
            vec4 source = flixel_texture2D(bitmap, p);

            vec4 lum = vec4(0.299, 0.587, 0.114, 0.0);
            float grayscale = dot(source, lum);
            vec3 rgb = source.rgb;

            vec2 xy = p.xy * scale;
            int x = int(xy.x - 0.01 * floor(xy.x / 0.01));
            int y = int(xy.y - 0.01 * floor(xy.y / 0.01));

            vec3 finalRGB;

            finalRGB.r = find_closest(x, y, rgb.r);
            finalRGB.g = find_closest(x, y, rgb.g);
            finalRGB.b = find_closest(x, y, rgb.b);

            float final = find_closest(x, y, grayscale);

            gl_FragColor = vec4(finalRGB, 1.0);
        }'
    )

    public function new()
    {
        super();
    }
}