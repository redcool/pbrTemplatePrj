Shader "FX/Others/BoxRadialBlur"
{
    Properties
    {
        [GroupHeader(v0.0.1)]
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
            // half4 _NoiseTex_ST;
            half _BlurSize;
            half _Radius;
            half2 _Range;
            half2 _Center;
            half _SampleCount;

            half4 _CameraColorTexture_TexelSize;

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

            float4 SampleBlur(float2 uv,int sampleCount){
                float2 dir = (uv - _Center);
                // float atten = saturate(dot(dir,dir) - _Radius*_Radius);
                float atten = saturate(length(dir) - _Radius);
                atten = smoothstep(_Range.x,_Range.y,atten);
                // return atten;
                float2 stepDir = dir/sampleCount * 0.1;

                float4 c = tex2D(_CameraOpaqueTexture,uv);
                for(int i=1;i<sampleCount;i++){
                    float4 c1 = tex2D(_CameraOpaqueTexture,uv + stepDir * i *_BlurSize * atten);
                    // c += c1;
                    c = lerp(c,c1,0.5);
                }
                // return c/sampleCount;
                return c;
            }
            float4 SampleBlur2(float2 uv,int sampleCount){
                float2 dir = (uv - _Center);
                // float atten = saturate(dot(dir,dir) - _Radius*_Radius);
                float atten = saturate(length(dir) - _Radius);
                atten = smoothstep(_Range.x,_Range.y,atten);
                // return atten;
                float2 stepDir = dir/sampleCount * 0.1;

                float4 c = tex2D(_CameraOpaqueTexture,uv);
                for(int i=1;i<sampleCount;i++){
                    float2 uvOffset = stepDir*10;// * i  * atten;
                    float4 c1 = tex2D(_CameraOpaqueTexture,uv + uvOffset);
                    // c += c1;
                    c = lerp(c,c1,0.5);
                }
                // return c/sampleCount;
                return c;
            }
            float4 frag (v2f i) : SV_Target
            {
                half aspect = _ScaledScreenParams.x/_ScaledScreenParams.y;
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;

                float4 col = SampleBlur2(screenUV,_SampleCount);
                return col;
            }
            ENDHLSL
        }
    }
}
