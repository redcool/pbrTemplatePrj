Shader "URP/Unlit/Template"
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
            #pragma shader_feature ALPHA_TEST
            // #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            half _Cutoff;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv) * _Color;
                #if defined(ALPHA_TEST)
                    clip(col.w - _Cutoff);
                #endif
                return col;
            }
            ENDHLSL
        }
    }
}
