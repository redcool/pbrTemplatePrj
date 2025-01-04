
Shader "FX/Box/Nature/BoxClouds3"
{
    /**
        clouds post , look this:
        https://www.youtube.com/watch?v=4QOcCGI6xOU&t=322s

    */
    Properties
    {
        [Header(Noise)]
        _NoiseTex("_NoiseTex",3d)=""{}

        _ShapeNoiseWeights("_ShapeNoiseWeights",vector)=(1,.48,.15,0)
        _DensityOffset("_DensityOffset",range(0,1)) = .5
        _DensityMultiplier("_DensityMultiplier",float) = 1
        _CloudScale("_CloudScale",float) = .6


        _DetailNoiseTex("_DetailNoiseTex",3d)=""{}
        _DetailNoiseScale("_DetailNoiseScale",float) = 3
        _DetailSpeed("_DetailSpeed",float) = 1

        _DetailWeights("_DetailWeights",vector) = (1,.5,.5,0)
        _DetailNoiseWeight("_DetailNoiseWeight",float) = 3.4

        _BlueNoise("_BlueNoise",2d) = ""{}

        [Header(Base)]
        _WindDir("_WindDir",vector) = (0.1,0,0,0)
        _BoundsMin("_BoundsMin",vector) = (-1000,-100,-1000,0)
        _BoundsMax("_BoundsMax",vector) = (1000,100,1000,0)
        _BoundsFade("_BoundsFade",vector) = (50,50,50,0)

        [Header(Lighting)]
        /*
        (forward scatter,backward scatter,base brightness,phase factor)
        */
        _PhaseParams("_PhaseParams",vector) = (.8,.33,1,.48)

        _NumStepsLight("_NumStepsLight",int) = 8
        _RayOffsetStrength("_RayOffsetStrength",float) = 10

        _LightAbsorptionTowardSun("_LightAbsorptionTowardSun",float) = 1.2
        _LightAbsorptionThroughCloud("_LightAbsorptionThroughCloud",float) = 0.75
        _DarknessThreshold("_DarknessThreshold",float) = 0.15
        _ColA("_ColA",color) = (1,1,1,1)
        _ColB("_ColB",color) = (0,0,0.7,1)
    }

HLSLINCLUDE
            #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
            #include "../../../PowerShaderLib/Lib/ScreenTextures.hlsl"            
            #include "CloudLib.hlsl"

            struct appdata {
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 viewVector : TEXCOORD1;
            };
            // #define FULL_SCREEN
            v2f vert (appdata v) {
                v2f output;
                #if !defined(FULL_SCREEN)
                output.pos = UnityObjectToClipPos(v.vertex);
                float3 hitPos = mul(unity_ObjectToWorld,float4(v.vertex) );
                output.viewVector = hitPos - _WorldSpaceCameraPos;
                #endif

                #if defined(FULL_SCREEN)
                output.pos = float4(v.vertex.xy*2,UNITY_NEAR_CLIP_VALUE,1);
                // Camera space matches OpenGL convention where cam forward is -z. In unity forward is positive z.
                // (https://docs.unity3d.com/ScriptReference/Camera-cameraToWorldMatrix.html)
                float2 dirScale = float2(1,1);
                #if defined(UNITY_UV_STARTS_AT_TOP)
                    dirScale.y =-1;
                #endif
                float3 viewVector = mul(unity_CameraInvProjection, float4(output.pos.xy*dirScale, 0, -1));
                output.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));
                #endif

                return output;
            }

            CBUFFER_START(UnityPerMaterial)
            // Textures
            sampler3D _NoiseTex;
            sampler3D _DetailNoiseTex;
            sampler2D _WeatherMap;
            sampler2D _BlueNoise;

            sampler2D _MainTex;

            // Shape settings
            float _DensityMultiplier;
            float _DensityOffset;
            float _CloudScale;
            float _DetailNoiseScale;
            float _DetailNoiseWeight;
            float3 _DetailWeights;
            float4 _ShapeNoiseWeights;
            float4 _PhaseParams;

            // March settings
            int _NumStepsLight;
            float _RayOffsetStrength;

            float3 _BoundsMin;
            float3 _BoundsMax;
            float3 _BoundsFade;

            // Light settings
            float _LightAbsorptionTowardSun;
            float _LightAbsorptionThroughCloud;
            float _DarknessThreshold;
            float _DetailSpeed;

            float3 _ColA,_ColB;

            //-----
            float3 _WindDir;
            CBUFFER_END

            float4 _LightColor0;

            
            float sampleDensity1(float3 rayPos) {

                // Calculate texture sample positions
                float3 size = _BoundsMax - _BoundsMin;
                float3 boundsCentre = (_BoundsMin+_BoundsMax) * .5;
                float3 shapeSamplePos = (rayPos * 0.001 + _WindDir *_Time.y) * _CloudScale;

                // Calculate falloff at along x/z edges of the cloud container
                const float containerEdgeFadeDst = 50;
                float3 dstEdge = min(containerEdgeFadeDst,min(rayPos - _BoundsMin,_BoundsMax - rayPos));
                float edgeWeight = min(dstEdge.x,min(dstEdge.y,dstEdge.z))/containerEdgeFadeDst;
                
                // Calculate height gradient from weather map
                //float2 weatherUV = (size.xz * .5 + (rayPos.xz-boundsCentre.xz)) / max(size.x,size.z);
                //float _WeatherMap = _WeatherMap.SampleLevel(samplerWeatherMap, weatherUV, mipLevel).x;

                float heightPercent = (rayPos.y - _BoundsMin.y) / size.y;
                float gMin = .2;
                float gMax = .7;
                float heightGradient = saturate(remap(heightPercent, 0.0, gMin, 0, 1)) * saturate(remap(heightPercent, 1, gMax, 0, 1));
                heightGradient *= edgeWeight;

                // float heightGradient = edgeWeight * ((1-abs(heightPercent-0.5)));

                // Calculate base shape density
                float4 shapeNoise = tex3Dlod(_NoiseTex, float4(shapeSamplePos, 0));
                float4 normalizedShapeWeights = _ShapeNoiseWeights / dot(_ShapeNoiseWeights, 1);
                float shapeFBM = dot(shapeNoise, normalizedShapeWeights) * heightGradient;
                float baseShapeDensity = shapeFBM - _DensityOffset;

                // Save sampling from detail tex if shape density <= 0
                if (baseShapeDensity > 0) {
                    // Sample detail noise
                    float3 detailSamplePos = rayPos*0.001 * _DetailNoiseScale + _WindDir * _Time.y * _DetailSpeed;

                    float4 detailNoise = tex3Dlod(_DetailNoiseTex,float4(detailSamplePos, 0));
                    float3 normalizedDetailWeights = _DetailWeights / dot(_DetailWeights, 1);
                    float detailFBM = dot(detailNoise, normalizedDetailWeights);

                    // Subtract detail noise from base shape (weighted by inverse density so that edges get eroded more than centre)
                    float oneMinusShape = 1 - shapeFBM;
                    float detailErodeWeight = oneMinusShape * oneMinusShape * oneMinusShape;
                    float cloudDensity = baseShapeDensity - (1-detailFBM) * detailErodeWeight * _DetailNoiseWeight;
    
                    return cloudDensity * _DensityMultiplier;
                }
                return baseShapeDensity;
            }

            float sampleDensity(float3 rayPos) {
                float3 size = _BoundsMax - _BoundsMin;
                float3 boundsCentre = (_BoundsMax+_BoundsMin)*0.5;
                // float containerEdgeFadeDst = 50;
                float3 dstEdge = min(_BoundsFade,min(rayPos - _BoundsMin,_BoundsMax - rayPos));
                dstEdge /= _BoundsFade;
                float edgeWeight = min(dstEdge.x,min(dstEdge.y,dstEdge.z));

                float2 weatherUV = (size.xz * .5 + (rayPos.xz-boundsCentre.xz)) / max(size.x,size.z);
                float weatherMap = tex2Dlod(_WeatherMap, float4(weatherUV,0, 0)).x;


                // height atten ?
                float heightPercent = (rayPos.y - _BoundsMin.y) / size.y;
                float gMin = .2;
                float gMax = .7;
                gMin = .4 * weatherMap.x;
                gMax = .7 * weatherMap.x +gMin;

                float heightGradient = saturate(remap(heightPercent, 0.0, gMin, 0, 1)) * saturate(remap(heightPercent, 1, gMax, 0, 1));
                heightGradient *= edgeWeight;


                float3 pos = (rayPos * 0.001 + _WindDir * _Time.y )*_CloudScale;
                float4 noiseTex = tex3Dlod(_NoiseTex,float4(pos,pos.x));
                float shapeNoise = dot(noiseTex,_ShapeNoiseWeights/dot(_ShapeNoiseWeights,1)) * heightGradient;

                float baseNoise = shapeNoise - _DensityOffset;
                // detail layer
                float3 detailPos = rayPos * 0.001 * _DetailNoiseScale + _WindDir * _Time.y * _DetailSpeed;
                float4 detailNoiseTex = tex3Dlod(_DetailNoiseTex,detailPos.xyzx);
                float detailShapeNoise = dot(detailNoiseTex,_DetailWeights/dot(_DetailWeights,1));

                float cloudDensity = lerp(baseNoise , detailShapeNoise * _DetailNoiseWeight,0.1);

                float oneMinusShape = 1 - shapeNoise;
                float detailWeight = oneMinusShape * oneMinusShape * oneMinusShape;
                 cloudDensity = baseNoise  - (1-detailShapeNoise) * detailWeight * _DetailNoiseWeight;

                return cloudDensity * _DensityMultiplier;
            }

            // Calculate proportion of light that reaches the given point from the lightsource
            float lightmarch(float3 position) {
                float3 dirToLight = _MainLightPosition.xyz;
                float dstInsideBox = rayBoxDst(_BoundsMin, _BoundsMax, position, 1/dirToLight).y;
                
                float stepSize = dstInsideBox/_NumStepsLight;
                float totalDensity = 0;

                for (int step = 0; step < _NumStepsLight; step ++) {
                    position += dirToLight * stepSize;
                    totalDensity += max(0, sampleDensity(position) * stepSize);
                }

                float transmittance = exp(-totalDensity * _LightAbsorptionTowardSun);
                return lerp(transmittance,1,_DarknessThreshold);
            }

            float4 frag(v2f i):SV_TARGET{
                float2 screenUV = i.pos.xy / _ScaledScreenParams.xy;
                float3 rayPos = _WorldSpaceCameraPos;
                float viewLength = length(i.viewVector);
                float3 rayDir = i.viewVector / viewLength;

                // float3 rayDir = normalize(i.viewVector);
                float rawDepth = GetScreenDepth(screenUV);
                float depth = LinearEyeDepth(rawDepth);

                float2 boxDst = rayBoxDst(_BoundsMin,_BoundsMax,rayPos,1/rayDir);
                float dstToBox = boxDst.x;
                float dstInsideBox = boxDst.y;

                float3 entryPoint = rayPos + rayDir * dstToBox;
                float randomOffset = tex2Dlod(_BlueNoise,float4(squareUV(screenUV * 3),0,0)) * _RayOffsetStrength;

                float cosAngle = dot(rayDir,_MainLightPosition.xyz);
                float phaseVal = phase(cosAngle,_PhaseParams);

                float curDist = randomOffset;
                float maxDist = min(depth - dstToBox,dstInsideBox);
                const float stepSize = 11;

                float transmittance = 1;
                float3 lightEnergy = 0;

                while(curDist < maxDist){
                    rayPos = entryPoint + rayDir * curDist;
                    float density = sampleDensity(rayPos);
                    if(density > 0){
                        float lightTransmittance = lightmarch(rayPos);
                        lightEnergy += density * lightTransmittance * transmittance * stepSize * phaseVal;
                        transmittance *= exp(-density * stepSize * _LightAbsorptionThroughCloud);

                        if(transmittance < 0.01)
                            break;
                    }

                    curDist += stepSize;
                }
                float3 cloudCol = lightEnergy * _LightColor0;

                float heightRate = (entryPoint - _BoundsMin)/(_BoundsMax - _BoundsMin).y;
                float3 skyCol = lerp(_ColA,_ColB,saturate(1-lightEnergy));
                // return skyCol.xyzx;
                float fogRate = 1-exp(-dstInsideBox*0.001);
                cloudCol = lerp(cloudCol,skyCol,fogRate);
                
                // use alpha blend
                float alpha = saturate(0.8-transmittance);
                return float4(cloudCol,alpha);
            }
          
            float4 frag1 (v2f i) : SV_Target
            {
                float2 screenUV = i.pos.xy/_ScreenParams.xy;
                // Create ray
                float3 rayPos = _WorldSpaceCameraPos;

                float viewLength = length(i.viewVector);
                float3 rayDir = i.viewVector / viewLength;

                // Depth and cloud container intersection info:
                float nonlin_depth = GetScreenDepth(screenUV);
                float depth = LinearEyeDepth(nonlin_depth);
                
                float2 rayToContainerInfo = rayBoxDst(_BoundsMin, _BoundsMax, rayPos, 1/rayDir);
                float dstToBox = rayToContainerInfo.x;
                float dstInsideBox = rayToContainerInfo.y;

                // point of intersection with the cloud container
                float3 entryPoint = rayPos + rayDir * dstToBox;

                // random starting offset (makes low-res results noisy rather than jagged/glitchy, which is nicer)
                float randomOffset = tex2Dlod(_BlueNoise, float4(squareUV(screenUV*3),0, 0));
                randomOffset *= _RayOffsetStrength;
                
                // Phase function makes clouds brighter around sun
                float cosAngle = dot(rayDir, _MainLightPosition.xyz);
                float phaseVal = phase(cosAngle,_PhaseParams);

                float dstTravelled = randomOffset;
                float dstLimit = min(depth-dstToBox, dstInsideBox);
                const float stepSize = 11;
                // float stepSize = dstInsideBox/11;

                // March through volume:
                float transmittance = 1;
                float3 lightEnergy = 0;

                while (dstTravelled < dstLimit) {
                    rayPos = entryPoint + rayDir * dstTravelled;
                    float density = sampleDensity(rayPos);
                    
                    if (density > 0) {
                        float lightTransmittance = lightmarch(rayPos);
                        lightEnergy += density * stepSize * transmittance * lightTransmittance * phaseVal;
                        transmittance *= exp(-density * stepSize * _LightAbsorptionThroughCloud);
                    
                        // Exit early if T is close to zero as further samples won't affect the result much
                        if (transmittance < 0.01) {
                            break;
                        }
                    }
                    dstTravelled += stepSize;
                }

                float3 cloudCol = lightEnergy * _LightColor0;
                
                // use alpha blend
                float alpha = saturate(0.8-transmittance);
                return float4(cloudCol,alpha);
            }
ENDHLSL

    SubShader
    {
        
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
        blend srcAlpha oneMinusSrcAlpha
        Tags{"Queue"="Transparent"}

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}