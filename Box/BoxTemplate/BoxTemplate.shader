Shader "Hidden/FX/Others/Template"
{
    Properties
    {
        [GroupHeader(v0.0.1)]
        [Group(Base)]
        [GroupToggle(Base)]_FullScreenOn("_FullScreenOn",int) = 1

        _MainTex("_MainTex",2d)=""{}
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

            sampler2D _MainTex;
            sampler2D _CameraColorTexture;
            sampler2D _CameraDepthTexture;

            CBUFFER_START(UnityPerMaterial)
            half _FullScreenOn;
            half4 _MainTex_ST;

            CBUFFER_END

// #define _CameraDepthTexture _CameraDepthAttachment
#define _CameraOpaqueTexture _CameraColorTexture

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = _FullScreenOn ? float4(v.vertex.xy * 2,0,1) : TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }



            float4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;

//============ world pos
                float depthTex = tex2D(_CameraDepthTexture,screenUV).x;
                half isFar = IsTooFar(depthTex.x);
                
                float3 worldPos = ScreenToWorldPos(screenUV,depthTex,UNITY_MATRIX_I_VP);
                return worldPos.xyzx;
            }
            ENDHLSL
        }
    }
}
