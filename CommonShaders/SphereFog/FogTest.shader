Shader "Unlit/FogTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Toggle]_HasHeightFog("_HasHeightFog",float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "FogLib.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 fogCoord:TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 worldPos:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            bool _HasHeightFog;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.fogCoord = CalcFogFactor(worldPos,_HasHeightFog);
                o.worldPos = worldPos;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 v = UnityWorldSpaceViewDir(i.worldPos);
                // sample the texture
                i.fogCoord = CalcFogFactor(i.worldPos,_HasHeightFog);
                fixed4 col = tex2D(_MainTex, i.uv);
                BlendFogSphere(i.fogCoord,_HasHeightFog,col.xyz/**/);
                return col;
            }
            ENDCG
        }
    }
}
