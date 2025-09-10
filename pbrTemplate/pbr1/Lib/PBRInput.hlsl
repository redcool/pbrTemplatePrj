#if !defined(PBR_INPUT_HLSL)
#define PBR_INPUT_HLSL
#include "../../../../PowerShaderLib/Lib/UnityLib.hlsl"
#define _MainTex _BaseMap
#define _MainTex_ST _BaseMap_ST
#define _PbrMask _MetallicMaskMap

sampler2D _MainTex;
sampler2D _NormalMap;
sampler2D _PbrMask;
sampler2D _EmissionMap;


CBUFFER_START(UnityPerMaterial)
half4 _Color;
half4 _MainTex_ST;
half _Metallic,_Smoothness,_Occlusion;

half _NormalScale;

half _SpecularOn;
half _AnisoRough;
half _AnisoShift;

int _PbrMode;
half _CalcTangent;

// custom shadow 
half _MainLightShadowSoftScale;
half _CustomShadowDepthBias,_CustomShadowNormalBias;

// half _CalcAdditionalLights,_ReceiveAdditionalLightShadow,_AdditionalIghtSoftShadow;

//thin film
half _TFOn,_TFScale,_TFOffset,_TFSaturate,_TFBrightness;

half _ReceiveShadowOff;

half _FogOn;
half _FogNoiseOn;
half _DepthFogOn;
half _HeightFogOn;

half _AlphaPremultiply;
half _Cutoff;

half4 _EmissionColor;

half _ParallaxOn,_ParallaxIterate,_ParallaxHeight,_ParallaxMapChannel;
            
//--- gpu animTex
half _StartFrame;
half _EndFrame;
half _AnimSampleRate;
half _Loop;
half _NextStartFrame;
half _NextEndFrame;
half _CrossLerp;
half _PlayTime;
half _OffsetPlayTime;
            
half4 _AnimTex_TexelSize;
half3 _ReflectionColor;
half2 _ReflectionSurfaceRange;
CBUFFER_END

#endif //PBR_INPUT_HLSL