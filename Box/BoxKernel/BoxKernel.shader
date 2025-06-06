Shader "FX/Box/Kernels"
{
    Properties
    {
        [GroupHeader(v0.0.1)]
        [Group(Base)]
        [GroupToggle(Base)]_FullScreenOn("_FullScreenOn",int) = 1

        [GroupItem(Base)] _MainTex("_MainTex",2d)=""{}
        [GroupItem(Base)] [hdr]_KernelColor("_KernelColor",color)=(1,1,1,1)
        [GroupItem(Base)] _TexelSizeScale("_TexelSizeScale",range(0.1,20)) = 1
        [GroupEnum(Base,_OFFSETS_3X3 _OFFSETS_2X2,true,samples 3x3 or 2x2 )]_OffsetMode("_OffsetMode",float) = 0
        [GroupEnum(Base,_SHARPEN _BLUR _DETECTION _CUSTOM,true,Kernel functions)]_KernelMode("_KernelMode",float) = 0

        [Group(Kernel)]
        [GroupHeader(Kernel,KernelMatrix)]
        [GroupItem(Kernel)]_Item123("_Item123",vector) = (0,0,0,-1)
        [GroupItem(Kernel,2x2 mode only use 4 5)]_Item456("_Item456",vector) = (0,0,0,1)
        [GroupItem(Kernel)]_Item789("_Item789",vector) = (0,0,0,1)

        [GroupToggle(Kernel,,_DETECTION mode keep edge color)] _KeepEdgeColor("_KeepEdgeColor",float) = 1

        [GroupItem(Kernel,lerp kernelColor to screenColor)] _BlendOpaqueTex("_BlendOpaqueTex",range(0,1)) = 0
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
        [GroupStencil(Stencil)] _Stencil ("Stencil ID", int) = 0
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

            #pragma multi_compile _OFFSETS_3X3 _OFFSETS_2X2
            #pragma multi_compile _SHARPEN _BLUR _DETECTION _CUSTOM

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
            #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
            #include "../../../PowerShaderLib/URPLib/URP_Input.hlsl"
            #include "../../../PowerShaderLib/Lib/Kernel/KernelDefines.hlsl"
            #include "../../../PowerShaderLib/Lib/SampleStates.hlsl"
            #include "../../../PowerShaderLib/Lib/ScreenTextures.hlsl"

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
            float4 _CameraOpaqueTexture_TexelSize;

            CBUFFER_START(UnityPerMaterial)
            half _FullScreenOn;
            half4 _MainTex_ST;
            half4 _KernelColor;
            half _TexelSizeScale;

            half3 _Item123;
            half3 _Item456;
            half3 _Item789;

            half _BlendOpaqueTex;
            half _KeepEdgeColor;
            CBUFFER_END

// #define _CameraDepthTexture _CameraDepthAttachment
// #define _CameraOpaqueTexture _CameraColorTexture

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = _FullScreenOn ? float4(v.vertex.xy * 2,UNITY_NEAR_CLIP_VALUE,1) : TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

// ====== variables
DEF_OFFSETS_3X3(offsets_3x3,_CameraOpaqueTexture_TexelSize.xy);
DEF_OFFSETS_2X2(offsets_2x2,_CameraOpaqueTexture_TexelSize.xy);
DEF_OFFSETS_2X2_CROSS(offsets_2x2_cross,_CameraOpaqueTexture_TexelSize.xy);

/**
    Calc kernels
*/

void CalcKernel_3x3(out float kernels[9]){
    float arr[9] = {_Item123,_Item456,_Item789};
    kernels = arr;
}
void CalcKernel_2x2(out float kernels[5]){
    float arr[5] = {_Item123,_Item456.xy};
    kernels = arr;
}

#define CALC_KERNEL_3X3(varName)\
float varName[9];\
CalcKernel_3x3(varName)

#define CALC_KERNEL_2X2(varName)\
float varName[5];\
CalcKernel_2x2(varName)

// #define _CameraOpaqueTexture _CameraDepthTexture
            float4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;
                // screenUV += N21(screenUV)*0.01;

//============ world pos
                float depth = GetScreenDepth(screenUV);
                half isFar = IsTooFar(depth);
                
                float3 worldPos = ScreenToWorldPos(screenUV,depth,UNITY_MATRIX_I_VP);

                // blend screen
                half4 opaqueTex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture,SAMPLE_STATE,screenUV);
                float blendRate = _BlendOpaqueTex;

                float4 col = 0;
                #if defined(_SHARPEN)
                    #if defined(_OFFSETS_3X3)
                    col = CalcKernelTexture_3x3(_CameraOpaqueTexture,SAMPLE_STATE,screenUV,_TexelSizeScale,offsets_3x3,kernels_sharpen);
                    #else
                    col = CalcKernelTexture_2x2(_CameraOpaqueTexture,SAMPLE_STATE,screenUV,_TexelSizeScale,offsets_2x2_cross,kernels_sharpen_2x2);
                    #endif
                #elif defined(_BLUR)
                    #if defined(_OFFSETS_3X3)
                    col = CalcKernelTexture_3x3(_CameraOpaqueTexture,SAMPLE_STATE,screenUV,_TexelSizeScale,offsets_3x3,kernels_blur);
                    #else
                    col = CalcKernelTexture_2x2(_CameraOpaqueTexture,SAMPLE_STATE,screenUV,_TexelSizeScale,offsets_2x2_cross,kernels_blur_2x2);
                    #endif
                #elif defined(_DETECTION)
                    #if defined(_OFFSETS_3X3)
                    col = CalcKernelTexture_3x3(_CameraOpaqueTexture,SAMPLE_STATE, screenUV,_TexelSizeScale,offsets_3x3,kernels_edgeDetection_noCenter);
                    #else
                    col = CalcKernelTexture_2x2(_CameraOpaqueTexture,SAMPLE_STATE,screenUV,_TexelSizeScale,offsets_2x2_cross,kernels_edgeDetection_2x2_noCenter);
                    #endif
                    // show opaque with edgeKernelColor
                    
                #else // custom calc kernel
                    #if defined(_OFFSETS_3X3)
                    CALC_KERNEL_3X3(kernel_3x3);
                    col = CalcKernelTexture_3x3(_CameraOpaqueTexture,SAMPLE_STATE,screenUV,_TexelSizeScale,offsets_3x3,kernel_3x3);
                    #else
                    CALC_KERNEL_2X2(kernel_2x2);
                    col = CalcKernelTexture_2x2(_CameraOpaqueTexture,SAMPLE_STATE,screenUV,_TexelSizeScale,offsets_2x2_cross,kernel_2x2);
                    #endif
                #endif

                col = saturate(col * _KernelColor);
                // only keep edge detection color
                #if defined(_DETECTION)
                col = _KeepEdgeColor ? max(col,opaqueTex) : col;
                #endif

                col = lerp(col,opaqueTex, _BlendOpaqueTex);

                return col;
            }
            ENDHLSL
        }
    }
}
