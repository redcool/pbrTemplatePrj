#if !defined(NOISE_LIB_HLSL)
#define NOISE_LIB_HLSL

half N21(half2 uv){
    return frac(sin(dot(uv,12.9898,78.233)) * 43758.5453123);
}

half 

#endif //NOISE_LIB_HLSL