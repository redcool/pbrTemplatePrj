Shader "Template/Unlit/InstancedLightmap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("_Color",color) = (1,1,1,1)

        [Header(Alpha)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcMode("_SrcMode",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstMode("_DstMode",int) = 0        
        [GroupToggle(,_ALPHA_TEST_ON)]_ClipOn("_ClipOn",int) = 0
        _Cutoff("_Cutoff",range(0,1)) = 0.5
    }

    HLSLINCLUDE
    #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
    #include "../../../PowerShaderLib/UrpLib/URP_GI.hlsl"
    ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            blend[_SrcMode][_DstMode]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma shader_feature _ALPHA_TEST_ON

            // nothing
            // #if defined(INSTANCING_ON)
                // #define UnityPerMaterial _UnityPerMaterial
            // #endif

            // define variables
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4,_MainTex_ST)
                UNITY_DEFINE_INSTANCED_PROP(float,_Cutoff)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            // define shortcot getters
            #define _MainTex_ST UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_MainTex_ST)
            #define _Cutoff UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Cutoff)

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1:TEXCOORD1;
                float3 n:NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
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

                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
                o.n = TransformObjectToWorldNormal(v.n);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                float2 mainUV = i.uv.xy;
                float2 lightmapUV = i.uv.zw;

                float3 sh = SampleSH(i.n);
                // sample the texture
                float4 mainTex = tex2D(_MainTex, mainUV);
                float3 albedo = mainTex.xyz;
                float alpha = mainTex.w;
                #if defined(_ALPHA_TEST_ON)
                    clip(alpha - _Cutoff);
                #endif

                half3 giDiff = CalcGIDiff(i.n,albedo,lightmapUV);
                half3 diffColor = albedo + giDiff;

                return float4(diffColor,1);
            }
            ENDHLSL
        }
    }
}
