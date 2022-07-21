#if !defined(UIFX_CORE_HLSL)
#define UIFX_CORE_HLSL

float SDFRect(float2 uv,float2 range){
    float a = smoothstep(range.x,range.y,uv.x);
    a += smoothstep(range.x,range.y,uv.y);
    a += smoothstep(range.x,range.y,1-uv.x);
    a += smoothstep(range.x,range.y,1-uv.y);
    return a;
}

#endif //UIFX_CORE_HLSL