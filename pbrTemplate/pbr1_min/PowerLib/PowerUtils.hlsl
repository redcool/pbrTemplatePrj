/**
    like UnityCG.cginc
*/

#if !defined(POWER_UTILS_HLSL)
#define POWER_UTILS_HLSL

// Linearize depth value sampled from the camera depth texture.
float LinearizeDepth(float z)
{
    float isOrtho = unity_OrthoParams.w;
    float isPers = 1 - unity_OrthoParams.w;
    z *= _ZBufferParams.x;
    return (1 - isOrtho * z) / (isPers * z + _ZBufferParams.y);
}

/**
screenUV -> ndc -> clip -> view
unity_MatrixInvVP
*/
half3 ScreenToWorldPos(half2 uv,half rawDepth,float4x4 invVP){
    // #if defined(UNITY_UV_STARTS_AT_TOP)
        uv.y = 1-uv.y;
    // #endif

    half4 p = half4(uv*2-1,rawDepth,1);

    p = mul(invVP,p);
    return p.xyz/p.w;
}


#define GetWorldSpaceViewDir(worldPos) (_WorldSpaceCameraPos - worldPos)
#define GetWorldSpaceLightDir(worldPos) _MainLightPosition.xyz

// #if defined(URP_LEGACY_HLSL)
// #define texCUBElod(cube,coord) cube.SampleLevel(sampler##cube,coord.xyz,coord.w)
// #endif //URP_LEGACY_HLSL

#endif //POWER_UTILS_HLSL