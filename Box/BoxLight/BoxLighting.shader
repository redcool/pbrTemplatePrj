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
        

        [GroupHeader(Light,MainLight Shadow)]
        [GroupToggle(Light,_RECEIVE_SHADOWS_OFF)]_ReceiveShadowOff("_ReceiveShadowOff",int) = 0
        [GroupItem(Light)]_MainLightShadowSoftScale("_MainLightShadowSoftScale",range(0,1)) = 0.1

        [GroupHeader(Light,BigShadow)]
        [GroupToggle(Light)]_BigShadowOff("_BigShadowOff",int) = 0
// ================================================== Volume Smoke
        [Group(Volume)]
        [GroupToggle(Volume,_BOX_VOLUME_ON)]_VolumeOn("Volume Fog",int) = 0
        [GroupItem(Volume)] _VolumeTex("Volume Noise 3D", 3D) = "white" {}
        [GroupItem(Volume)]_VolumeDensity("Density",range(0,2)) = 0.5
        [GroupItem(Volume)]_VolumeDensityHeightAtten("_VolumeDensityHeightAtten",range(0,2)) = 0.5
        [GroupItem(Volume)]_VolumeExtinction("Extinction",range(0,5)) = 1.0
        [GroupItem(Volume)]_VolumeTexScale("Volume Texture Scale",float) = 2.0
        [GroupItem(Volume)]_VolumeTexSpeed("Volume Texture Speed",range(0,1)) = 0.1
// ================================================== alpha      
        [Group(Alpha)]
        [GroupToggle(Alpha,_ALPHA_TEST)] _AlphaTestOn("_AlphaTestOn",int) = 0
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
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma shader_feature _BOX_VOLUME_ON

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
            #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
            #include "../../../PowerShaderLib/Lib/FullscreenLib.hlsl"
            #include "../../../PowerShaderLib/URPLib/URP_Input.hlsl"
            #include "../../../PowerShaderLib/URPLib/Lighting.hlsl"
            #include "../../../PowerShaderLib/Lib/ScreenTextures.hlsl"

            #include "../../../PowerShaderLib/Lib/BigShadows.hlsl"
            #include "../../../PowerShaderLib/Lib/BoxVolumeLib.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
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

            float _BigShadowOff;

            half _VolumeDensity;
            half _VolumeDensityHeightAtten;
            half _VolumeExtinction;
            half _VolumeTexScale;
            half _VolumeTexSpeed;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToNdcHClip(v.vertex,_FullScreenOn,_ScreenRange);
                o.uv.xy = TRANSFORM_TEX(v.uv,_MainTex);

                float2 lightmapUV = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
                o.uv.zw = lightmapUV;

                return o;
            }

            float GetShadowAtten(float3 worldPos){
                float4 shadowCoord = TransformWorldToShadowCoord(worldPos);
                float shadowAttenuation = CalcShadow(shadowCoord,worldPos,1);

                branch_if(!_BigShadowOff)
                {
                    float3 bigShadowCoord = TransformWorldToBigShadow(worldPos);
                    // i.bigShadowCoord.z += 0.001;
                    float atten = CalcBigShadowAtten(bigShadowCoord.xyz,1);
                    shadowAttenuation = min(shadowAttenuation,atten);
                }
                return shadowAttenuation;
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

                #define shadowAtten GetShadowAtten(worldPos)
                // #define shadowAtten 1
                #define distanceAndSpotAttenuation 0

                half isPoint = _LightType >=1;
                half isSpot= _LightType >= 2;
                float2 spotLightAngleCos = CalcSpotLightAngleAtten(_SpotLightAngle);
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
                spotLightAngleCos);

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

//============  volume scattering (dust/smoke within the box)
#if defined(_BOX_VOLUME_ON)
                float3 right   = UNITY_MATRIX_M._11_21_31;
                float3 up      = UNITY_MATRIX_M._12_22_32;
                float3 forward = UNITY_MATRIX_M._13_23_33;
                float3 center  = UNITY_MATRIX_M._14_24_34;
                float3 halfExt = (abs(right) + abs(up) + abs(forward)) * 0.5;

                float3 boundsMin = center - halfExt;
                float3 boundsMax = center + halfExt;

                float3 viewDir = normalize(worldPos - _WorldSpaceCameraPos);
                half4 vol = BoxVolumeScattering_3DTex(
                    boundsMin, boundsMax,
                    worldPos, viewDir,
                    light.color, light.distanceAttenuation,
                    _VolumeDensity, _VolumeExtinction,
                    _VolumeTexScale, _VolumeTexSpeed);

                // 体积雾: 表面光 × 透过率 + 散射光 (雾既遮挡又发光)
                radiance = radiance * vol.a + vol.rgb;
                // 雾的可见度提升 alpha，避免表面暗处雾被裁剪
                atten += (1-vol.a) * light.distanceAttenuation;
#endif

                return float4(radiance, atten);
            }
            ENDHLSL
        }
    }
}
