Shader "Unlit/Bill"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcMode("_SrcMode",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstMode("_DstMode",int) = 0
    }
    SubShader
    {
        Tags {  }
        LOD 100
        blend [_SrcMode][_DstMode] 

        Pass
        {
            Tags{"Queue"="Transparent"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            v2f vert (appdata v)
            {
                v2f o;
                
                // o.vertex = UnityObjectToClipPos(v.vertex);

                float sx = unity_ObjectToWorld._11;
                float sy = unity_ObjectToWorld._22;
                o.vertex = mul(UNITY_MATRIX_P,
                    mul(UNITY_MATRIX_MV,float4(0,0,0,1)) + float4(v.vertex.x * sx,v.vertex.y * sy,0,0)
                );
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * float4(0,1,0,1);
                // clip(col.a-0.5);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
