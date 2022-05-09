#if !defined(PBR_INPUT_HLSL)
#define PBR_INPUT_HLSL
#include "Lib/Core/Common.hlsl"


sampler2D _MainTex;
sampler2D _NormalMap;
sampler2D _PbrMask;

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

half _CalcAdditionalLights,_ReceiveAdditionalLightShadow,_AdditionalIghtSoftShadow;

//thin film
half _TFOn,_TFScale,_TFOffset,_TFSaturate,_TFBrightness;
half _ReceiveShadow;

CBUFFER_END

half CustomShadowDepthBias(){
    return lerp(-1,1,_CustomShadowDepthBias);
}
half CustomShadowNormalBias(){
    return lerp(-1,1,_CustomShadowNormalBias);
}
#endif //PBR_INPUT_HLSL