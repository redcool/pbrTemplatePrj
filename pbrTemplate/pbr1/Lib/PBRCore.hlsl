#if !defined(PBR_CORE_HLSL)
#define PBR_CORE_HLSL

#include "Lib/Core/CommonUtils.hlsl"
#include "Core/URPLib/URP_MainLightShadows.hlsl"
#include "Core/URPLib/URP_Lighting.hlsl"

half3 CalcAdditionalLight(Light light,half3 viewDir,half3 normal,half3 diffColor,half3 specColor,half a,half a2){
    half3 h = SafeNormalize(light.direction + viewDir);
    half nh = saturate(dot(normal,h));
    half nl = saturate(dot(normal,light.direction));
    half lh = saturate(dot(light.direction,h));
    half lightAtten = light.distanceAttenuation * light.shadowAttenuation;
    half specTerm = MinimalistCookTorrance(nh,lh,a,a2);
    half3 color = (lightAtten * nl) * light.color * (diffColor + specColor * specTerm);
    return color;
}

 half3 CalcAdditionalLights(half3 worldPos,half3 viewDir,half3 worldNormal,half3 diffColor,half3 specColor,half a,half a2){
     half3 color = 0;
     uint lightCount = GetAdditionalLightsCount();
     for(int i=0;i<lightCount;i++){
        Light light1 = GetAdditionalLight(i,worldPos,_ReceiveAdditionalLightShadow,_AdditionalIghtSoftShadow);
        color += CalcAdditionalLight(light1,viewDir,worldNormal,diffColor,specColor,a,a2);
     }
     return color;
 }
#endif //PBR_CORE_HLSL