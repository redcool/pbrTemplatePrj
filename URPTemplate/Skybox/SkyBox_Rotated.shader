Shader "Template/Unlit/SkyBox_Rotated"
{
    Properties
    {
        _Cube ("Texture", cube) = "white" {}
        _Angle("_Angle",range(0,360)) = 0
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


            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 viewDir:TEXCOORD2;
            };

            samplerCUBE _Cube;
            float _Angle;

            v2f vert (appdata v)
            {
                v2f o;
                float3 rotatedVertex = v.vertex;
                RotateUV(_Angle,0,rotatedVertex.xz);

                o.vertex = TransformObjectToHClip(rotatedVertex);
                o.viewDir = v.vertex.xyz;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = texCUBE(_Cube, i.viewDir);
                return col;
            }
            ENDHLSL
        }
    }
}
