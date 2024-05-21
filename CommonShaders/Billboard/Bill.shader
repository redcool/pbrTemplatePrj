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
        [Group(Alpha)]
        [GroupHeader(Alpha,Blend)]
        [GroupPresetBlendMode(Alpha,blend mode,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=0

        [GroupHeader(Alpha,Clip)]
        [GroupToggle(Alpha,ALPHA_TEST)]_ClipOn("_ClipOn",int) = 0
        [GroupItem(Alpha)]_Cutoff("_Cutoff",range(0,1)) = 0.5
//=================================================  Lighting
        [Group(Lighting)]
        
        // [GroupToggle(Lighting)]_ApplyMainLightColor("_ApplyMainLightColor",int) = 1
        [GroupItem(Lighting)]_Metallic("_Metallic",range(0,1)) = 0.5

        [GroupHeader(Lighting,Shadow)]
        [GroupToggle(Lighting,shadow caster use matrix _CameraYRot )]_RotateShadow("_RotateShadow",int) = 0

        [GroupHeader(Lighting,Diffuse)]
        [GroupVectorSlider(Lighting,Min Max,0_1 0_1)] _DiffuseRange("_DiffuseRange",vector) = (0,0.5,0,0)

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
        [GroupToggle(Wind,_WIND_ON)]_WindOn("_WindOn (need vertex color.r)",float) = 0
        [GroupVectorSlider(Wind,branch edge globalOffset flutterOffset,0_0.4 0_0.5 0_0.6 0_0.06)]_WindAnimParam("_WindAnimParam(x:branch,edge,z : global offset,w:flutter offset)",vector) = (1,1,0.1,0.3)
        [GroupVectorSlider(Wind,WindVector Intensity,0_1)]_WindDir("_WindDir,dir:(xyz),Intensity:(w)",vector) = (1,0.1,0,0.5)
        [GroupItem(Wind)]_WindSpeed("_WindSpeed",range(0,1)) = 0.3

        [Group(Snow)]
        [GroupToggle(Snow,_SNOW_ON)]_SnowOn("_SnowOn",int) = 0
        [GroupToggle(Snow,,snow show in edge first)]_ApplyEdgeOn("_ApplyEdgeOn",int) = 1
        [GroupItem(Snow)]_SnowIntensity("_SnowIntensity",range(0,1)) = 0

        [GroupVectorSlider(Snow,NoiseTilingX NoiseTilingY,0_10 0_10,,float)]_SnowNoiseTiling("_SnowNoiseTiling",vector) = (1,1,0,0)
        [GroupToggle(Snow,,mainTex.a as snow atten)] _SnowIntensityUseMainTexA("_SnowIntensityUseMainTexA",int) = 0
//=================================================  Settings
        [Group(Settings)]
        [GroupEnum(Settings,UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 2
		[GroupToggle(Settings)]_ZWriteMode("ZWriteMode",int) = 1
		/*
		Disabled,Never,Less,Equal,LessEqual,Greater,NotEqual,GreaterEqual,Always
		*/
		[GroupEnum(Settings,UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",float) = 4

        [HideInInspector][GroupEnum(Alpha,UnityEngine.Rendering.BlendMode)]_SrcMode("_SrcMode",int) = 1
        [HideInInspector][GroupEnum(Alpha,UnityEngine.Rendering.BlendMode)]_DstMode("_DstMode",int) = 0
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

            HLSLPROGRAM
            #pragma vertex vertBill
            #pragma fragment fragBill
            #pragma multi_compile_instancing
            #pragma shader_feature ALPHA_TEST
            #pragma shader_feature _WIND_ON
            #pragma shader_feature _SNOW_ON
            #pragma shader_feature_vertex _FACE_CAMERA

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

            #pragma shader_feature_fragment ALPHA_TEST

            #define _DEPTH_FOG_NOISE_ON
            #include "BillLib.hlsl"
            
            #define SHADOW_PASS 
            #define USE_SAMPLER2D
            #define _MainTexChannel 3
            #define _CustomShadowNormalBias 0
            #define _CustomShadowDepthBias 0
            #include "../../../PowerShaderLib/URPLib/ShadowCasterPass.hlsl"

            shadow_v2f vertBillShadow(shadow_appdata input){
                if(_RotateShadow)
                    input.vertex.xyz = mul(_CameraYRot,input.vertex).xyz;
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
