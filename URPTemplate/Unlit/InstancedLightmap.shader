Shader "Template/Unlit/InstancedLightmap"
{
    Properties
    {
        [Group(Main)]
        [GroupItem(Main)] _MainTex ("Texture", 2D) = "white" {}
        [GroupItem(Main)] [hdr] _Color("_Color",color) = (1,1,1,1)
        // ================================================== stencil settings
        [Group(Stencil)]
        [GroupEnum(Stencil,UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 0
        [GroupStencil(Stencil)] _Stencil ("Stencil ID", int) = 0
        [GroupEnum(Stencil,UnityEngine.Rendering.StencilOp)]_StencilOp ("Stencil Operation", Float) = 0
        [HideInInspector] _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [HideInInspector] _StencilReadMask ("Stencil Read Mask", Float) = 255

        [Group(Alpha)]
        [GroupHeader(Alpha,AlphaTest)]
        [GroupToggle(Alpha,ALPHA_TEST)]_ClipOn("_AlphaTestOn",int) = 0
        [GroupSlider(Alpha)]_Cutoff("_Cutoff",range(0,1)) = 0.5
        
        [GroupHeader(Alpha,BlendMode)]
        [GroupPresetBlendMode(Alpha,,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=0
        // [GroupEnum(Alpha,UnityEngine.Rendering.BlendMode)]
        [HideInInspector]_SrcMode("_SrcMode",int) = 1
        [HideInInspector]_DstMode("_DstMode",int) = 0

//================================================= settings
        [Group(Settings)]
		[GroupToggle(Settings)]_ZWriteMode("ZWriteMode",int) = 1
		/*
		Disabled,Never,Less,Equal,LessEqual,Greater,NotEqual,GreaterEqual,Always
		*/
		[GroupEnum(Settings,UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",float) = 4
        [GroupEnum(Settings,UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 2
    }

    HLSLINCLUDE
    #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
    #include "../../../PowerShaderLib/UrpLib/URP_GI.hlsl"
    ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            blend [_SrcMode][_DstMode]
            zwrite[_ZWriteMode]
            ztest[_ZTestMode]
            cull [_CullMode]

            Stencil
            {
                Ref [_Stencil]
                Comp [_StencilComp]
                Pass [_StencilOp]
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma shader_feature ALPHA_TEST

            // nothing
            // #if defined(INSTANCING_ON)
                // #define UnityPerMaterial _UnityPerMaterial
            // #endif

            // define variables
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4,_MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float,_Cutoff)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            // define shortcot getters
            #define _MainTex_ST UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_MainTex_ST)
            #define _Cutoff UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Cutoff)

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

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.vertex = TransformObjectToHClip(v.vertex);

                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
                o.n = TransformObjectToWorldNormal(v.n);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                float2 mainUV = i.uv.xy;
                float2 lightmapUV = i.uv.zw;

                float3 sh = SampleSH(i.n);
                // sample the texture
                float4 mainTex = tex2D(_MainTex, mainUV);
                float3 albedo = mainTex.xyz;
                float alpha = mainTex.w;
                #if defined(_ALPHA_TEST_ON)
                    clip(alpha - _Cutoff);
                #endif

                half3 giDiff = CalcGIDiff(i.n,albedo,lightmapUV);
                half3 diffColor = albedo + giDiff;

                return float4(diffColor,1);
            }
            ENDHLSL
        }
    }
}
