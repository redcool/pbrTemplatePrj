Shader "Hidden/MacroDefineDemo"
{
    Properties
    {
    }
    CGINCLUDE
    /**
        https://gcc.gnu.org/onlinedocs/cpp/Macros.html
    */
    // macro define 
    #define COLOR_ONLY

    //macro undefine
    #undef COLOR_ONLY

    // macro define has value
    #define GREEN_COLOR float4(0,1,0,1)

    // macro define multi lines
    #define OUTPUT_WHITE_COLOR \
        float4 c = 1;\
        return c
    
    // macro define function style
    #define Min3(a,b,c) (min(min(a,b),c))
    #define Min4(a,b,c,d) \
    (min(\
        Min3(a,b,c),d)\
        )

    // ## 组合出变量
    #define CalcColor(namePrefix,nameId) namePrefix ## nameId 

    //
    static const float4 redColor1=float4(0.3,0,0,1);
    static const float4 redColor2=float4(0.6,0,0,1);

    ENDCG
    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                #if defined(COLOR_ONLY)
                    return GREEN_COLOR;
                #endif

                // return Min4(0.4,0.3,0.2,0.1);

                OUTPUT_WHITE_COLOR;

                return CalcColor(redColor,2);
            }
            ENDCG
        }
    }
}
