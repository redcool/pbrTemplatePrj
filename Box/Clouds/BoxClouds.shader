Shader "FX/Others/BoxClouds"
{
    Properties
    {
        [GroupHeader(v0.0.1)]
        _BoundsMin("_BoundsMin",vector) = (0,0,0,0)
        _BoundsMax("_BoundsMax",vector) = (1,1,1,1)
    }

HLSLINCLUDE
            // Returns (dstToBox, dstInsideBox). If ray misses box, dstInsideBox will be zero
            float2 rayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 invRaydir) {
                // Adapted from: http://jcgt.org/published/0007/03/04/
                float3 t0 = (boundsMin - rayOrigin) * invRaydir;
                float3 t1 = (boundsMax - rayOrigin) * invRaydir;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);
                
                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(tmax.x, min(tmax.y, tmax.z));

                // CASE 1: ray intersects box from outside (0 <= dstA <= dstB)
                // dstA is dst to nearest intersection, dstB dst to far intersection

                // CASE 2: ray intersects box from inside (dstA < 0 < dstB)
                // dstA is the dst to intersection behind the ray, dstB is dst to forward intersection

                // CASE 3: ray misses box (dstA > dstB)

                float dstToBox = max(0, dstA);
                float dstInsideBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }
ENDHLSL

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
                float4 worldPos:TEXCOORD1;
                float3 viewDir :TEXCOORD2;
            };

            sampler2D _NoiseTex;
            sampler2D _CameraColorTexture,_CameraDepthTexture;

            CBUFFER_START(UnityPerMaterial)
            float3 _BoundsMax,_BoundsMin;

            CBUFFER_END

// #define _CameraDepthTexture _CameraDepthAttachment
#define _CameraOpaqueTexture _CameraColorTexture

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.vertex = float4(v.vertex.xy*2,0,1);
                o.uv = v.uv;
                o.worldPos.xyz = TransformObjectToWorld(v.vertex.xyz);
                o.viewDir = mul(unity_CameraInvProjection,float4(o.vertex.xyz,-1));
                o.viewDir = mul(unity_CameraToWorld,float4(o.viewDir,0));
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;
                //============ world pos
                float depthTex = tex2D(_CameraDepthTexture,screenUV).x;
                float3 worldPos = ScreenToWorldPos(screenUV,depthTex,UNITY_MATRIX_I_VP);

                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDir = (worldPos.xyz - _WorldSpaceCameraPos);
                float rayDirLen = length(rayDir);
                rayDir = rayDir/rayDirLen;
                // rayDir = normalize(i.viewDir);

                // float eyeDepth = LinearEyeDepth(depthTex,_ZBufferParams);
                // float depth = eyeDepth * 1;
                float2 rayBoxInfo = rayBoxDst(_BoundsMin,_BoundsMax,rayOrigin,1/rayDir);

                float dstToBox = rayBoxInfo.x;
                float dstInsideBox = rayBoxInfo.y;
                float rayHitBox = dstInsideBox && (dstToBox < rayDirLen);
                if(rayHitBox)
                {
                    return 0;
                }



                float4 colorTex = tex2D(_CameraOpaqueTexture,screenUV);

                half4 col = (half4)0;

                return colorTex;
            }
            ENDHLSL
        }
    }
}
