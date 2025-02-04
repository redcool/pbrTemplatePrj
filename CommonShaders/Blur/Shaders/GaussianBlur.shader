Shader "Hidden/Blur/GaussianBlur"
{
    Properties
    {
        _MainTex("_MainTex",2d) = ""{}
        _Scale("_Scale",range(1,10)) = 1
        [GroupToggle]_IsBlitTriangle("_IsBlitTriangle",float) = 0
    }
    HLSLINCLUDE
    #include "../../../../PowerShaderLib/Lib/UnityLib.hlsl"
    #include "../../../../PowerShaderLib/Lib/BlurLib.hlsl"
    #include "../../../../PowerShaderLib/Lib/BlitLib.hlsl"
    #include "../../../../PowerShaderLib/Lib/Colors.hlsl"    

    struct appdata
    {
        float4 vertex : POSITION;
        float4 uv : TEXCOORD0;
        uint vid:SV_VERTEXID;
    };

    struct v2f
    {
        float2 uv:TEXCOORD;
        float4 vertex : SV_POSITION;
    };
    CBUFFER_START(UnityPerMaterial)
    sampler2D _MainTex;
    float4 _MainTex_TexelSize;
    float _Scale;
    half _IsBlitTriangle;
    CBUFFER_END

    v2f vert (appdata v)
    {
        v2f o = (v2f)0;

        if(_IsBlitTriangle){
            FullScreenTriangleVert(v.vid,o.vertex/**/,o.uv/**/);
        }else{
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv.xy;
        }

        return o;
    }

    ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
//0
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            half4 frag (v2f i) : SV_Target
            {
                half2 uv = i.uv;
                half3 col = 0;

                col += Gaussian7(_MainTex,uv, _MainTex_TexelSize.xy * _Scale * half2(1,0));
                col += Gaussian7(_MainTex,uv, _MainTex_TexelSize.xy * _Scale * half2(0,1));
                col *= 0.5;
                return half4(col,1);
            }
            ENDHLSL
        }

    }
}
