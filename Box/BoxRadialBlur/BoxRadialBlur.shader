Shader "FX/Others/BoxRadialBlur"
{
    Properties
    {
        [GroupHeader(v0.0.2)]
        [Group(Base)]
        [GroupToggle(Base)]_FullScreenOn("_FullScreenOn",int) = 1

        [Group(NoiseTex)]
        [GroupItem(NoiseTex)] _NoiseTex("_NoiseTex",2d) = ""{}
        [GroupToggle(NoiseTex,,stop auto uv scroll)] _NoiseTexOffsetStop("_NoiseTexOffsetStop",int) = 0
        [GroupToggle(NoiseTex,_NOISE_POLAR_UV, use polar uv sample)]_NoiseTexPolarUV("_NoiseTexPolarUV",int) = 0
        [GroupItem(NoiseTex)] _NoiseScale("_NoiseScale",float) = 1
        [GroupItem(NoiseTex,noise atten screen uv radius)] _NoiseRadius("_NoiseRadius",range(0,1)) = 1
        

        [Group(RadialBlur)]
        [GroupHeader(RadialBlur,Distance)]
        [GroupVectorSlider(RadialBlur,centerX centerY,0_1 0_1,)]
        [GroupItem(RadialBlur,blur start pos)] _Center("_Center",vector) = (0,0,0,0)
        [GroupItem(RadialBlur,blur atten screen uv radius)] _Radius("_Radius",range(-1,1)) = 0

        [GroupVectorSlider(RadialBlur,rangeX rangeY,0_1 0_1,,)] _Range("_Range",vector) = (0,1,0,0)

        [GroupHeader(RadialBlur,Blur)]
        [GroupItem(RadialBlur)] _SampleCount("_SampleCount",range(1,10)) = 4
        [GroupItem(RadialBlur)] _BlurSize("_BlurSize",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100
        zwrite off
        ztest always
        cull off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _NOISE_POLAR_UV

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            // #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            // #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            // #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
            #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
            #include "../../../PowerShaderLib/Lib/CoordinateSystem.hlsl"
            #include "../../../PowerShaderLib/URPLib/URP_Input.hlsl"

            // #define USE_SAMPLER2D
            // #include "../../../PowerShaderLib/Lib/TextureLib.hlsl"
            // // #define _WeatherNoiseTexture _NoiseTex
            // #include "../../../PowerShaderLib/Lib/WeatherNoiseTexture.hlsl"

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
            sampler2D _CameraOpaqueTexture;
            sampler2D _CameraDepthTexture;

            CBUFFER_START(UnityPerMaterial)
            half _FullScreenOn;
            half4 _NoiseTex_ST;
            half _NoiseScale,_NoiseRadius;
            half _NoiseTexOffsetStop;

            half _BlurSize;
            half _Radius;
            half2 _Range;
            half2 _Center;
            half _SampleCount;


            CBUFFER_END

            half4 _CameraOpaqueTexture_TexelSize;
            half4 _NoiseTex_TexelSize;
// #define _CameraDepthTexture _CameraDepthAttachment
// #define _CameraOpaqueTexture _CameraColorTexture

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = _FullScreenOn ? float4(v.vertex.xy * 2,0,1) : TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            /**
                Get step dir for radiual blur
                cur blur uv = uv + stepDir*stepIndex

                uv : cur uv
                center : sdf(circle)' center
                radius : circle 's radius
                sampleCount : iterate count
                attenRange : [min,max] for smoothstep
                blurSize : scale final step dir
            */
            float2 CalcStepUVOffset(inout float distanceAtten,float2 uv,float2 center,float radius,int sampleCount,float2 attenRange,float blurSize){
                float2 dir = (uv - center);
                float atten = saturate(length(dir) - radius);
                atten = smoothstep(attenRange.x,attenRange.y,atten);
                distanceAtten = atten;
                // set outer
                // return atten;
                float2 stepDir = dir/sampleCount;

                return stepDir *blurSize * atten;
                // return dir *blurSize * atten;
            }

            float4 SampleBlur(float2 uv,int sampleCount,float2 uvStepOffset){
                float4 c = 0;
                for(int i=0;i<sampleCount;i++){
                    float4 c1 = tex2D(_CameraOpaqueTexture,uv + i * uvStepOffset);
                    c += c1;
                    // c = lerp(c,c1,0.5);
                }
                return c/sampleCount;
                // return c;
            }

            float4 SampleBlur3(float2 uv,int sampleCount,float2 uvStepOffset){
                // float2 dir = uv -_Center;
                // float atten = saturate(length(dir) - _Radius);
                // atten = smoothstep(_Range.x,_Range.y,atten);

                float halfCount = sampleCount /2;
                float4 c = 0;

                for(int i=0;i<sampleCount;i++){
                    //(i - halfCount) = [-halfCount,halfCount]
                    // float2 offset = (i - halfCount) * dir * _BlurSize * atten;
                    c += tex2D(_CameraOpaqueTexture,uv + (i - halfCount) * uvStepOffset);
                }
                return c/sampleCount;
            }

            float4 frag (v2f i) : SV_Target
            {
                float aspect = _ScaledScreenParams.x/_ScaledScreenParams.y;
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;
//============== Noise
                float2 noiseUV = screenUV;
                #if defined(_NOISE_POLAR_UV)
                noiseUV = ToPolar(screenUV*2-1);
                #endif
                half2 noiseOffset = UVOffset(_NoiseTex_ST.zw, _NoiseTexOffsetStop);
                float noiseTex = tex2D(_NoiseTex,noiseUV * _NoiseTex_ST.xy + noiseOffset).x;
                float noise = noiseTex * _NoiseScale*0.02;
//============== Distance
                float distanceAtten = 0;
                float2 uvStepOffset = CalcStepUVOffset(distanceAtten/**/,screenUV,_Center,_Radius,_SampleCount,_Range,_BlurSize);
                noise = saturate(noise * (distanceAtten - _NoiseRadius));
                // return noise;
                // distortion 1 step
                screenUV += _SampleCount<=2 ? uvStepOffset*0.1 : 0;
                float4 col = SampleBlur(screenUV,_SampleCount,uvStepOffset + noise);
                return col;
            }
            ENDHLSL
        }
    }
}
