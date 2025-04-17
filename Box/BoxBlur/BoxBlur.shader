Shader "FX/Box/Blur/BoxBlur"
{
    Properties
    {
        [GroupHeader(v0.0.1)]
        [Group(Base)]
        [GroupToggle(Base)]_FullScreenOn("_FullScreenOn",int) = 1
        [GroupVectorSlider(Base,minX minY maxX maxY,0_1 0_1 0_1 0_1,limit screen range,float)]_ScreenRange("ScreenRange",vector) = (0,0,1,1)
        [GroupItem(Base)] _MainTex("_MainTex",2d)=""{}
        [GroupToggle(Base,_CAMERA_OPAQUE_TEXTURE_ON,mainTexture use _CameraOpaqueTexture)]_CameraOpaqueTextureOn("_CameraOpaqueTextureOn",float) = 0
// ================================================== blur
        [Group(Blur)]
        [GroupToggle(Blur,_BLUR,use blur)]_BlurOn("_BlurOn",float) = 0
        [GroupItem(Blur)] _BlurSize("_BlurSize",range(0,1)) = 1
        [GroupItem(Blur)] _StepCount("_StepCount",range(1,10)) = 4

// ================================================== chromatic aberration
        [Group(ChromaticAberration)]
        [GroupToggle(ChromaticAberration,_CHROMATIC_ABERRATION,multi samples show chromatic aberration)]_ChromaticAberrationOn("_ChromaticAberrationOn",float) = 0
        
        [GroupItem(ChromaticAberration)] _ChromaticIntensity("_ChromaticIntensity",range(0,1)) = 0
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
            #pragma shader_feature _CAMERA_OPAQUE_TEXTURE_ON
            #pragma shader_feature _CHROMATIC_ABERRATION
            #pragma shader_feature _BLUR

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
            #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
            #include "../../../PowerShaderLib/Lib/FullscreenLib.hlsl"
            #include "../../../PowerShaderLib/URPLib/URP_Input.hlsl"
            #include "../../../PowerShaderLib/Lib/BlurLib.hlsl"
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

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);

            CBUFFER_START(UnityPerMaterial)
            half _FullScreenOn;
            half4 _MainTex_ST;
            half4 _ScreenRange;            
            float4 _MainTex_TexelSize;
            half _BlurSize;
            half _StepCount;

            half _ChromaticIntensity;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToNdcHClip(v.vertex,_FullScreenOn,_ScreenRange);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 SampleTextureApplyBoxBlur(TEXTURE2D_PARAM(tex,samperTex),float2 uv,float4 texelSize){
                float rate = texelSize.z/texelSize.w;
                // uv += texelSize.xy * 0.5;
                float4 c = 0;
                c += BoxBlur(tex,samperTex,uv,texelSize.xy * _BlurSize* float2(1,0),_StepCount);
                c += BoxBlur(tex,samperTex,uv,texelSize.xy * _BlurSize* float2(0,rate),_StepCount);
                return c * 0.5;
            }

            half4 frag (v2f i) : SV_Target
            {
                float4 c = float4(0,0,0,1);
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;
                float2 mainUV = _FullScreenOn?screenUV:i.uv;

                #if defined(_CAMERA_OPAQUE_TEXTURE_ON)
                TEXTURE2D(tex) = _CameraOpaqueTexture;
                SAMPLER(texSampler) = sampler_CameraOpaqueTexture;
                #else
                TEXTURE2D(tex) = _MainTex;
                SAMPLER(texSampler) = sampler_MainTex;
                #endif

                #if defined(_BLUR)
                c = SampleTextureApplyBoxBlur(tex,texSampler,mainUV,_MainTex_TexelSize);
                #endif //BLUR
                
                #if defined(_CHROMATIC_ABERRATION)
                float2 uvDir = mainUV - 0.5;
                float dist2 = dot(uvDir,uvDir);
                // return dist2;
                float2 uvOffset = uvDir * dist2 * _ChromaticIntensity;
                c.x = SAMPLE_TEXTURE2D(tex,texSampler,mainUV).x;
                c.y = SAMPLE_TEXTURE2D(tex,texSampler,mainUV + uvOffset).y;
                c.z = SAMPLE_TEXTURE2D(tex,texSampler,mainUV + uvOffset * 2).z;

                #endif // _CHROMATIC_ABERRATION
                

                return c;
            }
            ENDHLSL
        }
    }
}
