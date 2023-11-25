Shader "URP/Unlit/ParallaxOcclusion"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DepthTex("_DepthTex",2d) =""{}
        _Scale("_Scale",range(0,1)) = 0.1
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

            #define USE_SAMPLER2D
            #include "../../../PowerShaderLib/Lib/ParallaxMapping.hlsl"

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

                float4 tSpace0:TEXCOORD2;
                float4 tSpace1:TEXCOORD3;
                float4 tSpace2:TEXCOORD4;

                float3 viewDirTS:TEXCOORD5;
            };

            sampler2D _MainTex;
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _Scale;
            CBUFFER_END

            sampler2D _DepthTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;

                float3 n = TransformObjectToWorldNormal(v.normal);
                float3 t = TransformObjectToWorldDir(v.tangent.xyz);
                float3 b = normalize(cross(n,t)) * v.tangent.w;
                float3 worldPos= TransformObjectToWorld(v.vertex.xyz);

                // o.tSpace0 = float4(t.x,b.x,n.x,worldPos.x);
                // o.tSpace1 = float4(t.y,b.y,n.y,worldPos.y);
                // o.tSpace2 = float4(t.z,b.z,n.z,worldPos.z);

                float3 view = (_WorldSpaceCameraPos - worldPos);

                o.viewDirTS = float3(dot(t,view),dot(b,view),dot(n,view));
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;

                float2 offset = ParallaxOcclusionOffset(_Scale,normalize(i.viewDirTS),uv,_DepthTex);
                uv += offset;

                if(uv.x >1 || uv.x < 0 || uv.y>1 ||uv.y<0)
                    discard;
                float4 c = tex2D(_MainTex,uv);
                return c;
            }
            ENDHLSL
        }
    }
}
