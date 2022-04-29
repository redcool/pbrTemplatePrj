#if !defined(COMMON_UTILS_HLSL)
#define COMMON_UTILS_HLSL

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

/***
// Z buffer depth to linear 0-1 depth

_ZBufferParams
x is (1-far/near), 
y is (far/near), 
z is (x/far) 
w is (y/far).
**/
half LinearizeDepth(half z){
//ortho : 1 - (z - zf/n) + f/n
//pers : 1/(z-zf/n+f/n)
    half ortho = unity_OrthoParams.w;
    half pers = 1 - unity_OrthoParams.w;
    z *= _ZBufferParams.x;
    return (1 - ortho * z) / (pers * z + _ZBufferParams.y);
}

/**
    screenUV : [0,1]
    depth : [n,f]
    inverse projection matrix
    inverse view matrix
*/
half3 ScreenToWorldPos(half2 screenUV,half depth,half4x4 invProj,half4x4 invV){
    half4 p = half4(screenUV*2-1,depth,1);
    p = mul(invProj,p);
    p.xyz /= p.w;
    p = mul(invV,p);
    return p.xyz;
}

half3 ScreenToWorldPos(half2 screenUV,half depth){
    return ScreenToWorldPos(screenUV,depth,unity_MatrixInvP,unity_MatrixInvV);
}

#endif //COMMON_UTILS_HLSL