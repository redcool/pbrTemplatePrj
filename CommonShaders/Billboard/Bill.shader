shader "Unlit/Bill"
{
    Properties
    {
        [GroupHeader(v2.0.1)]
        _MainTex ("Texture", 2D) = "white" {}
        _Color("_Color",color) = (1,1,1,1)
        // [GroupToggle]_FullFaceCamera("_FullFaceCamera",int) = 0


        [Group(Alpha)]
        [GroupPresetBlendMode(Alpha,blend mode,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=0

        [GroupToggle(Alpha,ALPHA_TEST)]_ClipOn("_ClipOn",int) = 0
        [GroupItem(Alpha)]_Cutoff("_Cutoff",range(0,1)) = 0.5

        [Group(ShadowCaster)]
        [GroupToggle(ShadowCaster)]_RotateShadow("_RotateShadow",int) = 0

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


    // nothing
    // #if defined(INSTANCING_ON)
        // #define UnityPerMaterial _UnityPerMaterial
    // #endif

    // define variables
    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
        UNITY_DEFINE_INSTANCED_PROP(float4,_MainTex_ST)
        UNITY_DEFINE_INSTANCED_PROP(float4,_Color)
        
        // UNITY_DEFINE_INSTANCED_PROP(float,_FullFaceCamera)
        UNITY_DEFINE_INSTANCED_PROP(float,_Cutoff)
        UNITY_DEFINE_INSTANCED_PROP(float,_RotateShadow)
        
    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

    // define shortcot getters
    #define _MainTex_ST UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_MainTex_ST)
    #define _Color UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Color)
    #define _FullFaceCamera UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_FullFaceCamera)
    #define _Cutoff UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Cutoff)
    #define _RotateShadow UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_RotateShadow)
    

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
        float2 uv1:TEXCOORD1;
        float3 n:NORMAL;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct v2f
    {
        float4 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
        float3 n:TEXCOORD1;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    sampler2D _MainTex;
    float4x4 _CameraYRot;

    v2f vertBill (appdata v)
    {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_TRANSFER_INSTANCE_ID(v, o);


        v.vertex.xyz = mul((_CameraYRot),v.vertex).xyz;
        o.vertex = TransformObjectToHClip(v.vertex);
        // o.vertex = TransformBillboardObjectToHClip(v.vertex ,_FullFaceCamera);

        o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
        o.uv.zw = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
        o.n = TransformObjectToWorldNormal(v.n);
        return o;
    }

    float4 fragBill (v2f i) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(i);

        float2 mainUV = i.uv.xy;
        float2 lightmapUV = i.uv.zw;

        float3 sh = SampleSH(i.n);
        // sample the texture
        float4 mainTex = tex2D(_MainTex, mainUV) * _Color;
        float3 albedo = mainTex.xyz;
        float alpha = mainTex.w;
        #if defined(ALPHA_TEST)
            clip(alpha - _Cutoff);
        #endif

        half3 giDiff = CalcGIDiff(i.n,albedo,lightmapUV);
        half3 diffColor = albedo + giDiff;

        return float4(diffColor,1);
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
