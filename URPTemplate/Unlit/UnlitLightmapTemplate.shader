Shader "Template/UnlitLightmap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Lightmap("_Lightmap",2d)="white"{}
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

            #define USE_URP
            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1:TEXCOORD1;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _Lightmap;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = float4(TRANSFORM_TEX(v.uv, _MainTex),v.uv1);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv.xy);
                half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);
                float3 lmap = DecodeLightmap(tex2D(_Lightmap,i.uv.zw),decodeInstructions);
                col.xyz *= lmap;
                return col;
            }
            ENDHLSL
        }
    }
}
