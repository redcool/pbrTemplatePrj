Shader "TestParallax"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DepthTex("_DepthTex",2d) =""{}
        _Scale("_Scale",float) = 0.1
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

            #include "../../PowerShaderLib/Lib/UnityLib.hlsl"

            #define USE_SAMPLER2D
            #include "../../PowerShaderLib/Lib/ParallaxMapping.hlsl"

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

            // float3 _MainLightPosition;
            sampler2D _DepthTex;

            SAMPLER(sampler_linear_repeat );

            bool CheckDepth(inout float3 pos,float3 dir){
                const int count = 10;
                float3 stepDir = dir/(dir.z*count);

                UNITY_LOOP for(int i=0;i<count;i++){
                    float2 d = tex2D(_DepthTex,pos) * 2 -1;
                    d.x = 1-d.x;
                    
                    if(pos.z > d.x && pos.z < d.y && pos.x >0&&pos.x<1&&pos.y>0&&pos.y<1 )
                    {
                        return true;
                    }
                    pos += stepDir;
                }
                return false;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;

                float3 n = TransformObjectToWorldNormal(v.normal);
                float3 t = TransformObjectToWorldDir(v.tangent.xyz);
                float3 b = normalize(cross(n,t)) * v.tangent.w;
                float3 worldPos= TransformObjectToWorld(v.vertex.xyz);

                o.tSpace0 = float4(t.x,b.x,n.x,worldPos.x);
                o.tSpace1 = float4(t.y,b.y,n.y,worldPos.y);
                o.tSpace2 = float4(t.z,b.z,n.z,worldPos.z);

                float3 view = -(_WorldSpaceCameraPos - worldPos);

                o.viewDirTS = float3(dot(t,view),dot(b,view),dot(n,view));
                return o;
            }


            float2 ParallaxOffset(float scale,float3 viewDirTS,float2 uv,sampler2D depthTex,half2 layerRange=(8,30)){
                float numLayers = lerp(layerRange.y,layerRange.x,abs(dot(half3(0,0,1),viewDirTS)));
                // const float numLayers = 10;
                float layerDepth = 1/numLayers;
                float curLayerDepth = 0.0;
                float2 P = viewDirTS.xy * scale;
                float2 deltaUV = P/numLayers;
                float2 curUV = uv;

                float curDepth = 1-tex2D(depthTex,curUV).w;
                UNITY_LOOP while(curLayerDepth < curDepth){
                    curUV -= deltaUV;
                    curDepth = 1 - tex2D(depthTex,curUV).w;
                    curLayerDepth += layerDepth;
                }
                // return curUV - uv; // steep end

                // ------- occlusion offset
                float2 prevUV = curUV + deltaUV;
                float afterDepth = curDepth - curLayerDepth;
                float beforeDepth = 1-tex2D(depthTex,prevUV).w - curLayerDepth + layerDepth;
                float weight = afterDepth/(afterDepth - beforeDepth);
                float2 finalUV = lerp(curUV,prevUV,weight);
                return finalUV - uv;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;

                float2 offset = ParallaxOcclusionOffset(_Scale,-normalize(i.viewDirTS),uv,_DepthTex);
                uv += offset;

                if(uv.x >1 || uv.x < 0 || uv.y>1 ||uv.y<0)
                    discard;
float4 c = tex2D(_MainTex,uv);
                return c;

                float3 worldPos = float3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);
                float3x3 rot = float3x3(i.tSpace0.xyz,i.tSpace1.xyz,i.tSpace2.xyz);
                float3 v = normalize(_WorldSpaceCameraPos - worldPos);
                float3 viewDirTS = mul(-v,rot);

                float3 pos = float3(i.uv,0);
                float3 dir = viewDirTS;

                float4 col = 0;

                if(CheckDepth(pos,dir)){
                    col = tex2D(_MainTex, pos.xy);
                }
                // sample the texture
                
                return col;
            }
            ENDHLSL
        }
    }
}
