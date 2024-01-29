shader "Unlit/Bill"
{
    Properties
    {
        [GroupHeader(v2.0.1)]
        _MainTex ("Texture", 2D) = "white" {}
        [hdr]_Color("_Color",color) = (1,1,1,1)
        [GroupToggle()]_ApplyMainLightColor("_ApplyMainLightColor",int) = 1
        // [GroupToggle]_FullFaceCamera("_FullFaceCamera",int) = 0

        [Group(Alpha)]
        [GroupPresetBlendMode(Alpha,blend mode,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=0

        [GroupToggle(Alpha,ALPHA_TEST)]_ClipOn("_ClipOn",int) = 0
        [GroupItem(Alpha)]_Cutoff("_Cutoff",range(0,1)) = 0.5

        [Group(ShadowCaster)]
        [GroupToggle(ShadowCaster)]_RotateShadow("_RotateShadow",int) = 0
//=================================================  weather
        [Group(Fog)]
        [GroupToggle(Fog)]_FogOn("_FogOn",int) = 1
        [GroupToggle(Fog,SIMPLE_FOG,use simple linear depth height fog)]_SimpleFog("_SimpleFog",int) = 0
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
        // [GroupToggle(Snow,,snow show in edge first)]_ApplyEdgeOn("_ApplyEdgeOn",int) = 1
        [GroupItem(Snow)]_SnowIntensity("_SnowIntensity",range(0,1)) = 0
        [GroupToggle(Snow,,mainTex.a as snow atten)] _SnowIntensityUseMainTexA("_SnowIntensityUseMainTexA",int) = 0

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

    HLSLINCLUDE
    #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
    #include "../../../PowerShaderLib/UrpLib/URP_GI.hlsl"
    #include "../../../PowerShaderLib/Lib/BillboardLib.hlsl"
    #include "../../../PowerShaderLib/Lib/NatureLib.hlsl"


    // nothing
    // #if defined(INSTANCING_ON)
        // #define UnityPerMaterial _UnityPerMaterial
    // #endif

    // define variables
    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
        UNITY_DEFINE_INSTANCED_PROP(half4,_MainTex_ST)
        UNITY_DEFINE_INSTANCED_PROP(half4,_Color)
        
        // UNITY_DEFINE_INSTANCED_PROP(float,_FullFaceCamera)
        UNITY_DEFINE_INSTANCED_PROP(half,_Cutoff)
        UNITY_DEFINE_INSTANCED_PROP(half,_RotateShadow)

        UNITY_DEFINE_INSTANCED_PROP(half4,_WindAnimParam)
        UNITY_DEFINE_INSTANCED_PROP(half4,_WindDir)
        UNITY_DEFINE_INSTANCED_PROP(half,_WindSpeed)
        UNITY_DEFINE_INSTANCED_PROP(half,_ApplyMainLightColor)

        UNITY_DEFINE_INSTANCED_PROP(half,_SnowIntensity)
        UNITY_DEFINE_INSTANCED_PROP(half,_SnowIntensityUseMainTexA)

        UNITY_DEFINE_INSTANCED_PROP(half,_FogOn)
        UNITY_DEFINE_INSTANCED_PROP(half,_FogNoiseOn)
        UNITY_DEFINE_INSTANCED_PROP(half,_DepthFogOn)
        UNITY_DEFINE_INSTANCED_PROP(half,_HeightFogOn)
        
    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

    // define shortcot getters
    #define _MainTex_ST UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_MainTex_ST)
    #define _Color UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Color)
    #define _FullFaceCamera UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_FullFaceCamera)
    #define _Cutoff UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Cutoff)
    #define _RotateShadow UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_RotateShadow)

    #define _WindAnimParam UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_WindAnimParam)
    #define _WindDir UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_WindDir)
    #define _WindSpeed UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_WindSpeed)
    #define _ApplyMainLightColor UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_ApplyMainLightColor)

    #include "../../../PowerShaderLib/Lib/FogLib.hlsl"

    struct appdata
    {
        float4 vertex : POSITION;
        float3 normal:NORMAL;
        float4 color:COLOR;
        float2 uv : TEXCOORD0;
        float2 uv1:TEXCOORD1;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct v2f
    {
        float4 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
        float3 normal:TEXCOORD1;
        float4 worldPos:TEXCOORD2;
        float4 fogCoord:TEXCOORD3;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    sampler2D _MainTex;
    float4x4 _CameraYRot;

    v2f vertBill (appdata v)
    {
        v2f o = (v2f)0;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_TRANSFER_INSTANCE_ID(v, o);

        v.vertex.xyz = mul((_CameraYRot),v.vertex).xyz;
        float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
        o.normal = TransformObjectToWorldNormal(v.normal);
        #if defined(_WIND_ON)
        branch_if(IsWindOn())
        {
            float4 attenParam = v.color.x;
            worldPos = WindAnimationVertex(worldPos,v.vertex.xyz,o.normal,attenParam * _WindAnimParam, _WindDir,_WindSpeed).xyz;
        }
        #endif

        o.vertex = TransformWorldToHClip(worldPos);
        // o.vertex = TransformBillboardObjectToHClip(v.vertex ,_FullFaceCamera);

        o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
        o.uv.zw = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;

        o.worldPos.xyz = worldPos;
        o.fogCoord.xy = CalcFogFactor(worldPos.xyz,o.vertex.z,_HeightFogOn,_DepthFogOn);
        return o;
    }

    float4 fragBill (v2f i) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(i);

        float2 mainUV = i.uv.xy;
        float2 lightmapUV = i.uv.zw;

        float3 sh = SampleSH(i.normal);
        // sample the texture
        float4 mainTex = tex2D(_MainTex, mainUV) * _Color;

        float3 albedo = mainTex.xyz;
        float alpha = mainTex.w;
        #if defined(_SNOW_ON)
        branch_if(IsSnowOn())
        {
            half snowAtten = (_SnowIntensityUseMainTexA ? alpha : 1) * _SnowIntensity;            
            albedo = MixSnow(albedo,1,snowAtten,i.normal);
        }
        #endif        
        #if defined(ALPHA_TEST)
            clip(alpha - _Cutoff);
        #endif

        half3 giDiff = CalcGIDiff(i.normal,albedo,lightmapUV);
        half3 diffCol = albedo * (_ApplyMainLightColor? _MainLightColor.xyz : 1);
        half3 col = diffCol + giDiff;

        BlendFogSphereKeyword(col.rgb/**/,i.worldPos.xyz,i.fogCoord.xy,_HeightFogOn,_FogNoiseOn,_DepthFogOn); // 2fps

        return float4(col,1);
    }
    ENDHLSL

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

            HLSLPROGRAM
            #pragma vertex vertBill
            #pragma fragment fragBill
            #pragma multi_compile_instancing
            #pragma shader_feature ALPHA_TEST
            #pragma shader_feature _WIND_ON
            #pragma shader_feature_local_fragment _SNOW_ON

            ENDHLSL
        }
        Pass{
            Tags{"LightMode" = "ShadowCaster"}

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
