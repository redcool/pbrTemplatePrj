Shader "Template/Unlit/SkyBox_InteriorMap"
{
    Properties
    {
        _Cubemap ("Texture", cube) = "white" {}
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
            #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
            #include "../../../PowerShaderLib/Lib/TangentLib.hlsl"
            #include "../../../PowerShaderLib/Lib/ReflectionLib.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal:TEXCOORD1;
                
                float3 viewDirTS:TEXCOORD4;
            };

            samplerCUBE _Cubemap;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;

                float3 t = normalize(TransformObjectToWorldDir(v.tangent.xyz));
                float3 n = normalize(TransformObjectToWorldNormal(v.normal));
                float3 b = normalize(cross(n,t)) * v.tangent.w;
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
                o.viewDirTS = float3(
                    dot(t,viewDir),
                    dot(b,viewDir),
                    dot(n,viewDir)
                );
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 reflectDir = CalcInteriorMapReflectDir(i.viewDirTS,i.uv,float2(0,1),1);
                // sample the texture
                float4 col = texCUBE(_Cubemap, reflectDir);
                return col;
            }
            ENDHLSL
        }
    }
}
