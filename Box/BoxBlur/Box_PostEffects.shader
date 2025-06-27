/**
    Blur
    ChromationAberration
    Vignette
*/
Shader "FX/Box/Blur/Box_PostEffects"
{
    Properties
    {
        [GroupHeader(v0.0.1)]
        [Group(Base)]
        [GroupToggle(Base)]_FullScreenOn("_FullScreenOn",int) = 1
        [GroupVectorSlider(Base,minX minY maxX maxY,0_1 0_1 0_1 0_1,limit screen range,float)]_ScreenRange("ScreenRange",vector) = (0,0,1,1)

        [Group(Noise)]
        [GroupToggle(Noise,_NOISE_ON)] _NoiseOn("_NoiseOn",float)= 0
        [GroupItem(Noise)] _WeatherNoiseTexture("_WeatherNoiseTexture",2d)=""{}
        [GroupItem(Noise)] _NoiseUVTexelSize("_NoiseUVTexelSize",float)= 100
        [GroupVectorSlider(Noise,dirU dirV,m1_1 m1_1)] _NoiseDir("_NoiseDir",vector)= (1,1,0,0)
        [GroupItem(Noise)] _NoiseSpeed("_NoiseSpeed",float)= 1
        [GroupItem(Noise)] _NoiseScale("_NoiseScale",range(0,1))= 1
        
// ================================================== blur
        [Group(Blur)]
        [GroupToggle(Blur,_BLUR,use blur)]_BlurOn("_BlurOn",float) = 0
        [GroupItem(Blur)] _BlurSize("_BlurSize",range(0,3)) = 1
        [GroupItem(Blur)] _StepCount("_StepCount",range(1,10)) = 4

// ================================================== chromatic aberration
        [Group(ChromaticAberration)]
        [GroupToggle(ChromaticAberration,_CHROMATIC_ABERRATION,multi samples show chromatic aberration)]_ChromaticAberrationOn("_ChromaticAberrationOn",float) = 0
        [GroupVectorSlider(ChromaticAberration,centerX centerY,0_1 0_1)] _ChromaticCenter("_ChromaticCenter",vector) = (0.5,0.5,0,0)
        [GroupItem(ChromaticAberration)] _ChromaticScale("_ChromaticScale",range(-.2,.2)) = 0

// ================================================== vignette
        [Group(Vignette)]
        [GroupToggle(Vignette,_VIGNETTE,use vignette)]_VignetteOn("_VignetteOn",float) = 0
        [GroupToggle(Vignette)]_RoundOn("_RoundOn",float) = 0
        [GroupItem(Vignette)]_Intensity("_Intensity",range(0,1)) = 1
        [GroupVectorSlider(Vignette,centerX centerY,0_1 0_1,position)] _Center("_Center",vector) = (0.5,0.5,0,0)
        [GroupVectorSlider(Vignette,min max,0_1 0_1,vignet range smooth )] _VignetRange("_VignetRange",vector) = (0,1,0,0)        
        [GroupVectorSlider(Vignette,min max,0_1 0_1,blick eyes)] _Oval("_Oval",vector) = (1,1,0,0)

        [GroupItem(Vignette)] _Color1("_Color1",color) = (1,1,1,1)
        [GroupItem(Vignette)] _Color2("_Color2",color) = (1,1,1,1)
// ================================================== Lens distortion
        [Group(LensDistortion)]
        [GroupToggle(LensDistortion,_LENS_DISTORTION)]_LensDistOn("_LensDistOn",float) = 0
        [GroupItem(LensDistortion)]_LensDistIntensity("_LensDistIntensity",float) = 0
        [GroupItem(LensDistortion)]_LensDistAmplitude("_LensDistAmplitude",float) = 0.02
        [GroupVectorSlider(LensDistortion,centerX centerY,0_1 0_1)] _LensDistCenter("_LensDistCenter",vector) = (0.5,0.5,0,0)
        [GroupItem(LensDistortion)]_LensDistScale("_LensDistScale",float) = 0
        // [GroupItem(LensDistortion)]_LensDistMoveSpeed("_LensDistMoveSpeed",float) = 0
        
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
            #pragma shader_feature _CHROMATIC_ABERRATION
            #pragma shader_feature _BLUR
            #pragma shader_feature _VIGNETTE
            #pragma shader_feature _NOISE_ON
            #pragma shader_feature _LENS_DISTORTION
            

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
            #include "../../../PowerShaderLib/Lib/SDF.hlsl"
            #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
            #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
            #include "../../../PowerShaderLib/Lib/FullscreenLib.hlsl"
            #include "../../../PowerShaderLib/URPLib/URP_Input.hlsl"
            #include "../../../PowerShaderLib/Lib/BlurLib.hlsl"
            #include "../../../PowerShaderLib/Lib/WeatherNoiseTexture.hlsl"
            #include "../../../PowerShaderLib/Lib/Colors.hlsl"

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

            // TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);

            CBUFFER_START(UnityPerMaterial)
            half _FullScreenOn;
            half4 _WeatherNoiseTexture_ST;
            half4 _ScreenRange;            
            float4 _MainTex_TexelSize;
            half _BlurSize;
            half _StepCount;

            half _ChromaticScale;
            half2 _ChromaticCenter;
            // vignette
            half4 _Color1,_Color2;
            half2 _VignetRange;
            float2 _Center;
            half2 _Oval;
            half _RoundOn;
            half _Intensity;
            // noise
            half _NoiseUVTexelSize;
            half _NoiseSpeed;
            half _NoiseScale;
            half2 _NoiseDir;
            // lens distortion
            half _LensDistIntensity;
            half _LensDistAmplitude;
            half2 _LensDistCenter;
            half _LensDistScale;
            // half _LensDistMoveSpeed;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToNdcHClip(v.vertex,_FullScreenOn,_ScreenRange);
                o.uv = v.uv;
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
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;
                
                float noise = 0;
                #if defined(_NOISE_ON)
                float2 noiseUV = screenUV * _NoiseUVTexelSize + _NoiseDir * _Time.x*_NoiseSpeed;
                noise = SampleWeatherNoise(noiseUV ) * _NoiseScale;
// return noise;
                #endif

                screenUV += noise * 0.2;
                // apply fish eye offset
                #if defined(_LENS_DISTORTION)
                ApplyLensDistorionUVOffset(screenUV/**/,_ScaledScreenParams,_LensDistIntensity,_LensDistAmplitude,_LensDistCenter,_LensDistScale);
                #endif

                TEXTURE2D(tex) = _CameraOpaqueTexture;
                SAMPLER(texSampler) = sampler_CameraOpaqueTexture;
                float4 c = SAMPLE_TEXTURE2D(tex,texSampler,screenUV);
                
                #if defined(_BLUR)
                c = SampleTextureApplyBoxBlur(tex,texSampler,screenUV,_MainTex_TexelSize);
                #endif //BLUR

                #if defined(_CHROMATIC_ABERRATION)
                float2 uvDir = screenUV - _ChromaticCenter;
                float dist2 = dot(uvDir,uvDir);
                // return dist2;
                float2 uvOffset = uvDir * dist2 * _ChromaticScale;
                half3 chromaCol=0;
                chromaCol.x = SAMPLE_TEXTURE2D(tex,texSampler,screenUV).x;
                chromaCol.y = SAMPLE_TEXTURE2D(tex,texSampler,screenUV + uvOffset).y;
                chromaCol.z = SAMPLE_TEXTURE2D(tex,texSampler,screenUV + uvOffset * 2).z;
                c.xyz = lerp(c.xyz,chromaCol,0.3);
                #endif // _CHROMATIC_ABERRATION


                #if defined(_VIGNETTE)
                half4 vignetteColor = CalcVignette(screenUV,_Center,_RoundOn,_Oval,_VignetRange,_Color1,_Color2,_Intensity);
                c = lerp(c,vignetteColor,vignetteColor.a);
                #endif  //VIGNETTE

                return c;
            }
            ENDHLSL
        }
    }
}
