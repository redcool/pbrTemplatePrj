Shader "Template/Unlit/Plane"
{
    Properties
    {
        _MainTex ("Texture(RGB:Color,A:Depth)", 2D) = "white" {}
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
            #include "../../../PowerShaderLib/URPLib/URP_Input.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // #if defined(UNITY_UV_STARTS_AT_TOP)
                    o.uv.y = 1-o.uv.y;
                // #endif
                return o;
            }

            float4 frag (v2f i,out float depth:SV_DEPTH) : SV_Target
            {
                // float2 screenUV = i.vertex.xy * _ScaledScreenParams.zw;
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv);
                depth = col.w;
                return float4(col.xyz,1);
            }
            ENDHLSL
        }
    }
}
