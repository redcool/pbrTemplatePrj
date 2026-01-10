Shader "Hidden/FX/Box/BoxLight"
{
    Properties
    {
        [GroupHeader(v0.0.1)]
        [Group(Base)]
        [GroupToggle(Base)]_FullScreenOn("_FullScreenOn",int) = 1
        [GroupVectorSlider(Base,minX minY maxX maxY,0_1 0_1 0_1 0_1,limit screen range,float)]_ScreenRange("ScreenRange",vector) = (0,0,1,1)
        [GroupItem(Base)] _MainTex("_MainTex",2d)=""{}
// ================================================== Light
        [Group(Light)]
        [GroupItem(Light)] [hdr]_LightColor("_LightColor",color) = (1,1,1,1)
        [GroupToggle(Light)] _IsPosLight("_IsPosLight",int) = 1
        [GroupItem(Light)] _Radius("_Radius",float) = 10.0
        [GroupItem(Light)] _Intensity("_Intensity",float) = 10.0
        [GroupItem(Light)] _Falloff("_Falloff",float) = 10.0
        
        [GroupToggle(Light,_ALPHA_TEST)] _AlphaTestOn("_AlphaTestOn",int) = 0
// ================================================== alpha      
        [Group(Alpha)]
        [GroupHeader(Alpha,BlendMode)]
        [GroupPresetBlendMode(Alpha,,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=0
        [HideInInspector]_SrcMode("_SrcMode",int) = 1
        [HideInInspector]_DstMode("_DstMode",int) = 0

        // [GroupHeader(Alpha,Premultiply)]
        // [GroupToggle(Alpha)]_AlphaPremultiply("_AlphaPremultiply",int) = 0

        // [GroupHeader(Alpha,AlphaTest)]
        // [GroupToggle(Alpha,ALPHA_TEST)]_AlphaTestOn("_AlphaTestOn",int) = 0
        // [GroupSlider(Alpha)]_Cutoff("_Cutoff",range(0,1)) = 0.5
// ================================================== Settings
        [Group(Settings)]
        [GroupEnum(Settings,UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 2
		[GroupToggle(Settings)]_ZWriteMode("ZWriteMode",int) = 0

		/*
		Disabled,Never,Less,Equal,LessEqual,Greater,NotEqual,GreaterEqual,Always
		*/
		[GroupEnum(Settings,UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",float) = 4

        [GroupHeader(Settings,Color Mask)]
        [GroupEnum(Settings,RGBA 16 RGB 15 RG 12 GB 6 RB 10 R 8 G 4 B 2 A 1 None 0)] _ColorMask("_ColorMask",int) = 15
// ================================================== stencil settings
        [Group(Stencil)]
        [GroupEnum(Stencil,UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Float) = 0
        [GroupStencil(Stencil)] _Stencil ("Stencil ID", int) = 0
        [GroupEnum(Stencil,UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Float) = 0
        [GroupHeader(Stencil,)]
        [GroupEnum(Stencil,UnityEngine.Rendering.StencilOp)] _StencilFailOp ("Stencil Fail Operation", Float) = 0
        [GroupEnum(Stencil,UnityEngine.Rendering.StencilOp)] _StencilZFailOp ("Stencil zfail Operation", Float) = 0
        [GroupItem(Stencil)] _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [GroupItem(Stencil)] _StencilReadMask ("Stencil Read Mask", Float) = 255
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100

        ZWrite[_ZWriteMode]
        Blend [_SrcMode][_DstMode]
        // BlendOp[_BlendOp]
        Cull [_CullMode]
        ztest [_ZTestMode]
        ColorMask [_ColorMask]

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            Fail [_StencilFailOp]
            ZFail [_StencilZFailOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ALPHA_TEST

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
            #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
            #include "../../../PowerShaderLib/Lib/FullscreenLib.hlsl"
            #include "../../../PowerShaderLib/URPLib/URP_Input.hlsl"
            #include "../../../PowerShaderLib/URPLib/Lighting.hlsl"
            #include "../../../PowerShaderLib/Lib/ScreenTextures.hlsl"

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
            // sampler2D _CameraOpaqueTexture;
            // sampler2D _CameraDepthTexture;
            // sampler2D _CameraNormalTexture;

            CBUFFER_START(UnityPerMaterial)
            half _FullScreenOn;
            half4 _MainTex_ST;
            half4 _ScreenRange;

            half4 _LightColor;
            half _IsPosLight;
            half _Radius;
            half _Intensity;
            half _Falloff;

            CBUFFER_END
// light 
float4 _LightAttenuation;
float4 _LightDirection;
float2 _SpotLightAngle; //{outer:dot range[1,0],innerSpotAngle:dot range[1,0]}

// float4 _LightRadiusIntensityFalloff;
// #define _Radius _LightRadiusIntensityFalloff.x
// #define _Intensity _LightRadiusIntensityFalloff.y
// #define _Falloff _LightRadiusIntensityFalloff.z
// #define _IsSpot _LightRadiusIntensityFalloff.w

// #define _CameraDepthTexture _CameraDepthAttachment
// #define _CameraOpaqueTexture _CameraColorTexture

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToNdcHClip(v.vertex,_FullScreenOn,_ScreenRange);
                o.uv = v.uv;
                return o;
            }



            float4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;
                half4 screenColor = GetScreenColor(screenUV);
                
//============ world pos
                float depthTex = GetScreenDepth(screenUV);
                half isFar = IsTooFar(depthTex.x);
                float3 worldPos = ScreenToWorld(screenUV);

                float3 worldNormal = CalcWorldNormal(worldPos);
//============ light                
                // float3 lightDir = lightPos - worldPos * (1-lightPos.w);
                // float distSqr = max(dot(lightDir,lightDir),HALF_MIN);
                // float radius2 = _Radius * _Radius;
                // lightDir = lightDir * rsqrt(distSqr);
                // float atten = 1;
                // atten *=  DistanceAtten(distSqr,radius2,_Intensity,_Falloff);

                // #if defined(_ALPHA_TEST)
                // clip(atten-0.01);
                // #endif

                // half4 lightColor = _LightColor * atten * nl;
                // return lightColor;
                // return (lightColor + screenColor);

                #define shadowAtten 1
                half _IsSpot= 0;
                half2 _SpotLightAngle=0;

                float3 lightDir = normalize(unity_ObjectToWorld._13_23_33);
                float4 lightPos = float4(_IsPosLight ? unity_ObjectToWorld._14_24_34 : lightDir,_IsPosLight);

                Light light = GetLight(lightPos,
                _LightColor.xyz,
                shadowAtten,
                worldPos,
                _LightAttenuation,
                _LightDirection,
                _Radius,
                _Intensity,
                _Falloff,
                _IsSpot,
                _SpotLightAngle);

                float nl = saturate(dot(worldNormal, light.direction));
                // return light.distanceAttenuation * light.color.xyzx * nl;
                float3 radiance = light.color * (light.distanceAttenuation  * max(0.1,light.shadowAttenuation) * nl);
                return float4(radiance, 1.0);
            }
            ENDHLSL
        }
    }
}
