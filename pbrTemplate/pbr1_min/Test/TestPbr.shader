Shader "Unlit/TestPbr"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Metallic("_Metallic",range(0,1)) = 0
        _Smoothness("_Smoothness",range(0,1)) = 0
        _IBL("_IBL",cube)=""{}
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

            #include "../PowerLib/UnityLib.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal:TEXCOORD1;
                float3 viewDir:TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Smoothness,_Metallic;
            samplerCUBE _IBL;
            float4 _IBL_HDR;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = TransformObjectToWorldNormal(v.normal);

                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 mainTex = tex2D(_MainTex, i.uv);
                half3 albedo = mainTex.xyz;
                half alpha = mainTex.w;

                half3 n = normalize(i.normal);
                half3 l = _MainLightPosition;
                half3 v = i.viewDir;
                half3 h = normalize(l+v);
                
                half3 diffColor = albedo * (1-_Metallic);
                half3 specColor = lerp(0.04,albedo,_Metallic);

                half rough = 1-_Smoothness;
                half a = max(rough * rough,1e-4);
                half a2 = a * a;

                half radiance = saturate(dot(n,l));

                half nh = saturate(dot(n,h));
                half lh = saturate(dot(l,h));
                half nv = saturate(dot(n,v));

                half d = nh*nh * (a2-1)+1;
                half specTerm = a2/(d*d * max(0.001,lh*lh) * (4*a+2));

                half3 col = (diffColor + specTerm * specColor) * radiance * _MainLightColor;

                half3 sh = SampleSH(n);
                half3 giDiff = sh * diffColor;

                // half mip = lerp(0,6,rough);
                half mip = (1.7 - rough * 0.7)*rough * 6;
                half3 reflectDir = reflect(-v,n);
                half4 envColor = texCUBElod(_IBL,half4(reflectDir,mip));
                envColor.xyz = DecodeHDREnvironment(envColor,_IBL_HDR);
                // return envColor;

                half surfaceReduction = 1/(a2+1);
                half grazingTerm = saturate(_Smoothness+_Metallic);
                half fresnelTerm = Pow4(1 - nv);
                half3 giSpec = surfaceReduction * envColor * lerp(specColor,grazingTerm,fresnelTerm);

// return lerp(specColor,grazingTerm,fresnelTerm).xyzx;
                col.xyz += (giDiff + giSpec);

                return half4(col,1);
            }
            ENDHLSL
        }
    }
}
