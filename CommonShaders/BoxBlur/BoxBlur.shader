Shader "Unlit/Blur/BoxBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("_BlurSize",float) = 1
        _StepCount("_StepCount",range(1,10)) = 4

        [GroupToggle(,_IS_CAMERA_OPAQUE_TEXTURE,mainTexture use _CameraOpaqueTexture)]_IsCameraOpaqueTexture("_IsCameraOpaqueTexture",float) = 0
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
            #pragma shader_feature _IS_CAMERA_OPAQUE_TEXTURE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../../../PowerShaderLib/Lib/BlurLib.hlsl"
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

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            float _BlurSize;
            float _StepCount;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float4 c = 0;
                #if defined(_IS_CAMERA_OPAQUE_TEXTURE)
                // c = GaussBlur(_MainTex,sampler_MainTex,i.uv,float2(_MainTex_TexelSize.x,0) * _BlurSize,true);
                c += BoxBlur(_CameraOpaqueTexture,sampler_CameraOpaqueTexture,i.uv,_MainTex_TexelSize.xy * _BlurSize* float2(1,0),_StepCount);
                c += BoxBlur(_CameraOpaqueTexture,sampler_CameraOpaqueTexture,i.uv,_MainTex_TexelSize.xy * _BlurSize* float2(0,1),_StepCount);
                #else
                c += BoxBlur(_MainTex,sampler_MainTex,i.uv,_MainTex_TexelSize.xy * _BlurSize* float2(1,0),_StepCount);
                c += BoxBlur(_MainTex,sampler_MainTex,i.uv,_MainTex_TexelSize.xy * _BlurSize* float2(0,1),_StepCount);
                #endif
                return c;
            }
            ENDHLSL
        }
    }
}
