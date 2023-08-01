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

            #if !defined(INSTANCING_ON)
                #define UnityPerMaterial UnityPerMaterial
            #endif

            // define variables
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4,_MainTex_ST)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            // define shortcot getters
            #define _MainTex_ST UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_MainTex_ST)

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
                // sample the texture
                float4 mainTex = tex2D(_MainTex, i.uv);
                float3 albedo = mainTex.xyz;
                float alpha = mainTex.w;
                float3 diffColor = albedo * sh;
                
                return float4(diffColor,alpha);
            }
            ENDHLSL
        }
    }
}
