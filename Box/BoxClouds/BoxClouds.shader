Shader "FX/Others/BoxClouds"
{
    Properties
    {
        [GroupHeader(v0.0.1)]

        [Group(Noise)]
        [GroupItem(Noise)] _NoiseTex ("_NoiseTex", 2D) = "white" {}
        [GroupToggle(Noise,,stop auto pan)]_NoiseTexOffsetStop("_NoiseTex OffsetStop",int) = 0

        [GroupItem(Noise)]_NoiseRangeMin("_NoiseRangeMin",range(0,1)) = 0.1
        [GroupItem(Noise)]_NoiseRangeMax("_NoiseRangeMax",range(0,1)) = 0.5

        [Group(Color)]
        [GroupItem(Color)] [hdr]_ShadowColor("_ShadowColor",color) = (0.1,0.1,0.1,0)
        [GroupItem(Color)] _BaseShadowIntensity("_BaseShadowIntensity",float) = 0.1
        [GroupItem(Color)] _ShadowIntensity("_ShadowIntensity",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100
        zwrite off
        ztest always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
            #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
            #include "../../../PowerShaderLib/URPLib/URP_Input.hlsl"

            #define USE_SAMPLER2D
            #include "../../../PowerShaderLib/Lib/TextureLib.hlsl"
            // #define _WeatherNoiseTexture _NoiseTex
            #include "../../../PowerShaderLib/Lib/WeatherNoiseTexture.hlsl"

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

            sampler2D _NoiseTex;
            sampler2D _CameraColorTexture,_CameraDepthTexture;

            CBUFFER_START(UnityPerMaterial)
            half4 _NoiseTex_ST;
            half _NoiseTexOffsetStop;
            half _NoiseRangeMax,_NoiseRangeMin;

            half4 _ShadowColor;
            half _ShadowIntensity,_BaseShadowIntensity;

            CBUFFER_END

// #define _CameraDepthTexture _CameraDepthAttachment
#define _CameraOpaqueTexture _CameraColorTexture

            v2f vert (appdata v)
            {
                v2f o;
                // o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.vertex = float4(v.vertex.xy*2,0,1);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;

//============ world pos
                float depthTex = tex2D(_CameraDepthTexture,screenUV).x;
                half isFar = depthTex.x>0.999999;

                float3 worldPos = ScreenToWorldPos(screenUV,depthTex,UNITY_MATRIX_I_VP);

                float2 uv = worldPos.xz * _NoiseTex_ST.xy + UVOffset(_NoiseTex_ST.zw,_NoiseTexOffsetStop);
                float noise = SampleWeatherNoise(_NoiseTex,uv,half4(0.1,0.2,0.3,0.4));
                noise = smoothstep(_NoiseRangeMin,_NoiseRangeMax,noise);

                float rate = saturate(noise * _ShadowIntensity + _BaseShadowIntensity);
                rate = isFar ? 1 : rate;
                half3 shadowColor = lerp(_ShadowColor,1,rate );

                float4 col = tex2D(_CameraOpaqueTexture,screenUV);
                col.xyz *= shadowColor.xyz;

                return col;
            }
            ENDHLSL
        }
    }
}
