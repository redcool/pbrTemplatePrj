shader "URP/Unlit/Bill"
{
    Properties
    {
        [GroupHeader(v2.0.3)]
        [Group(Main)]
        [GroupItem(Main)] _MainTex ("Texture", 2D) = "white" {}
        [GroupItem(Main)] [hdr]_Color("_Color",color) = (1,1,1,1)
        [GroupToggle(Main,_FACE_CAMERA)]_FullFaceCamera("_FullFaceCamera",int) = 0

//=================================================  Lighting
        [Group(Lighting)]
        // [GroupToggle(Lighting)]_ApplyMainLightColor("_ApplyMainLightColor",int) = 1
        [GroupItem(Lighting)]_Metallic("_Metallic",range(0,1)) = 0.5



        [GroupHeader(Lighting,Diffuse)]
        [GroupVectorSlider(Lighting,Min Max,0_1 0_1)] _DiffuseRange("_DiffuseRange",vector) = (0,0.5,0,0)
        [GroupItem(Lighting,PosRange)] _TopdownLine("_TopdownLine",range(-5,5))= 0
        [GroupItem(Lighting,Blend)] _DiffuseBlend("_DiffuseBlend",range(0,1)) = 0

        [GroupHeader(Lighting,MatCap)]
        [GroupItem(Lighting,specTerm use )] _MatCap("_MatCap",2d)=""{}
        [GroupItem(Lighting)] _MatCapScale("_MatCapScale",float)= 1

//=================================================  weather
        [Group(Fog)]
        [GroupToggle(Fog)]_FogOn("_FogOn",int) = 1
        // [GroupToggle(Fog,SIMPLE_FOG,use simple linear depth height fog)]_SimpleFog("_SimpleFog",int) = 0
        [GroupToggle(Fog)]_FogNoiseOn("_FogNoiseOn",int) = 0
        [GroupToggle(Fog)]_DepthFogOn("_DepthFogOn",int) = 1
        [GroupToggle(Fog)]_HeightFogOn("_HeightFogOn",int) = 1

        [Group(Wind)]
        [GroupToggle(Wind)]_WindOn("_WindOn (need vertex color.r)",float) = 0
        [GroupVectorSlider(Wind,branch edge globalOffset flutterOffset,0_0.4 0_0.5 0_0.6 0_0.06)]_WindAnimParam("_WindAnimParam(x:branch,edge,z : global offset,w:flutter offset)",vector) = (1,1,0.1,0.3)
        [GroupVectorSlider(Wind,WindVector Intensity,0_1)]_WindDir("_WindDir,dir:(xyz),Intensity:(w)",vector) = (1,0.1,0,0.5)
        [GroupItem(Wind)]_WindSpeed("_WindSpeed",range(0,1)) = 0.3

        [Group(Snow)]
        [GroupToggle(Snow,_SNOW_ON)]_SnowOn("_SnowOn",int) = 0
        [GroupToggle(Snow,,snow show in edge first)]_ApplyEdgeOn("_ApplyEdgeOn",int) = 1
        [GroupItem(Snow)]_SnowIntensity("_SnowIntensity",range(0,1)) = 0

        [GroupVectorSlider(Snow,NoiseTilingX NoiseTilingY,0_10 0_10,,float)]_SnowNoiseTiling("_SnowNoiseTiling",vector) = (1,1,0,0)
        [GroupToggle(Snow,,mainTex.a as snow atten)] _SnowIntensityUseMainTexA("_SnowIntensityUseMainTexA",int) = 0
//=================================================  CloudShadow
        [Group(CloudShadow)]
        // [GroupToggle(CloudShadow,)]_CloudShadowOn("_CloudShadowOn",int) = 0
        // // [GroupVectorSlider(,TilingX TilingZ OffsetX OffsetZ,m0.0001_10)]
        // [GroupItem(CloudShadow)] _CloudNoiseTilingOffset("_CloudNoiseTilingOffset",vector) = (0.1,0.1,0.1,0.1)
        // [GroupItem(CloudShadow)] _CloudNoiseRangeMin("_CloudNoiseRangeMin",range(0,1)) = 0
        // [GroupItem(CloudShadow)] _CloudNoiseRangeMax("_CloudNoiseRangeMax",range(0,1)) = 1
        // [GroupToggle(CloudShadow,)] _CloudNoiseOffsetStop("_CloudNoiseOffsetStop",float) = 0
        // [GroupItem(CloudShadow)] _CloudShadowColor("_CloudShadowColor",color) = (0,0,0,0)
        // [GroupItem(CloudShadow)] _CloudShadowIntensity("_CloudShadowIntensity",range(0,1)) = 0.5
        // [GroupItem(CloudShadow)] _CloudBaseShadowIntensity("_CloudBaseShadowIntensity",range(0,1)) =0.02
//=================================================  Shadow
        [Group(Shadow)]
        [GroupToggle(Shadow,,shadow caster use matrix _CameraYRot )]_RotateShadow("_RotateShadow",int) = 0
        
        [GroupToggle(Shadow,_RECEIVE_SHADOWS_OFF)]_IsReceiveShadowOff("_IsReceiveShadowOff",int) = 0
//=================================================  alpha
        [Group(Alpha)]
        [GroupHeader(Alpha,Blend)]
        [GroupPresetBlendMode(Alpha,blend mode,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=0
        [HideInInspector][GroupEnum(Alpha,UnityEngine.Rendering.BlendMode)]_SrcMode("_SrcMode",int) = 1
        [HideInInspector][GroupEnum(Alpha,UnityEngine.Rendering.BlendMode)]_DstMode("_DstMode",int) = 0

        [GroupHeader(Alpha,Clip)]
        [GroupToggle(Alpha,ALPHA_TEST)]_ClipOn("_ClipOn",int) = 0
        [GroupItem(Alpha)]_Cutoff("_Cutoff",range(0,1)) = 0.5        
//================================================= Settings
        [Group(Settings)]
		[GroupToggle(Settings)]_ZWriteMode("ZWriteMode",int) = 1
		/*
		Disabled,Never,Less,Equal,LessEqual,Greater,NotEqual,GreaterEqual,Always
		*/
		[GroupEnum(Settings,UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",float) = 4
        [GroupEnum(Settings,UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 2
        [GroupHeader(Settings,Color Mask)]
        [GroupEnum(Settings,RGBA 16 RGB 15 RG 12 GB 6 RB 10 R 8 G 4 B 2 A 1 None 0)] _ColorMask("_ColorMask",int) = 15
// ================================================== stencil settings
        [Group(Stencil)]
        [GroupEnum(Stencil,UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Float) = 0
        [GroupItem(Stencil)] _Stencil ("Stencil ID", int) = 0
        [GroupEnum(Stencil,UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Float) = 0
        [GroupItem(Stencil)] _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [GroupItem(Stencil)] _StencilReadMask ("Stencil Read Mask", Float) = 255


    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            name "Forward"
			ZWrite[_ZWriteMode]
			Blend [_SrcMode][_DstMode]
			// BlendOp[_BlendOp]
			Cull[_CullMode]
			ztest[_ZTestMode]

            Stencil
            {
                Ref [_Stencil]
                Comp [_StencilComp]
                Pass [_StencilOp]
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
            }            

            HLSLPROGRAM
            #pragma vertex vertBill
            #pragma fragment fragBill
            // #pragma multi_compile_instancing
            #pragma shader_feature ALPHA_TEST
            #define _WIND_ON //#pragma shader_feature _WIND_ON
            #pragma shader_feature _SNOW_ON
            #pragma shader_feature_vertex _FACE_CAMERA

            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS //_MAIN_LIGHT_SHADOWS_CASCADE //_MAIN_LIGHT_SHADOWS_SCREEN

            #define _DEPTH_FOG_NOISE_ON
            #include "BillLib.hlsl"

            ENDHLSL
        }
        Pass{
            Tags{"LightMode" = "ShadowCaster"}
            name "ShadowCaster"

            ZWrite On
            ZTest LEqual
            ColorMask 0
            cull off
            HLSLPROGRAM
            #pragma vertex vertBillShadow
            #pragma fragment frag

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #define _WIND_ON //#pragma shader_feature _WIND_ON
            #pragma shader_feature_fragment ALPHA_TEST

            #define _DEPTH_FOG_NOISE_ON
            #include "BillLib.hlsl"
            
            #define SHADOW_PASS 
            #define USE_SAMPLER2D
            #define _MainTexChannel 3
            #define _CustomShadowNormalBias 0
            #define _CustomShadowDepthBias 0
            #include "../../../PowerShaderLib/URPLib/ShadowCasterPass.hlsl"

            // rotate by Mainlight
            float4x4 _MainLightYRot;
            // #define _MainLightYRot _CameraYRot

            shadow_v2f vertBillShadow(shadow_appdata input){
                input.vertex.xyz = _RotateShadow ? mul(_MainLightYRot,input.vertex).xyz : input.vertex.xyz;

                return vert(input);
            }
            

            ENDHLSL
        }
         Pass{
            Name "Meta"
            Tags{"LightMode" = "Meta"}
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment fragBill 
            #pragma shader_feature_fragment ALPHA_TEST
            #pragma shader_feature_local_fragment _EMISSION

            #include "BillLib.hlsl"

            #define _BaseMap _MainTex
            #include "../../../PowerShaderLib/URPLib/MetaPass.hlsl"


            float4 fragBill(Attributes input):SV_Target{
                float4 mainTex = tex2D(_MainTex, input.uv) * _Color;
                float3 emission = 0;
                return MetaFragment(mainTex.xyz,emission);
            }

            ENDHLSL
        }
    }

}
