Shader "Template/Unlit/DepthOnly"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass{
            Name "DepthOnly"
            Tags{"LightMode"="DepthOnly"}
            zwrite on
            colorMask 0
            cull[_CullMode]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            // #pragma shader_feature_local_vertex _WIND_ON

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"

            // #define SHADOW_PASS 
        //     #define USE_SAMPLER2D
            #define _MainTexChannel 3
            #define _CustomShadowNormalBias 0
            #define _CustomShadowDepthBias 0
            // #define USE_BASEMAP

            #include "../../../PowerShaderLib/URPLib/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
}
