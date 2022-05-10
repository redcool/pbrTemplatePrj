Shader "URP/PowerOcean"
{
    Properties
    {
        [Header(Color)]
        _Color1("_Color1",color) = (1,1,1,1)
        _Color2("_Color2",color) = (1,1,1,1)
        [Header(Main)]
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_NormalMap("_NormalMap",2d) = "bump"{}
        _NormalScale("_NormalScale",float) = .3

        _NormalSpeed("_NormalSpeed",float) = 1
        _NormalTiling("_NormalTiling",float) = 1

        [Header(PBR Mask)]
        _PBRMask("_PBRMask(Metallic:R,Smoothness:G,Occlusion:B)",2d)="white"{}
        _Metallic("_Metallic",range(0,1)) = 0.5
        _Smoothness("_Smoothness",range(0,1)) = 0.5
        _Occlusion("_Occlusion",range(0,1)) = 0

        [Header(Test)]
        _Depth("_Depth",float) = 1
        _WaveTiling("_WaveTiling",vector) = (0.1,1,0,0)
        _WaveScale("_WaveScale",float) = 1
        _WaveSpeed("_WaveSpeed",float) = 1
    }
    SubShader
    {

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityLib.hlsl"

            // #define URP_LEGACY_HLSL
            #include "PowerLib/PowerUtils.hlsl"
            #include "PowerLib/NodeLib.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                half2 uv : TEXCOORD0;
                half4 vertex : SV_POSITION;
                float4 tSpace0:TEXCOORD1;
                float4 tSpace1:TEXCOORD2;
                float4 tSpace2:TEXCOORD3;
            };

            v2f vert (appdata v)
            {
                v2f o;
                half3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.vertex = TransformWorldToHClip(worldPos);
                o.uv = v.uv;

                half3 n = normalize(TransformObjectToWorldNormal(v.normal));
                half3 t = normalize(TransformObjectToWorldDir(v.tangent.xyz));
                half3 b = normalize(cross(n,t)) * v.tangent.w;

                o.tSpace0 = half4(t.x,b.x,n.x,worldPos.x);
                o.tSpace1 = half4(t.y,b.y,n.y,worldPos.y);
                o.tSpace2 = half4(t.z,b.z,n.z,worldPos.z);
                return o;
            }

            sampler2D _MainTex;
            samplerCUBE unity_SpecCube0;
            sampler2D _NormalMap;
            sampler2D _PBRMask;
            sampler2D _CameraOpaqueTexture;
            sampler2D _CameraDepthTexture;

            CBUFFER_START(UntiyPerMaterial)
            half _Smoothness;
            half _Metallic;
            half _Occlusion;

            half _NormalScale;
            half _Depth;
            half4 _NormalMap_ST;
            half _NormalSpeed,_NormalTiling;
            half4 _Color2,_Color1;

            half2 _WaveTiling;
            half _WaveScale,_WaveSpeed;

            CBUFFER_END

            half3 CalcWorldPos(half4 hclipCoord ){
                half2 suv =  hclipCoord.xy /_ScreenParams.xy;
                half depth = tex2D(_CameraDepthTexture,suv);
                half3 wpos = ScreenToWorldPos(suv,depth,unity_MatrixInvVP);
                return wpos;
            }

            half2 CalcOffsetTiling(half2 posXZ,half2 dir,half speed,half tiling){
                half2 uv = posXZ + dir * speed *_Time.x;
                return uv * tiling;
            }


            half4 frag (v2f i) : SV_Target
            {
                half3 worldPos = half3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);
                // half3 vertexTangent = (half3(i.tSpace0.x,i.tSpace1.x,i.tSpace2.x));
                // half3 vertexBinormal = normalize(half3(i.tSpace0.y,i.tSpace1.y,i.tSpace2.y));
                half3 vertexNormal = normalize(half3(i.tSpace0.z,i.tSpace1.z,i.tSpace2.z));


                half3 wpos = CalcWorldPos(i.vertex);
                half seaDepth = wpos.y - worldPos.y - _Depth;

                // calc normal uv then 2 normal blend
                // half2 normalSpeed = half2(_NormalSpeed,2*_NormalSpeed);
                // half4 normalUV = worldPos.xzxz  +  half4(1,0.2,-1,-0.2) * _NormalSpeed * (_Time.x);
                // normalUV *= half4(_NormalTiling.xx,_NormalTiling.xx*10);

                half2 normalUV1 = CalcOffsetTiling(worldPos.xz,half2(1,0.2),_NormalSpeed,_NormalTiling);
                half2 normalUV2 = CalcOffsetTiling(worldPos.xz,half2(-1,-0.2),_NormalSpeed,_NormalTiling);

                half3 tn = UnpackNormalScale(tex2D(_NormalMap,normalUV1),_NormalScale);
                half3 tn2 = UnpackNormalScale(tex2D(_NormalMap,normalUV2),_NormalScale);
                tn = BlendNormal(tn,tn2);

                half3 n = normalize(half3(
                    dot(i.tSpace0.xyz,tn),
                    dot(i.tSpace1.xyz,tn),
                    dot(i.tSpace2.xyz,tn)
                ));

                half2 noiseUV = CalcOffsetTiling(worldPos.xz * _WaveTiling.xy,half2(0,-1),_WaveSpeed,1);

                half simpleNoise = Unity_SimpleNoise_half(noiseUV,_WaveScale);

                half3 l = GetWorldSpaceLightDir(worldPos);
                half3 v = normalize(GetWorldSpaceViewDir(worldPos));
                half3 h = normalize(l+v);
                half nl = saturate(dot(n,l));
                half nv = saturate(dot(n,v));
                half nh = saturate(dot(n,h));
                half lh = saturate(dot(l,h));

                half fresnel = 1-saturate(dot(vertexNormal,v));
                half3 seaColor = lerp(_Color1,_Color2,fresnel);
                seaColor *= clamp(simpleNoise,0.3,1);
                // return seaColor.xyzx;

                half3 emissionColor = 0;
                // emissionColor = simpleNoise;

//-------- pbr
                half4 pbrMask = tex2D(_PBRMask,i.uv);

                half smoothness = _Smoothness * pbrMask.y;
                half roughness = 1 - smoothness;
                half a = max(roughness * roughness, HALF_MIN_SQRT);
                half a2 = max(a * a ,HALF_MIN);

                half metallic = _Metallic * pbrMask.x;
                half occlusion = lerp(1, pbrMask.z,_Occlusion);

                half4 mainTex = tex2D(_MainTex, i.uv);
                half3 albedo = mainTex.xyz * seaColor;
                half alpha = mainTex.w;

                half3 diffColor = albedo * (1-metallic);
                half3 specColor = lerp(0.04,albedo,metallic);

                half3 sh = SampleSH(n);
                half3 giDiff = sh * diffColor;

                half mip = roughness * (1.7 - roughness * 0.7) * 6;
                half3 reflectDir = reflect(-v,n);
                half4 envColor = texCUBElod(unity_SpecCube0,half4(reflectDir,mip));
                envColor.xyz = DecodeHDREnvironment(envColor,unity_SpecCube0_HDR);

                half surfaceReduction = 1/(a2+1);
                
                half grazingTerm = saturate(smoothness + metallic);
                half fresnelTerm = Pow4(1-nv);
                half3 giSpec = surfaceReduction * envColor.xyz * lerp(specColor,grazingTerm,fresnelTerm);

                half4 col = 0;
                col.xyz = (giDiff + giSpec) * occlusion;

                half3 radiance = nl * _MainLightColor.xyz;
                half specTerm = MinimalistCookTorrance(nh,lh,a,a2);
                col.xyz += (diffColor + specColor * specTerm) * radiance;
//---------emission
                col.xyz += emissionColor;
                return col;
            }
            ENDHLSL
        }
    }
}
