Shader "Template/Unlit"
{
    Properties
    {
        _TexA ("Texture", 2D) = "white" {}
        _TexB("_TexB",2d) = ""{}
    }

HLSLINCLUDE
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "ColorSpace.hlsl"

ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


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

            sampler2D _TexA;
            sampler2D _TexB;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                // v.vertex.xy *= 2;
                // o.vertex = v.vertex;
                o.uv = v.uv;
                return o;
            }

            float3 BlendHue(float3 a,float3 b){
                a = RgbToLch(a);
                b = RgbToLch(b);
                // a = float3(b.xy,a.z); // hue
                // a = float3(b.x,a.y,b.z); // saturation
                // a = float3(b.x,a.yz); // color
                a = float3(a.x,b.yz); //luminosity
                a = LchToRgb(a);
                return a;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 colA = tex2D(_TexA, i.uv);
                float4 colB = tex2D(_TexB,i.uv);

                float3 col = BlendHue(colA.xyz,colB.xyz);
                return col.xyzx;
            }
            ENDHLSL
        }
    }
}
