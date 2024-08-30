Shader "Unlit/TestRaymarch"
{
    Properties
    {

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

#define MAX_STEPS 100
#define MAX_DIST 100
#define SURF_DIST 1e-3            

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                float3 ro:TEXCOORD1;
                float3 hitPos:TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // o.vertex = float4(v.vertex.xy * 2,0,1);
                o.uv = v.uv;

                o.ro = _WorldSpaceCameraPos;
                o.hitPos = mul(unity_ObjectToWorld,v.vertex);

                return o;
            }

            float GetDist(float3 p,float3 center = float3(0,0,2),float radius = 1){
                // float d = length(p) - 0.5; // sphere
                float d = distance(p,center) - radius; // sphere
                d = length(float2(length(p.xz) - .5,p.y)) - .1;
                return d;
            }
            float Raymarch(float3 ro,float3 rd){
                float d0 = 0;
                float ds;

                for(int i=0;i<MAX_STEPS;i++){
                    float3 p = ro + rd * d0;
                    ds = GetDist(p);
                    d0 += ds;
                    if(ds < SURF_DIST || d0 > MAX_DIST)
                        break;
                }
                return d0;
            }

            float3 GetNormal(float3 p){
                float2 e = float2(1e-2,0);
                float3 n = GetDist(p) - float3(
                    GetDist(p-e.xyy),
                    GetDist(p-e.yxy),
                    GetDist(p-e.yyx)
                );
                return normalize(n);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv -0.5;
                // float3 ro = float3(0,0,-3);
                // float3 rd = normalize(float3(uv,1));

                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos - ro);

                float d = Raymarch(ro,rd);

                float4 col = 0;
                if(d < MAX_DIST)
                {
                    // col.x = 1;
                    float3 p = ro + rd * d;
                    float3 n = GetNormal(p);
                    col.xyz = n;
                }

                return col;
            }
            ENDCG
        }
    }
}
