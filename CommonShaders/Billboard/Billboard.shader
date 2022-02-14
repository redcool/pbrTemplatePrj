Shader "Unlit/Bill"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("_Color",color) = (1,1,1,1)
        [Toggle]_FullFaceCamera("_FullFaceCamera",int) = 0

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
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _Color;
            int _FullFaceCamera;
            CBUFFER_END


            float4 BillboardVertex(float3 vertex,bool fullFaceCamera){
                float3x3 camRotMat = float3x3(
                    UNITY_MATRIX_V[0].xyz,
                    UNITY_MATRIX_V[1].xyz,
                    UNITY_MATRIX_V[2].xyz
                );

                float sx = unity_ObjectToWorld._11;
                float sy = unity_ObjectToWorld._22;

                float3 vertexOffset = float3(sx,sy,0) * vertex.xyz;
                float3 vertexRotate = mul(camRotMat,float3(0,vertex.y * sy,0));

                if(!fullFaceCamera){
                    vertexOffset.y = 0;
                    vertexOffset += vertexRotate;
                }

                return mul(UNITY_MATRIX_P,
                    mul(UNITY_MATRIX_MV,float4(0,0,0,1))
                     + float4(vertexOffset,1)
                );
            }


            v2f vert (appdata v)
            {
                v2f o;
                
                o.vertex = BillboardVertex(v.vertex ,_FullFaceCamera);


                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                // clip(col.a-0.5);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
