Shader "FX/Others/BoxRadialBlur"
{
    Properties
    {
        [GroupHeader(v0.0.1)]

        _NoiseTex("_NoiseTex",2d) = ""{}
        _NoiseScale("_NoiseScale",float) = 1

        [GroupVectorSlider(,centerX centerY,0_1 0_1,)]
        _Center("_Center",vector) = (0,0,0,0)
        _Radius("_Radius",range(-1,1)) = 0

        [GroupVectorSlider(,rangeX rangeY,0_1 0_1,,)]
        _Range("_Range",vector) = (0,1,0,0)

        _SampleCount("_SampleCount",range(4,10)) = 4
        _BlurSize("_BlurSize",float) = 1
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

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            // #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            // #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            // #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
            // #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
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
            float4 _NoiseTex_ST;
            float _NoiseScale;

            float _BlurSize;
            float _Radius;
            float2 _Range;
            float2 _Center;
            float _SampleCount;


            CBUFFER_END

            float4 _CameraOpaqueTexture_TexelSize;
            float4 _NoiseTex_TexelSize;
// #define _CameraDepthTexture _CameraDepthAttachment
// #define _CameraOpaqueTexture _CameraColorTexture

            v2f vert (appdata v)
            {
                v2f o;
                // o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.vertex = float4(v.vertex.xy*2,0,1);
                o.uv = v.uv;
                return o;
            }

            float2 CalcStepUVOffset(float2 uv,float2 center,int sampleCount,float attenRadius,float2 attenRange,float blurSize){
                float2 dir = (uv - _Center);
                float atten = saturate(length(dir) - attenRadius);
                atten = smoothstep(attenRange.x,attenRange.y,atten);
                // return atten;
                float2 stepDir = dir/sampleCount;

                return stepDir *blurSize * atten;
                // return dir *blurSize * atten;
            }

            float4 SampleBlur(float2 uv,int sampleCount,float2 uvStepOffset){
                float4 c = tex2D(_CameraOpaqueTexture,uv);
                for(int i=1;i<sampleCount;i++){
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

                float noiseTex = tex2D(_NoiseTex,screenUV).x;
                float noise = noiseTex * _NoiseScale;

                float2 uvStepOffset = CalcStepUVOffset(screenUV,_Center,_SampleCount,_Radius,_Range,_BlurSize);

                float4 col = SampleBlur(screenUV,_SampleCount,uvStepOffset * noise);
                return col;
            }
            ENDHLSL
        }
    }
}
