Shader "Hidden/Template/Unlit"
{
    Properties
    {
        _MainTex ("Texture", cube) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal:TEXCOORD1;
                float3 viewDir:TEXCOORD2;
            };

            samplerCUBE _MainTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                float3 worldPos = TransformObjectToWorld(v.vertex);

                o.normal = TransformObjectToWorldNormal(v.normal);
                o.viewDir = _WorldSpaceCameraPos.xyz - worldPos;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 reflectDir = reflect(-i.viewDir,normalize(i.normal));
                // sample the texture
                float4 col = texCUBE(_MainTex, reflectDir);
                return col;
            }
            ENDHLSL
        }
    }
}
