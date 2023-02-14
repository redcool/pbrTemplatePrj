#if !defined(SHADER_FLOW_PASS_HLSL)
#define SHADER_FLOW_PASS_HLSL

#if defined(VERSION_1)
    #include "ShaderFlowPassVersion1.hlsl"
#else
    #include "ShaderFlowPassVersion2.hlsl"
#endif

#endif //SHADER_FLOW_PASS_HLSL