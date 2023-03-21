Shader "Character/pbr1"
{
    /*
    lighting(pbr,charlie,aniso)
    shadow(main light)
    fog
    srp batched 

    instanced
    detail()
    alpha

    */
    Properties
    {
        [Group(Main)]
        [GroupItem(Main)]_MainTex ("Texture", 2D) = "white" {}
        [GroupItem(Main)]_Color ("_Color", color) = (1,1,1,1)
        [GroupItem(Main)]_NormalMap("_NormalMap",2d)="bump"{}
        [GroupSlider(Main)]_NormalScale("_NormalScale",range(0,5)) = 1

        [Group(PBR Mask)]
        [GroupItem(PBR Mask)]_PbrMask("_PbrMask",2d)="white"{}

        [GroupItem(PBR Mask)]_Metallic("_Metallic",range(0,1)) = 0.5
        [GroupItem(PBR Mask)]_Smoothness("_Smoothness",range(0,1)) = 0.5
        [GroupItem(PBR Mask)]_Occlusion("_Occlusion",range(0,1)) = 0

        [Group(LightModeGroup)]   
        [GroupToggle(LightModeGroup)]_SpecularOn("_SpecularOn",int) = 1
        // [Enum(PBR,0,Aniso,1,Charlie,2)]_PbrMode("_PbrMode",int) = 0
        [GroupEnum(LightModeGroup,_PBRMODE_PBR _PBRMODE_ANISO _PBRMODE_CHARLIE,true)]_PbrMode("_PbrMode",int) = 0
        
        [Group(ShadowGroup)]
        //[LineHeader(Shadows)]
        [GroupToggle(ShadowGroup)]_ReceiveShadow("_ReceiveShadow",int) = 1
        [GroupItem(ShadowGroup)]_MainLightShadowSoftScale("_MainLightShadowSoftScale",range(0,1)) = 0.1
        //[LineHeader(Shadow Bias)]
        [GroupSlider(ShadowGroup)]_CustomShadowDepthBias("_CustomShadowDepthBias",range(-1,1)) = 0.5
        [GroupSlider(ShadowGroup)]_CustomShadowNormalBias("_CustomShadowNormalBias",range(-1,1)) = 0.5

        [Group(AdditionalLights)]
        [GroupToggle(AdditionalLights,_ADDITIONAL_LIGHTS_ON)]_CalcAdditionalLights("_CalcAdditionalLights",int) = 0
        [GroupToggle(AdditionalLights)]_ReceiveAdditionalLightShadow("_ReceiveAdditionalLightShadow",int) = 1
        [GroupToggle(AdditionalLights)]_AdditionalIghtSoftShadow("_AdditionalIghtSoftShadow",int) = 0

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

        [Group(Fog)]
        [GroupToggle()]_FogOn("_FogOn",int) = 1
        [GroupToggle(_,_DEPTH_FOG_NOISE_ON)]_FogNoiseOn("_FogNoiseOn",int) = 0
        [GroupToggle(_)]_DepthFogOn("_DepthFogOn",int) = 1
        [GroupToggle(_)]_HeightFogOn("_HeightFogOn",int) = 1
        // [Group(Lightmap)]
        // [GroupToggle(Lightmap,LIGHTMAP_ON)]_LightmapOn("_LightmapOn",int) = 0
        
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
            #pragma target 3.0
            // #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHTS_ON

            // #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fragment _ LIGHTMAP_ON

            #pragma shader_feature _PBRMODE_PBR _PBRMODE_ANISO _PBRMODE_CHARLIE
            #pragma shader_feature _DEPTH_FOG_NOISE_ON

            #include "Lib/PBRForwardPass.hlsl"
            
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
            
            #define SHADOW_PASS 
            #include "Lib/ShadowCasterPass.hlsl"

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

            #include "Lib/ShadowCasterPass.hlsl"

            ENDHLSL
        }
    }
}
