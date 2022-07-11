#if !defined(PBR_INPUT_HLSL)
#define PBR_INPUT_HLSL
sampler2D _MainTex;
// samplerCUBE unity_SpecCube0;
sampler2D _NormalMap;
sampler2D _PBRMask;
sampler2D _CameraOpaqueTexture;
sampler2D _CameraDepthTexture;

CBUFFER_START(UnityPerMaterial)
half _Smoothness;
half _Metallic;
half _Occlusion;

half _NormalScale;
half _Depth;

CBUFFER_END
#endif //PBR_INPUT_HLSL