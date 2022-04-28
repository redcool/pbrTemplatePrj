#if !defined(URP_GI_HLSL)
#define URP_GI_HLSL
//-----------------------------------------------------------EntityLight
#define LIGHTMAP_RGBM_MAX_GAMMA     half(5.0)       // NB: Must match value in RGBMRanges.h
#define LIGHTMAP_RGBM_MAX_LINEAR    half(34.493242) // LIGHTMAP_RGBM_MAX_GAMMA ^ 2.2

#ifdef UNITY_LIGHTMAP_RGBM_ENCODING
    #ifdef UNITY_COLORSPACE_GAMMA
        #define LIGHTMAP_HDR_MULTIPLIER LIGHTMAP_RGBM_MAX_GAMMA
        #define LIGHTMAP_HDR_EXPONENT   half(1.0)   // Not used in gamma color space
    #else
        #define LIGHTMAP_HDR_MULTIPLIER LIGHTMAP_RGBM_MAX_LINEAR
        #define LIGHTMAP_HDR_EXPONENT   half(2.2)
    #endif
#elif defined(UNITY_LIGHTMAP_DLDR_ENCODING)
    #ifdef UNITY_COLORSPACE_GAMMA
        #define LIGHTMAP_HDR_MULTIPLIER half(2.0)
    #else
        #define LIGHTMAP_HDR_MULTIPLIER half(4.59) // 2.0 ^ 2.2
    #endif
    #define LIGHTMAP_HDR_EXPONENT half(0.0)
#else // (UNITY_LIGHTMAP_FULL_HDR)
    #define LIGHTMAP_HDR_MULTIPLIER half(1.0)
    #define LIGHTMAP_HDR_EXPONENT half(1.0)
#endif

 half3 UnpackLightmapRGBM(half4 rgbmInput, half4 decodeInstructions)
{
#ifdef UNITY_COLORSPACE_GAMMA
    return rgbmInput.rgb * (rgbmInput.a * decodeInstructions.x);
#else
    // return rgbmInput.rgb * (pow(rgbmInput.a, decodeInstructions.y) * decodeInstructions.x);
    // optimise 
    half scale = rgbmInput.w;
    #if defined(UNITY_LIGHTMAP_RGBM_ENCODING)
        scale = scale * scale;
    #endif

    return rgbmInput.rgb * ( scale * decodeInstructions.x);
#endif
}

half3 UnpackLightmapDoubleLDR(half4 encodedColor, half4 decodeInstructions)
{
    return encodedColor.rgb * decodeInstructions.x;
}

#ifndef BUILTIN_TARGET_API
half3 DecodeLightmap(half4 encodedIlluminance, half4 decodeInstructions)
{
#if defined(UNITY_LIGHTMAP_RGBM_ENCODING)
    return UnpackLightmapRGBM(encodedIlluminance, decodeInstructions);
#elif defined(UNITY_LIGHTMAP_DLDR_ENCODING)
    return UnpackLightmapDoubleLDR(encodedIlluminance, decodeInstructions);
#else // (UNITY_LIGHTMAP_FULL_HDR)
    return encodedIlluminance.rgb;
#endif
}
#endif

half3 SampleLightmap(half2 uv){
    #ifdef UNITY_LIGHTMAP_FULL_HDR
    bool encodedLightmap = false;
#else
    bool encodedLightmap = true;
#endif

    half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);
    half4 illum = SAMPLE_TEXTURE2D(unity_Lightmap,samplerunity_Lightmap,uv);
    return DecodeLightmap(illum,decodeInstructions);
}

half4 SampleShadowMask(half2 uv){
    return SAMPLE_TEXTURE2D(unity_ShadowMask,samplerunity_ShadowMask,uv);
}
#endif //URP_GI_HLSL