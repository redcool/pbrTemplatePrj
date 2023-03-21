#if !defined(SHADOW_CASTER_PASS_HLSL)
#define SHADOW_CASTER_PASS_HLSL

#include "PBRInput.hlsl"
#include "../../../../PowerShaderLib/URPLib/URP_MainLightShadows.hlsl"

struct appdata
{
    half4 vertex : POSITION;
    half2 uv : TEXCOORD0;
    half3 normal:NORMAL;
    half4 tangent:TANGENT;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
struct v2f{
    half2 uv:TEXCOORD0;
    half4 pos:SV_POSITION;
};

half3 _LightDirection;

//--------- shadow helpers
half4 GetShadowPositionHClip(appdata input){
    half3 worldPos = mul(unity_ObjectToWorld,input.vertex).xyz;
    half3 worldNormal = UnityObjectToWorldNormal(input.normal);
    half4 positionCS = UnityWorldToClipPos(ApplyShadowBias(worldPos,worldNormal,_LightDirection,_CustomShadowNormalBias,_CustomShadowDepthBias));
    #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    return positionCS;
}

v2f vert(appdata input){
    v2f output;

    #if defined(SHADOW_PASS)
        output.pos = GetShadowPositionHClip(input);
    #else 
        output.pos = UnityObjectToClipPos(input.vertex);
    #endif
    output.uv = TRANSFORM_TEX(input.uv,_MainTex);
    return output;
}

half4 frag(v2f input):SV_Target{
    #if defined(_ALPHA_TEST)
    if(_AlphaTestOn){
        half4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
        clip(tex.a - _Cutoff);
    }
    #endif
    return 0;
}

#endif //SHADOW_CASTER_PASS_HLSL