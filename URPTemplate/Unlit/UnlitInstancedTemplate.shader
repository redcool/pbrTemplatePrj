Shader "Template/UnlitInstanced"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    HLSLINCLUDE
    #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
    // urp's flow
// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
    ENDHLSL
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing



            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 n:NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 n:TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            
            #define CNAME UnityPerMaterial1
            #if !defined(INSTANCING_ON)
                // #define CNAME UnityPerMaterial
            #endif

            UNITY_INSTANCING_BUFFER_START(CNAME)
                UNITY_DEFINE_INSTANCED_PROP(float4,_MainTex_ST)
            UNITY_INSTANCING_BUFFER_END(CNAME)

            #if defined(INSTANCING_ON)
                #define _MainTex_ST UNITY_ACCESS_INSTANCED_PROP(CNAME,_MainTex_ST)
            #endif

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.n = TransformObjectToWorldNormal(v.n);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                float3 sh = SampleSH(i.n);
                return sh.xyzx;
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDHLSL
        }
    }
}
