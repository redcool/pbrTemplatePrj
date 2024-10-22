Shader "Unlit/FX/Border4Fading"
{
    Properties
    {
        _BaseColor("_BaseColor",color) = (0,0,0,1)
        _MaskTex ("Texture", 2D) = "white" {}
        [GroupVectorSlider(_,left right top bottom,0_1 0_1 0_1 0_1,float)]
        _Fading("_Fading",vector) = ( 1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "../../../../PowerShaderLib/Lib/UnityLib.hlsl"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MaskTex;
            CBUFFER_START(UnityPerMaterial)

            float4 _Fading;
            float4 _BaseColor;
            CBUFFER_END

            float GetAlpha(float2 uv,float fading){
                float4 mask = tex2D(_MaskTex, uv);
                // float a = saturate(c.r - _Fading);
                float a = lerp(1,mask.r,fading);
                return a;
            }

            float GetAlpha4(float2 uv){
                float a = 1;
                a *= GetAlpha(uv,_Fading.x);
                a *= GetAlpha(float2(1 - uv.x,uv.y),_Fading.y);
                a *= GetAlpha(float2(uv.y,uv.x),_Fading.z);
                a *= GetAlpha(float2(1 - uv.y,uv.x),_Fading.w);
                // a = 1-a;
                float fadingSum = dot(_Fading,1);//mad
                // a *= fadingSum>3? lerp(a,0,fadingSum-3): 1;
                a *= smoothstep(a,0,fadingSum-3);
                return a;
            }            

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = _BaseColor;
                col.a *= GetAlpha4(i.uv);
                return col;
            }
            ENDHLSL
        }
    }
}
