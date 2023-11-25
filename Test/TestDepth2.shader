Shader "Unlit/TestDepth2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DepthTex("_DepthTex",2d)=""{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
cull off
        // blend srcAlpha oneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

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
                float4 tSpace0:TEXCOORD1;
                float4 tSpace1:TEXCOORD2;
                float4 tSpace2:TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _DepthTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 t = UnityObjectToWorldDir(v.tangent.xyz);
                float3 n = UnityObjectToWorldNormal(v.normal);
                float3 b = normalize(cross(n,t)) * v.tangent.w;
                float3 p = mul(unity_ObjectToWorld,v.vertex);
                o.tSpace0 = float4(t.x,b.x,n.x,p.x);
                o.tSpace1 = float4(t.y,b.y,n.y,p.y);
                o.tSpace2 = float4(t.z,b.z,n.z,p.z);
                return o;
            }


            bool CheckDepth(inout float3 pos,float3 dir){
                const int count = 100;
                // dir.xyz /= dir.z;
                
                float3 stepDir = dir/(count);
                UNITY_LOOP for(int i=0;i<count;i++){

                    half2 depth = tex2D(_DepthTex,pos.xy);
                    depth.x = 1-depth.x;

                    if(pos.z > depth.x && pos.z < depth.y && pos.x >0 && pos.x < 1 && pos.y > 0 && pos.y < 1)
                    {
                        return true;
                    }
                    pos += stepDir;
                    
                }
                return false;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3x3 rot = float3x3(i.tSpace0.xyz,i.tSpace1.xyz,i.tSpace2.xyz);
                float3 worldPos = float3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);
                float3 v = normalize(_WorldSpaceCameraPos - worldPos);
                float3 viewDirTS = (mul(-v,rot));
                viewDirTS.z = abs(viewDirTS.z);

                float3 startPos = float3(i.uv,0);
                half4 col = 0;
                if(CheckDepth(startPos,viewDirTS)){
                    col += tex2D(_MainTex, startPos.xy);
                }
                // col += tex2D(_MainTex,i.uv);
                return col;
            }
            ENDCG
        }
    }
}
