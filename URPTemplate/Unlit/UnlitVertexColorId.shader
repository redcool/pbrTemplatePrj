Shader "Template/Unlit/VertexColorId"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Speed_Amp("_Speed_Amp",vector) = (-10,1,0,0) // speed,amplitude
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
            #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 color:COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 color:COLOR;
            };

            sampler2D _MainTex;
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _Speed_Amp;
            CBUFFER_END

            v2f vert (appdata v)
            {
                float colorId = v.color.x+0.01;
                float n21 = GradientNoise(colorId.xx * _Time.yy * _Speed_Amp.x);
                v.vertex.xyz += n21 *_Speed_Amp.y;

                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.color = v.color;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 col = tex2D(_MainTex, i.uv);

                col.xyz *= i.color;
                return col;
            }
            ENDHLSL
        }
    }
}
