Shader "Examples/ShaderFunctionOverrideDemo"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define VERSION_1
            #include "Lib/ShaderFlowPass.hlsl"


            ENDCG
        }
    }
}
