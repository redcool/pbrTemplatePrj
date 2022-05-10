#if !defined(POWER_WATER_FORWARD_PASS_HLSL)
#define POWER_WATER_FORWARD_PASS_HLSL

            #include "UnityLib.hlsl"

            // #define URP_LEGACY_HLSL
            #include "PowerLib/PowerUtils.hlsl"
            #include "PowerLib/NodeLib.hlsl"
            #include "PowerLib/UnityGI.hlsl"

sampler2D _MainTex;


            sampler2D _NormalMap;
            sampler2D _PBRMask;
            sampler2D _CameraOpaqueTexture;
            sampler2D _CameraDepthTexture;
            sampler2D _FoamTex;

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
            half3 _WaveDir;
            half _WaveScale,_WaveSpeed,_WaveStrength;

            CBUFFER_END            



            half2 CalcOffsetTiling(half2 posXZ,half2 dir,half speed,half tiling){
                half2 uv = posXZ + dir * speed *_Time.x;
                return uv * tiling;
            }



            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                half4 uvNoise : TEXCOORD0;
                half4 vertex : SV_POSITION;
                float4 tSpace0:TEXCOORD1;
                float4 tSpace1:TEXCOORD2;
                float4 tSpace2:TEXCOORD3;
            };


            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
// simple noise
                half3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                half2 noiseUV = CalcOffsetTiling(worldPos.xz * _WaveTiling.xy,_WaveDir,_WaveSpeed,1);
                half simpleNoise = Unity_SimpleNoise_half(noiseUV,_WaveScale);

                v.vertex.y = simpleNoise * _WaveStrength;
                o.vertex = TransformObjectToHClip(v.vertex);

                o.uvNoise.xy = v.uv;
                o.uvNoise.z = simpleNoise;

                half3 n = normalize(TransformObjectToWorldNormal(v.normal));
                half3 t = normalize(TransformObjectToWorldDir(v.tangent.xyz));
                half3 b = normalize(cross(n,t)) * v.tangent.w;

                o.tSpace0 = half4(t.x,b.x,n.x,worldPos.x);
                o.tSpace1 = half4(t.y,b.y,n.y,worldPos.y);
                o.tSpace2 = half4(t.z,b.z,n.z,worldPos.z);


                return o;
            }

            half3 CalcWorldPos(half2 screenUV){
                half depth = tex2D(_CameraDepthTexture,screenUV);
                half3 wpos = ScreenToWorldPos(screenUV,depth,unity_MatrixInvVP);
                return wpos;
            }

            half3 Blend2Normals(half3 worldPos,half3 tSpace0,half3 tSpace1,half3 tSpace2){
                // calc normal uv then 2 normal blend
                half2 normalUV1 = CalcOffsetTiling(worldPos.xz,half2(1,0.2),_NormalSpeed,_NormalTiling);
                half2 normalUV2 = CalcOffsetTiling(worldPos.xz,half2(-1,-0.2),_NormalSpeed,_NormalTiling);

                half3 tn = UnpackNormalScale(tex2D(_NormalMap,normalUV1),_NormalScale);
                half3 tn2 = UnpackNormalScale(tex2D(_NormalMap,normalUV2),_NormalScale);
                tn = BlendNormal(tn,tn2);

                half3 n = normalize(half3(
                    dot(tSpace0.xyz,tn),
                    dot(tSpace1.xyz,tn),
                    dot(tSpace2.xyz,tn)
                ));
                return n;
            }

            half3 CalcSeaColor(half2 screenUV,half3 worldPos,half3 vertexNormal,half3 viewDir,half clampNoise){
                half fresnel = 1-saturate(dot(vertexNormal,viewDir));
                half3 seaColor = lerp(_Color1,_Color2,fresnel);
                seaColor *= clampNoise;

                half3 wpos = CalcWorldPos(screenUV);
                half seaDepth = saturate(wpos.y - worldPos.y - _Depth);
                // refraction
                half refractionRate = lerp(clampNoise,0,seaDepth);
                half4 screenColor = tex2D(_CameraOpaqueTexture,screenUV + clampNoise * refractionRate*0.05);
                seaColor = lerp(seaColor,screenColor,seaDepth);

                // foam
                // seaColor += seaDepth * clampNoise;
                return seaColor;
            }

            half4 frag (v2f i) : SV_Target
            {
                half simpleNoise = i.uvNoise.z;
                half clampNoise = clamp(simpleNoise,0.3,1);

                half2 screenUV =  i.vertex.xy /_ScreenParams.xy;

                half3 worldPos = half3(i.tSpace0.w,i.tSpace1.w,i.tSpace2.w);
                // half3 vertexTangent = (half3(i.tSpace0.x,i.tSpace1.x,i.tSpace2.x));
                // half3 vertexBinormal = normalize(half3(i.tSpace0.y,i.tSpace1.y,i.tSpace2.y));
                half3 vertexNormal = normalize(half3(i.tSpace0.z,i.tSpace1.z,i.tSpace2.z));

                // half2 noiseUV = CalcOffsetTiling(worldPos.xz * _WaveTiling.xy,_WaveDir,_WaveSpeed,1);
                // half simpleNoise = Unity_SimpleNoise_half(noiseUV,_WaveScale);
                // return simpleNoise;

                half3 n = Blend2Normals(worldPos,i.tSpace0.xyz,i.tSpace1.xyz,i.tSpace2.xyz);

//------ brdf info
                half3 l = GetWorldSpaceLightDir(worldPos);
                half3 v = normalize(GetWorldSpaceViewDir(worldPos));
                half3 h = normalize(l+v);
                half nl = saturate(dot(n,l));
                half nv = saturate(dot(n,v));
                half nh = saturate(dot(n,h));
                half lh = saturate(dot(l,h));


                half3 seaColor = CalcSeaColor(screenUV,worldPos,vertexNormal,v,clampNoise);
// return seaColor.xyzx;
                half3 emissionColor = 0;
//-------- pbr
                half2 mainUV = i.uvNoise.xy;
                half4 pbrMask = tex2D(_PBRMask,mainUV);

                half smoothness = _Smoothness * pbrMask.y;
                half roughness = 1 - smoothness;
                half a = max(roughness * roughness, HALF_MIN_SQRT);
                half a2 = max(a * a ,HALF_MIN);

                half metallic = _Metallic * pbrMask.x;
                half occlusion = lerp(1, pbrMask.z,_Occlusion);

                half4 mainTex = tex2D(_MainTex, mainUV);
                half3 albedo = mainTex.xyz * seaColor;
                half alpha = mainTex.w;

                half3 diffColor = albedo * (1-metallic);
                half3 specColor = lerp(0.04,albedo,metallic);

                half3 sh = SampleSH(n);
                half3 giDiff = sh * diffColor;

                half mip = roughness * (1.7 - roughness * 0.7) * 6;
                half3 reflectDir = reflect(-v,n);
                half4 envColor = 0;
                // envColor.xyz = GlossyEnvironmentReflection(reflectDir,worldPos,roughness,1);
// ibl as reflection
                envColor = SAMPLE_TEXTURECUBE_LOD(_GlossyEnvironmentCubeMap,sampler_GlossyEnvironmentCubeMap,reflectDir,mip);
                envColor.xyz = DecodeHDREnvironment(envColor,_GlossyEnvironmentCubeMap_HDR);

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
#endif //POWER_WATER_FORWARD_PASS_HLSL