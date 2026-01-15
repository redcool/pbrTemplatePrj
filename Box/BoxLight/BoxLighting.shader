Shader "Hidden/FX/Box/BoxLighting"
{
    Properties
    {
        [GroupHeader(v0.0.1)]
        [Group(Base)]
        [GroupToggle(Base)]_FullScreenOn("_FullScreenOn",int) = 1
        [GroupVectorSlider(Base,minX minY maxX maxY,0_1 0_1 0_1 0_1,limit screen range,float)]_ScreenRange("ScreenRange",vector) = (0,0,1,1)
        [GroupItem(Base)] _MainTex("_MainTex",2d)="white"{}
// ================================================== Light
        [Group(Light)]
        [GroupItem(Light)] [hdr]_LightColor("_LightColor",color) = (1,1,1,1)
        [GroupEnum(Light,dir 0 point 1 spot 2)] _LightType("_LightType",int) = 1
        // [GroupToggle(Light)] _IsPosLight("_IsPosLight",int) = 1
        [GroupItem(Light)] _Radius("_Radius",float) = 10.0
        [GroupItem(Light)] _Intensity("_Intensity",float) = 10.0
        [GroupItem(Light)] _Falloff("_Falloff",float) = 10.0
        [GroupVectorSlider(Light,spotAngle spotInnerAngle,0_180 0_180,spot light angle,float)] _SpotLightAngle("_SpotLightAngle",Vector) = (45,45,0,0)
        
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
            half _LightType; //dir :0, point :1 ,spot :2
            half _Radius;
            half _Intensity;
            half _Falloff;

            float2 _SpotLightAngle; //{outer:dot range[1,0],innerSpotAngle:dot range[1,0]}
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToNdcHClip(v.vertex,_FullScreenOn,_ScreenRange);
                o.uv = TRANSFORM_TEX(v.uv,_MainTex);
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
// return worldPos.xyzx;
                float3 worldNormal = CalcWorldNormal(worldPos);
//============ light                

                #define shadowAtten 1
                #define distanceAndSpotAttenuation 0

                half isPoint = _LightType >=1;
                half isSpot= _LightType >= 2;
                float2 spotLightAngle = CalcSpotLightAngle(_SpotLightAngle);
// return spotLightAngle.x;
                float3 lightDir = - normalize(unity_ObjectToWorld._13_23_33);
                float4 lightPos = float4(isPoint ? unity_ObjectToWorld._14_24_34 : lightDir,isPoint);

                Light light = GetLight(
                lightPos,
                _LightColor.xyz,
                shadowAtten,
                worldPos,
                distanceAndSpotAttenuation, // unity atten only
                lightDir,
                _Radius,
                _Intensity,
                _Falloff,
                isSpot,
                spotLightAngle);

//============  calc lighting
                float nl = saturate(dot(worldNormal, light.direction));
                // return light.distanceAttenuation * light.color.xyzx * nl;
                float atten = (light.distanceAttenuation  * max(0.1,light.shadowAttenuation) * nl);
                atten *= 1- isFar; // filter out far distance
                float3 radiance = light.color * atten;

//============  mainTex as light cookie
                float2 mainTexUV = i.uv; // screenUV * _MainTex_ST.xy + _MainTex_ST.zw
                half4 mainTex = tex2D(_MainTex, mainTexUV);
                
                radiance *= mainTex.xyz;
                atten *=  mainTex.w;
                return float4(radiance, atten);
            }
            ENDHLSL
        }
    }
}
