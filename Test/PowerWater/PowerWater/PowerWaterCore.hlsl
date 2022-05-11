#if !defined(POWER_WATER_CORE_HLSL)
#define POWER_WATER_CORE_HLSL
            half2 CalcOffsetTiling(half2 posXZ,half2 dir,half speed,half tiling){
                half2 uv = posXZ + dir * speed *_Time.x;
                return uv * tiling;
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

            half3 CalcFoamColor(half2 uv,half3 wpos,half3 worldPos,half depth,half depthMin,half depthMax,half3 blendNormal,half clampNoise,half offsetSpeed,half2 uvTiling){
                half foamDepth = saturate(wpos.y - worldPos.y + depth);
                foamDepth = smoothstep(depthMin,depthMax,foamDepth);
// return foamDepth;
                half2 foamOffset = blendNormal.xz*0.05 + half2(clampNoise*0.1,0);
                foamOffset *= offsetSpeed;
                half3 foamTex = tex2D(_FoamTex,uv * uvTiling + foamOffset);
                return foamTex * foamDepth;
            }

            half3 CalcSeaColor(half2 screenUV,half3 worldPos,half3 vertexNormal,half3 viewDir,half clampNoise,half3 blendNormal,half2 uv){
                // -------------------- fresnel color
                half fresnel = 1-saturate(dot(vertexNormal,viewDir));
                half3 seaColor = lerp(_Color1,_Color2,fresnel);
                // -------------------- noise depth shadow
                seaColor *= clampNoise;

                half3 wpos = CalcWorldPos(screenUV);
                half seaDepth = saturate(wpos.y - worldPos.y - _Depth);

                // -------------------- depth and shallow color
                seaColor *= lerp(_DepthColor,_ShallowColor,seaDepth);

                // -------------------- caustics ,depth is 1
                half3 causticsColor = CalcFoamColor(uv,wpos,worldPos,0.5,0.3,0,blendNormal*2,clampNoise,_CausticsSpeed,_CausticsTiling);
                // causticsColor *= _CausticsIntensity;
                // seaColor += causticsColor;
                
                // -------------------- refraction color
                half refractionRate = lerp(clampNoise,0,seaDepth);
                half3 refractionColor = tex2D(_CameraOpaqueTexture,screenUV + blendNormal.xz * clampNoise * refractionRate*0.05 * _RefractionIntensity);
                refractionColor = saturate(lerp(refractionColor,causticsColor,_CausticsIntensity));
                seaColor = lerp(seaColor,refractionColor,seaDepth);

                // -------------------- foam, depth is 0.5
                half3 foamColor =  CalcFoamColor(uv,wpos,worldPos,0.5,_FoamDepthMin,_FoamDepthMax,blendNormal,clampNoise,_FoamSpeed,_FoamTex_ST.xy);
                seaColor += foamColor;




                return seaColor;
            }
#endif //POWER_WATER_CORE_HLSL