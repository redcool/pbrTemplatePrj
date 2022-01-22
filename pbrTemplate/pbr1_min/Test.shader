Shader "Hidden/Test"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _NormalMap("_NormalMap",2d) = "white"{}
        
        _PbrMask("_PbrMask",2d) = "white"{}
        _Metallic("_Metallic",range(0,1)) = 0
        _Smoothness("_Smoothness",range(0,1)) = 0
        _Occlusion("_Occlusion",range(0,1)) = 0
        
    }
    SubShader
    {

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityLib.hlsl"

            

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

            v2f vert (appdata v)
            {
                v2f o;

                float3 wp = mul((float3x3)unity_ObjectToWorld,v.vertex.xyz);
                float3 n = normalize(TransformObjectToWorldNormal(v.normal));
                float3 t = TransformObjectToWorldDir(v.tangent.xyz);
                float3 b = cross(n,t) * v.tangent.w;

                o.tSpace0 = float4(t.x,b.x,n.x,wp.x);
                o.tSpace1 = float4(t.y,b.y,n.y,wp.y);
                o.tSpace2 = float4(t.z,b.z,n.z,wp.z);

                o.vertex = TransformWorldToHClip(float4(wp,1));
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _NormalMap;
            sampler2D _PbrMask;
            samplerCUBE unity_SpecCube0;
            float4 unity_SpecCube0_HDR;

            float _Metallic,_Smoothness,_Occlusion;

            float4 frag (v2f i) : SV_Target
            {
                float4 mainTex = tex2D(_MainTex, i.uv);
                float3 albedo = mainTex.xyz;
                float alpha = mainTex.w;

                float3 tn = UnpackNormal(tex2D(_NormalMap,i.uv));
                float3 n = normalize(float3(
                    dot(i.tSpace0.xyz,tn),
                    dot(i.tSpace1.xyz,tn),
                    dot(i.tSpace2.xyz,tn)
                ));

                float3 worldPos = float3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);
                float3 l = GetWorldSpaceLightDir(worldPos);
                float3 v = normalize(GetWorldSpaceViewDir(worldPos));
                float3 h = normalize(l+v);
                float nl = saturate(dot(n,l));
                float nh = saturate(dot(n,h));
                float lh = saturate(dot(l,h));
                float nv = saturate(dot(n,v));

                // float nlGrid = nl * 3;
                // float nlId = floor(nlGrid);
                // float nlFactor = frac(nlGrid);
                // return nlId/3;

                float4 pbrMask = tex2D(_PbrMask,i.uv);
                float metallic = pbrMask.x * _Metallic;
                float smoothness = pbrMask.y * _Smoothness;
                float occlusion = lerp(1,pbrMask.z , _Occlusion);

                float3 diffColor = albedo * (1-metallic);
                float3 specColor = lerp(0.04,albedo, metallic);

                float3 giDiff = SampleSH(n) * diffColor;
                
                float roughness = 1 - smoothness;
                float a = roughness * roughness;
                float a2 = a*a;

                float mip = roughness * (1.7 - 0.7*roughness) * 6;
                float3 refDir = reflect(-v,n);
                float4 envColor = texCUBElod(unity_SpecCube0,float4(refDir,mip));
                envColor.xyz = DecodeHDREnvironment(envColor,unity_SpecCube0_HDR);

                
                float surfaecReduction = 1/(a2 + 1);
                float grazingTerm = saturate(smoothness + metallic);
                float fresnelTerm = Pow4(1 - nv);
                float3 giSpec = surfaecReduction * envColor.xyz * lerp(specColor,grazingTerm,fresnelTerm);
                

                float4 col = 0;
                col.xyz = (giDiff + giSpec) * occlusion;
                float specTerm = MinimalistCookTorrance(nh,lh,a,a2);
                float radiance = nl * _MainLightColor.xyz;
                col.xyz += (diffColor + specColor * specTerm) * radiance;
                return col;
            }
            ENDHLSL
        }
    }
}
