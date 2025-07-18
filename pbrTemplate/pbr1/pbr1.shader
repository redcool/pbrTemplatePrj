Shader "URP/pbr1"
{
    Properties
    {
        [GroupHeader(v0.0.8)]
        [Group(Main)]
        [GroupItem(Main)]_BaseMap ("_BaseMap", 2D) = "white" {}
        [GroupItem(Main)][hdr][gamma]_Color ("_Color", color) = (1,1,1,1)
        [GroupItem(Main)]_NormalMap("_NormalMap",2d)="bump"{}
        [GroupItem(Main)]_NormalScale("_NormalScale",range(0,5)) = 1

        [Group(PBR Mask)]
        [GroupItem(PBR Mask)]_MetallicMaskMap("_PbrMask",2d)="white"{}

        [GroupItem(PBR Mask)]_Metallic("_Metallic",range(0,1)) = 0.5
        [GroupItem(PBR Mask)]_Smoothness("_Smoothness",range(0,1)) = 0.5
        [GroupItem(PBR Mask)]_Occlusion("_Occlusion",range(0,1)) = 0

        [Group(LightMode)]   
        [GroupToggle(LightMode)]_SpecularOn("_SpecularOn",int) = 1
        // [Enum(PBR,0,Aniso,1,Charlie,2)]_PbrMode("_PbrMode",int) = 0
        [GroupEnum(LightMode,_PBRMODE_PBR _PBRMODE_ANISO _PBRMODE_CHARLIE,true)]_PbrMode("_PbrMode",int) = 0
        
        [Group(Shadow)]
        //[LineHeader(Shadows)]
        [GroupToggle(Shadow,_RECEIVE_SHADOWS_OFF)]_ReceiveShadowOff("_ReceiveShadowOff",int) = 0
        [GroupItem(Shadow)]_MainLightShadowSoftScale("_MainLightShadowSoftScale",range(0,1)) = 0.1

        [GroupHeader(Shadow,custom bias)]
        [GroupSlider(Shadow)]_CustomShadowNormalBias("_CustomShadowNormalBias",range(-1,1)) = 0
        [GroupSlider(Shadow)]_CustomShadowDepthBias("_CustomShadowDepthBias",range(-1,1)) = 0

        [Group(AdditionalLights)]
        [GroupToggle(AdditionalLights,_ADDITIONAL_LIGHTS_ON)]_CalcAdditionalLights("_CalcAdditionalLights",int) = 0
        [GroupToggle(AdditionalLights,_ADDITIONAL_LIGHT_SHADOWS_ON)]_ReceiveAdditionalLightShadow("_ReceiveAdditionalLightShadow",int) = 1
        // [GroupToggle(AdditionalLights,_ADDITIONAL_LIGHT_SHADOWS_SOFT)]_AdditionalIghtSoftShadow("_AdditionalIghtSoftShadow",int) = 0
        
        [Group(Emission)]
        [GroupToggle(Emission,_EMISSION)]_EmissionOn("_EmissionOn",int) = 0
        [GroupItem(Emission)]_EmissionMap("_EmissionMap",2d)=""{}
        [GroupItem(Emission)]_EmissionColor("_EmissionColor(w:mask)",color) = (0,0,0,0)
        [GroupMaterialGI(Emission)]_EmissionGI("_EmissionGI",int) = 0

        [Group(Aniso)]
        [GroupToggle(Aniso)]_CalcTangent("_CalcTangent",int) = 0
        [GroupItem(Aniso)]_AnisoRough("_AnisoRough",range(-0.5,0.5)) = 0
        [GroupItem(Aniso)]_AnisoShift("_AnisoShift",range(-1,1)) = 0

        [Group(Thin Film)]
        [GroupToggle(Thin Film)]_TFOn("_TFOn",int) = 0
        [GroupItem(Thin Film)]_TFScale("_TFScale",float) = 1
        [GroupItem(Thin Film)]_TFOffset("_TFOffset",float) = 0
        [GroupItem(Thin Film)]_TFSaturate("_TFSaturate",range(0,1)) = 1
        [GroupItem(Thin Film)]_TFBrightness("_TFBrightness",range(0,1)) = 1

//================================================= Parallax
        [Group(Parallax)]
        [GroupToggle(Parallax)]_ParallaxOn("_ParallaxOn",int) = 0
        [GroupSlider(Parallax,iterate count,int)]_ParallaxIterate("_ParallaxIterate",range(1,10)) = 1
        // [GroupToggle(Parallax,run in vertex shader)]_ParallaxInVSOn("_ParallaxInVSOn",int) = 0
        
        [GroupItem(Parallax)]_ParallaxMap("_ParallaxMap",2d) = "white"{}
        [GroupEnum(Parallax,R 0 G 1 B 2 A 3)]_ParallaxMapChannel("_ParallaxMapChannel",int) = 3
        [GroupSlider(Parallax)]_ParallaxHeight("_ParallaxHeight",range(0.005,0.3)) = 0.01        

        [Group(Fog)]
        [GroupToggle(Fog)]_FogOn("_FogOn",int) = 1
        [GroupToggle(Fog,SIMPLE_FOG,use simple linear depth height fog)]_SimpleFog("_SimpleFog",int) = 0
        [GroupToggle(Fog)]_FogNoiseOn("_FogNoiseOn",int) = 0
        [GroupToggle(Fog)]_DepthFogOn("_DepthFogOn",int) = 1
        [GroupToggle(Fog)]_HeightFogOn("_HeightFogOn",int) = 1
//================================================= AnimTex
		[Group(GPUSkin)]
        [GroupEnum(GPUSkin,_None _ANIM_TEX_ON _GPU_SKINNED_ON,true,use AnimTex or GpuSkin)] _GpuSkinnedOn("_GpuSkinOn",float) = 0

		[Group(AnimTex)]
        [GroupToggle(AnimTex,_ANIM_TEX_ON)] _AnimTexOn("Anim Tex ON",float) = 0
		[GroupItem(AnimTex)] _AnimTex("Anim Tex",2d) = ""{}
		[GroupItem(AnimTex)] _AnimSampleRate("Anim Sample Rate",float) = 30
		[GroupItem(AnimTex)] _StartFrame("Start Frame",float) = 0
		[GroupItem(AnimTex)] _EndFrame("End Frame",float) = 1
		[GroupItem(AnimTex)] _Loop("Loop[0:Loop,1:Clamp]",range(0,1)) = 1
		[GroupItem(AnimTex)] _PlayTime("Play Time",float) = 0
		[GroupItem(AnimTex)] _OffsetPlayTime("Offset Play Time",float) = 0

		[GroupItem(AnimTex)] _NextStartFrame("Next Anim Start Frame",float) = 0
		[GroupItem(AnimTex)] _NextEndFrame("Next Anim End Frame",float) = 0
		[GroupItem(AnimTex)] _CrossLerp("Cross Lerp",range(0,1)) = 0

        // [Group(Lightmap)]
        // [GroupToggle(Lightmap,LIGHTMAP_ON)]_LightmapOn("_LightmapOn",int) = 0
        [Group(Alpha)]
        [GroupHeader(Alpha,BlendMode)]
        [GroupPresetBlendMode(Alpha,,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=0
        // [GroupEnum(Alpha,UnityEngine.Rendering.BlendMode)]
        [HideInInspector]_SrcMode("_SrcMode",int) = 1
        [HideInInspector]_DstMode("_DstMode",int) = 0

        [GroupHeader(Alpha,Premultiply)]
        [GroupToggle(Alpha)]_AlphaPremultiply("_AlphaPremultiply",int) = 0

        [GroupHeader(Alpha,AlphaTest)]
        [GroupToggle(Alpha,ALPHA_TEST)]_AlphaTestOn("_AlphaTestOn",int) = 0
        [GroupSlider(Alpha)]_Cutoff("_Cutoff",range(0,1)) = 0.5

        [Group(Settings)]
        [GroupEnum(Settings,UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 2
		[GroupToggle(Settings)]_ZWriteMode("ZWriteMode",int) = 1
		/*
		Disabled,Never,Less,Equal,LessEqual,Greater,NotEqual,GreaterEqual,Always
		*/
		[GroupEnum(Settings,UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",float) = 4
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			ZWrite[_ZWriteMode]
			Blend [_SrcMode][_DstMode]
			// BlendOp[_BlendOp]
			Cull[_CullMode]
			ztest[_ZTestMode]
			// ColorMask [_ColorMask]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            // #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE //_MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma shader_feature_fragment _ADDITIONAL_LIGHTS_ON
            #pragma shader_feature_fragment _ _ADDITIONAL_LIGHT_SHADOWS_ON
            // #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS_SOFT

            // #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #define SHADOWS_FULL_MIX // for shadowMask
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fragment _ LIGHTMAP_ON

            #pragma shader_feature_fragment _PBRMODE_PBR _PBRMODE_ANISO _PBRMODE_CHARLIE
            // #pragma shader_feature_fragment _DEPTH_FOG_NOISE_ON
            #pragma shader_feature SIMPLE_FOG

            // #pragma shader_feature_local _PARALLAX
            #pragma shader_feature_fragment _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_fragment ALPHA_TEST
            #pragma shader_feature_fragment _EMISSION
            #pragma shader_feature_vertex _ _ANIM_TEX_ON _GPU_SKINNED_ON
            
            #include "Lib/PBRInput.hlsl"
            #include "Lib/PBRForwardPass.hlsl"
            
            ENDHLSL
        }

        Pass{
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            #pragma shader_feature_fragment ALPHA_TEST

            #define USE_SAMPLER2D
            #include "Lib/PBRInput.hlsl"
            #include "../../../PowerShaderLib/URPLib/ShadowCasterPass.hlsl"

            ENDHLSL
        }

        Pass{
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma shader_feature_fragment ALPHA_TEST
            #pragma shader_feature_vertex _ _ANIM_TEX_ON _GPU_SKINNED_ON
            
            #define SHADOW_PASS 
            #define USE_SAMPLER2D
            #define _MainTexChannel 3
            #define _CustomShadowNormalBias _CustomShadowNormalBias
            #define _CustomShadowDepthBias _CustomShadowDepthBias
            #include "Lib/PBRInput.hlsl"
            #include "../../../PowerShaderLib/URPLib/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass{
            Name "Meta"
            Tags{"LightMode" = "Meta"}
            Cull Off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            #pragma shader_feature_fragment ALPHA_TEST
            #pragma shader_feature_local_fragment _EMISSION

            #include "Lib/PBRInput.hlsl"
            #include "../../../PowerShaderLib/URPLib/PBR1_MetaPass.hlsl"

            ENDHLSL
        }        
    }
}
