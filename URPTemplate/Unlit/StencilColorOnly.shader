Shader "Template/Unlit/StencilColorOnly"
{
    Properties
    {
        [GroupHeader(Main,stencilOutline)]
        [GroupItem(Main)]_StencilOutlineWidth("_StencilOutlineWidth",float) = 1
        [GroupItem(Main)]_StencilOutlineColor("_StencilOutlineColor",color) = (1,1,1,1)
        [GroupItem(Main)]_ZOffset("_ZOffset",float) = 1
        
// ================================================== stencil settings
        [Group(Stencil)]
        [GroupEnum(Stencil,UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 0
        [GroupItem(Stencil)]_Stencil ("Stencil ID", int) = 0
        [GroupEnum(Stencil,UnityEngine.Rendering.StencilOp)]_StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        [Header(Blend)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcMode("_SrcMode",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstMode("_DstMode",int) = 0

//================================================= settings
        [Header(Settings)]
        [GroupToggle]_ZWriteMode("_ZWriteMode",int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",int) = 4
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"}
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

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
            float _StencilOutlineWidth;
            half4 _StencilOutlineColor;
            half _ZOffset;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;

                float3 pos = mul(
                    half3x3(
                        _StencilOutlineWidth,0,0,
                        0,_StencilOutlineWidth,0,
                        0,0,_StencilOutlineWidth
                    ) ,v.vertex.xyz
                    );
                o.vertex = TransformObjectToHClip(pos);
                OffsetHClipVertexZ(o.vertex,_ZOffset);
                // o.vertex.xy *= _StencilOutlineWidth;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                return _StencilOutlineColor;
            }
            ENDHLSL
        }
    }
}
