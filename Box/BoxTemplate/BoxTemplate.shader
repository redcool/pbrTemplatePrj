Shader "Hidden/FX/Box/Template"
{
    Properties
    {
        [GroupHeader(v0.0.1)]
        [Group(Base)]
        [GroupToggle(Base)]_FullScreenOn("_FullScreenOn",int) = 1
        [GroupVectorSlider(Base,minX minY maxX maxY,0_1 0_1 0_1 0_1,limit screen range,float)]_ScreenRange("ScreenRange",vector) = (0,0,1,1)

        _MainTex("_MainTex",2d)=""{}

// ================================================== alpha      
        [Group(Alpha)]
        [GroupHeader(Alpha,BlendMode)]
        [GroupPresetBlendMode(Alpha,,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=0
        [HideInInspector]_SrcMode("_SrcMode",int) = 1
        [HideInInspector]_DstMode("_DstMode",int) = 0

        // [GroupHeader(Alpha,Premultiply)]
        // [GroupToggle(Alpha)]_AlphaPremultiply("_AlphaPremultiply",int) = 0

        // [GroupHeader(Alpha,AlphaTest)]
        // [GroupToggle(Alpha,ALPHA_TEST)]_AlphaTestOn("_AlphaTestOn",int) = 0
        // [GroupSlider(Alpha)]_Cutoff("_Cutoff",range(0,1)) = 0.5
// ================================================== Settings
        [Group(Settings)]
        [GroupEnum(Settings,UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 2
		[GroupToggle(Settings)]_ZWriteMode("ZWriteMode",int) = 0

		/*
		Disabled,Never,Less,Equal,LessEqual,Greater,NotEqual,GreaterEqual,Always
		*/
		[GroupEnum(Settings,UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",float) = 4

        [GroupHeader(Settings,Color Mask)]
        [GroupEnum(Settings,RGBA 16 RGB 15 RG 12 GB 6 RB 10 R 8 G 4 B 2 A 1 None 0)] _ColorMask("_ColorMask",int) = 15
// ================================================== stencil settings
        [Group(Stencil)]
		[GroupEnum(Stencil,UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 0
        [GroupItem(Stencil)] _Stencil ("Stencil ID", int) = 0
        [GroupEnum(Stencil,UnityEngine.Rendering.StencilOp)]_StencilOp ("Stencil Operation", Float) = 0
        [HideInInspector] 
        [GroupItem(Stencil)] _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [HideInInspector] 
        [GroupItem(Stencil)] _StencilReadMask ("Stencil Read Mask", Float) = 255
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100

        ZWrite[_ZWriteMode]
        Blend [_SrcMode][_DstMode]
        // BlendOp[_BlendOp]
        Cull [_CullMode]
        ztest [_ZTestMode]
        ColorMask [_ColorMask]

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
            #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
            #include "../../../PowerShaderLib/Lib/FullscreenLib.hlsl"
            #include "../../../PowerShaderLib/URPLib/URP_Input.hlsl"

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
            sampler2D _CameraOpaqueTexture;
            sampler2D _CameraDepthTexture;

            CBUFFER_START(UnityPerMaterial)
            half _FullScreenOn;
            half4 _MainTex_ST;
            half4 _ScreenRange;

            CBUFFER_END

// #define _CameraDepthTexture _CameraDepthAttachment
// #define _CameraOpaqueTexture _CameraColorTexture

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToNdcHClip(v.vertex,_FullScreenOn,_ScreenRange);
                o.uv = v.uv;
                return o;
            }



            float4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;

//============ world pos
                float depthTex = tex2D(_CameraDepthTexture,screenUV).x;
                half isFar = IsTooFar(depthTex.x);
                
                float3 worldPos = ScreenToWorldPos(screenUV,depthTex,UNITY_MATRIX_I_VP);
                return worldPos.xyzx;
            }
            ENDHLSL
        }
    }
}
