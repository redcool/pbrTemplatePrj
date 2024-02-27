Shader "URP/pbr1_learn"
{
    Properties
    {
        _MainTex("_MainTex",2d)="white"{}
        _NormalTex("_NormalTex",2d)="bump"{}
        _PBRMask("_PBRMask",2d)="white"{}
        _Metallic("_Metallic",range(0,1)) = 0.5
        _Smoothness("_Smoothness",range(0,1)) = 0.5
        _Occlusion("_Occlusion",range(0,1)) = 0.5
    }

    HLSLINCLUDE
        #define _TEST
        #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"

        struct appdata{
            float4 pos:POSITION;
            float2 uv:TEXCOORD;
            float2 uv1:TEXCOORD1;
            float3 normal:NORMAL;
            float4 tangent:TANGENT;
        };
        struct v2f{
            float4 pos:SV_POSITION;
            float4 uv:TEXCOORD;
            float4 tSpace0:TEXCOORD1;
            float4 tSpace1:TEXCOORD2;
            float4 tSpace2:TEXCOORD3;
        };

        sampler2D _MainTex;
        sampler2D _NormalTex;
        sampler2D _PBRMask;

        float4 _MainTex_ST;
        float _Metallic,_Smoothness,_Occlusion;

        // float4 _MainLightPosition;
        // float3 _MainLightColor;

        struct Light{
            float3 direction;
            float3 color;
        };

        Light GetMainLight(){
            Light l;
            l.direction = _MainLightPosition.xyz;
            l.color = _MainLightColor.xyz;
            return l;
        }

        #define POW4(a) ((a)*(a)*(a)*(a))
        float Pow4(float a){
            float a2 = a*a;
            return a2*a2;
        };

        v2f vert(appdata i){
            v2f o=(v2f)0;

            float3 worldPos = TransformObjectToWorld(i.pos);
            float3 n = normalize(TransformObjectToWorldNormal(i.normal));
            float3 t = normalize(TransformObjectToWorldDir(i.tangent.xyz));
            float3 b = normalize(cross(n,t)) * i.tangent.w;

            o.pos = TransformWorldToHClip(worldPos);
            o.tSpace0 = float4(t.x,b.x,n.x,worldPos.x);
            o.tSpace1 = float4(t.y,b.y,n.y,worldPos.y);
            o.tSpace2 = float4(t.z,b.z,n.z,worldPos.z);
            o.uv.xy = i.uv * _MainTex_ST.xy + _MainTex_ST.zw;

            return o;
        }

        float MCT(float nh,float lh,float a,float a2){
            float d = nh * nh * (a2-1)+1;
            return a2 /(d*d * max(0.1,lh*lh) * (4*a+2));
        }

        float4 frag(v2f i):SV_TARGET{
            float2 mainUV = i.uv;
            float4 mainTex = tex2D(_MainTex,mainUV);

            float3 albedo = mainTex.xyz;
            float alpha = mainTex.w;

            float4 pbrMask = tex2D(_PBRMask,mainUV);
            float metallic = pbrMask.x * _Metallic;
            float smoothness = pbrMask.y * _Smoothness;
            float occlusion = lerp(1,pbrMask.z, _Occlusion);
            float roughness  = 1 - smoothness;
            float a = max(roughness * roughness,.00001); //HALF_MIN_SQRT
            float a2 = max(a*a,.000001); // HALF_MIN
            

            float3 worldPos = float3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);

            float3 tn = UnpackNormal(tex2D(_NormalTex,mainUV));
            float3 n = normalize(float3(
                dot(i.tSpace0.xyz,tn),
                dot(i.tSpace1.xyz,tn),
                dot(i.tSpace2.xyz,tn)
            ));
            // n = float3(i.tSpace0.z,i.tSpace1.z,i.tSpace2.z);

            float3 diffColor = albedo * (1-metallic);
            float3 specColor = lerp(0,albedo,metallic);
            Light mainLight = GetMainLight();

            float3 v = normalize(_WorldSpaceCameraPos - worldPos);
            float3 l = (mainLight.direction);
            float3 h = normalize(v + l);
            float nl = saturate(dot(n,l));
            float nv = saturate(dot(n,v));
            float nh = saturate(dot(n,h));
            float lh = saturate(dot(l,h));
// return n.xyzx;
            float3 giColor = 0;
            float3 directColor = 0;
//=========== gi color

            float3 reflectDir = reflect(-v,n);
            float lod = (1.7-0.7*roughness) * 6 * roughness;//lerp(0,6,roughness);
            float4 envColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0,reflectDir,lod);
            envColor.xyz = DecodeHDREnvironment(envColor,unity_SpecCube0_HDR);

            float surfaceReduction = 1/(a2+1);
            float grazingTerm = saturate(smoothness+metallic);

            float fresnelTerm = Pow4(1 - nv);
            float3 giSpec = surfaceReduction * envColor.xyz * lerp(specColor,grazingTerm,fresnelTerm);

            float3 giDiff = SampleSH(n) * diffColor;
            giColor = (giDiff + giSpec) * occlusion;
//=========== direct color
            float3 radiance = nl * mainLight.color;
            float specTerm = MCT(nh,lh,a,a2);

            directColor = (diffColor + specTerm * specColor) * radiance;

            float4 col = 0;

            col.xyz += giColor;
            col.xyz += directColor;

            return col;
        }

    ENDHLSL

    SubShader
    {
        pass{
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            ENDHLSL
        }
    }
}