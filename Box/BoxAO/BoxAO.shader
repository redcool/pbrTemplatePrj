Shader "FX/Box/AO"
{
    Properties
    {
        [GroupHeader(v0.0.1)]
        [Group(Base)]
        [GroupToggle(Base)]_FullScreenOn("_FullScreenOn",int) = 1
        [GroupVectorSlider(Base,minX minY maxX maxY,0_1 0_1 0_1 0_1,limit screen range,float)]_ScreenRange("ScreenRange",vector) = (0,0,1,1)
        
        [Group(HBAO)]
        [GroupItem(HBAO)] _AORangeMin("_AORangeMin",range(0,1)) = 0.1
        [GroupItem(HBAO)] _AORangeMax("_AORangeMax",range(0,1)) = 1
        [GroupItem(HBAO)] _StepScale("_StepScale",range(0.02,.2)) = 0.1

        [GroupSlider(HBAO,direction count ,int)] _DirCount("_DirCount",range(4,20)) = 10
        [GroupSlider(HBAO,calc times a count,int)] _StepCount("_StepCount",range(4,20)) = 4
        
        [GroupToggle((HBAO),_NORMAL_FROM_DEPTH)] _NormalFromDepth("_NormalFromDepth",float) = 0
// ================================================== alpha      
        [Group(Alpha)]
        [GroupHeader(Alpha,BlendMode)]
        [GroupPresetBlendMode(Alpha,,_SrcMode,_DstMode)]_PresetBlendMode("_PresetBlendMode",int)=0
        [HideInInspector]_SrcMode("_SrcMode",int) = 1
        [HideInInspector]_DstMode("_DstMode",int) = 0

        // [GroupHeader(Alpha,Premultiply)]
        // [GroupToggle(Alpha)]_AlphaPremultiply("_AlphaPremultiply",int) = 0

//         [GroupHeader(Alpha,AlphaTest)]
//         [GroupToggle(Alpha,ALPHA_TEST)]_AlphaTestOn("_AlphaTestOn",int) = 0
//         [GroupSlider(Alpha)]_Cutoff("_Cutoff",range(0,1)) = 0.5
// // ================================================== Settings
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
        [GroupEnum(Stencil,UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Float) = 0
        [GroupStencil(Stencil)] _Stencil ("Stencil ID", int) = 0
        [GroupEnum(Stencil,UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Float) = 0
        [GroupHeader(Stencil,)]
        [GroupEnum(Stencil,UnityEngine.Rendering.StencilOp)] _StencilFailOp ("Stencil Fail Operation", Float) = 0
        [GroupEnum(Stencil,UnityEngine.Rendering.StencilOp)] _StencilZFailOp ("Stencil zfail Operation", Float) = 0
        [GroupItem(Stencil)] _StencilWriteMask ("Stencil Write Mask", Float) = 255
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
            Fail [_StencilFailOp]
            ZFail [_StencilZFailOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _NORMAL_FROM_DEPTH

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            #include "../../../PowerShaderLib/Lib/Colors.hlsl"
            #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
            #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
            #include "../../../PowerShaderLib/Lib/FullscreenLib.hlsl"
            #define USE_SAMPLER2D
            #include "../../../PowerShaderLib/Lib/TextureLib.hlsl"
            #include "../../../PowerShaderLib/Lib/ScreenTextures.hlsl"
            #include "../../../PowerShaderLib/URPLib/URP_Input.hlsl"

            #include "../../../PowerShaderLib/Lib/BlitLib.hlsl"
            #include "../../../PowerShaderLib/Lib/AOLib.hlsl"

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

            // sampler2D _MainTex;

            CBUFFER_START(UnityPerMaterial)
            half _FullScreenOn;
            // half4 _MainTex_ST;
            half4 _ScreenRange;
            // half _Cutoff;

            float _AORangeMax,_AORangeMin;
            float _StepScale;
            float _DirCount,_StepCount;
            CBUFFER_END
            half4 _MainTex_TexelSize;

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
                float depthTex = GetScreenDepth(screenUV);
                half isFar = IsTooFar(depthTex.x);

                // float3 screenCol = GetScreenColor(screenUV);
                // float3 gray = dot(screenCol,float3(0.2,0.7,0.1));

                // float3 worldPos = ScreenToWorldPos(screenUV,depthTex,UNITY_MATRIX_I_VP);
                // float3 worldNormal = GetScreenNormal(screenUV);
                // float3 worldNormal = CalcWorldNormal(worldPos);
                // return worldNormal.xyzx;

                float3 worldPos = ScreenToWorld(screenUV);
                float3 viewPos = WorldToViewPos(worldPos);
                float4 screenCol = GetScreenColor(screenUV);

                #if defined(_NORMAL_FROM_DEPTH)
                float3 worldNormal = CalcWorldNormal(worldPos);
                #else
                float3 worldNormal = GetScreenNormal(screenUV);
                #endif
                float3 viewNormal = normalize(WorldToViewNormal(worldNormal));

                float occlusion = CalcHBAO(screenUV,viewNormal,viewPos,_DirCount,_StepCount,_StepScale,_AORangeMin,_AORangeMax);
                // return occlusion ;
                return half4(screenCol.xyz * occlusion,1);
            }
            ENDHLSL
        }
    }
}
