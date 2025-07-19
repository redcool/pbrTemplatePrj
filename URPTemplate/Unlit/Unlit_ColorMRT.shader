Shader "Template/Unlit/Color_MRT"
{
    Properties
    {
        [Group(Main)]
        [GroupItem(Main)] _MainTex ("Texture", 2D) = "white" {}
        [GroupToggle(Main,,sample texture use uv1)] _UseUV1 ("_UseUV1", float) = 0
        [GroupToggle(Main,,uv1 y reverse)] _UV1ReverseY ("_UV1ReverseY", float) = 0
        [GroupItem(Main)] [hdr] _Color("_Color",color) = (1,1,1,1)

        [Group(Fog)]
        [GroupToggle(Fog)]_FogOn("_FogOn",int) = 1
        [GroupToggle(Fog,SIMPLE_FOG,use simple linear depth height fog)]_SimpleFog("_SimpleFog",int) = 0
        [GroupToggle(Fog)]_FogNoiseOn("_FogNoiseOn",int) = 0
        [GroupToggle(Fog)]_DepthFogOn("_DepthFogOn",int) = 1
        [GroupToggle(Fog)]_HeightFogOn("_HeightFogOn",int) = 1

        [Group(Normal)]
        [GroupToggle(Normal, ,output flat normal)]_NormalUnifiedOn("_NormalUnifiedOn",int) = 0
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
            #pragma shader_feature SIMPLE_FOG
            #pragma shader_feature ALPHA_TEST

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/URPLib/URP_MotionVectors.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1:TEXCOORD1;
                DECLARE_MOTION_VS_INPUT(prevPos);
                float3 normal:NORMAL;
                float4 color:COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldPos:TEXCOORD1;
                float2 fogCoord:TEXCOORD2;
                // motion vectors
                DECLARE_MOTION_VS_OUTPUT(6,7);
                float4 color:COLOR;
                float4 normal:TEXCOORD3;
            };

            sampler2D _MainTex;
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            half _FogOn,_FogNoiseOn,_DepthFogOn,_HeightFogOn;
            half _Cutoff;
            half _NormalUnifiedOn;
            half _UseUV1,_UV1ReverseY;
            CBUFFER_END
            
            #include "../../../PowerShaderLib/Lib/FogLib.hlsl"


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = _UV1ReverseY ? float2(v.uv1.x, 1 - v.uv1.y) : v.uv1;
                o.worldPos.xyz = TransformObjectToWorld(v.vertex.xyz);
                o.fogCoord = CalcFogFactor(o.worldPos.xyz,o.vertex.z,_HeightFogOn,_DepthFogOn);
                o.color = v.color;
                o.normal.xyz = _NormalUnifiedOn ? 0.5 : v.normal;

                CALC_MOTION_POSITIONS(v.prevPos,v.vertex,o,o.vertex);

                return o;
            }

            float4 frag (v2f i,out float4 outputNormal:SV_TARGET1,out float4 outputMotionVectors:SV_TARGET2) : SV_Target
            {
                float2 uv = _UseUV1? i.uv.zw : i.uv.xy;
                // sample the texture
                float4 col = tex2D(_MainTex, uv) * _Color * i.color;
                #if defined(ALPHA_TEST)
                    clip(col.w - _Cutoff);
                #endif
                float3 worldPos = i.worldPos.xyz;
                //-------- output mrt
                // output world normal
                outputNormal = half4(i.normal.xyz,0.5);
                // output motion
                outputMotionVectors = CALC_MOTION_VECTORS(i);

                BlendFogSphereKeyword(col.rgb/**/,worldPos,i.fogCoord.xy,_HeightFogOn,_FogNoiseOn,_DepthFogOn); // 2fps

                return col;
            }
            ENDHLSL
        }
    }
}
