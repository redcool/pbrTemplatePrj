Shader "FX/Box/BoxDecal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [GroupToggle]_BoxUpClip("_BoxUpClip",int) = 0

        [Group(Noise)]
        [GroupToggle(Noise,_NOISE_ON)]_NoiseOn("_NoiseOn",float) = 0
        [GroupVectorSlider(Noise,scaleX scaleY offsetX offsetY,m1_1 m1_1 0_10 0_10,noise generato,float)]
        _NoiseScaleOffset("_NoiseScaleOffset",vector) = (1,1,0,0)

        [GroupItem(Noise)]_NoiseIntensity("_NoiseIntensity",range(0,4)) = 0.2
        [GroupItem(Noise)]_NoiseColor("_NoiseColor",color) = (1,1,1,1)
//=================================================  weather
        [Group(Fog)]
        [GroupToggle(Fog)]_FogOn("_FogOn",int) = 1
        // [GroupToggle(Fog,SIMPLE_FOG,use simple linear depth height fog)]_SimpleFog("_SimpleFog",int) = 0
        [GroupToggle(Fog)]_FogNoiseOn("_FogNoiseOn",int) = 0
        [GroupToggle(Fog)]_DepthFogOn("_DepthFogOn",int) = 1
        [GroupToggle(Fog)]_HeightFogOn("_HeightFogOn",int) = 1

    }
    HLSLINCLUDE
        #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
        #include "../../../PowerShaderLib/URPLib/URP_Fog.hlsl"
        #include "../../../PowerShaderLib/Lib/ScreenTextures.hlsl"
        #include "../../../PowerShaderLib/Lib/NatureLib.hlsl"
        #include "../../../PowerShaderLib/Lib/Common/Randoms.hlsl"

        /**
            Decal in Box
            
            cube bounds is [-.5,.5]
            depth : [0, far]
            camPos : world space camera pos
            ray : camera's direction point to vertex
            return : xyz : cube space pos, w : is in box
        */
        float4 GetObjectPosFromDepth(float depth,float3 ray,bool isBoxUpClip,float3 boxWorldUp,out float boxUp){
            float3 camForward = -UNITY_MATRIX_V[2].xyz;
            ray /= dot(ray,camForward);

            float3 worldPos = _WorldSpaceCameraPos + ray * depth;
            float3 objPos = mul(unity_WorldToObject,float4(worldPos,1));
            
            // box clip
            float3 inBox = .5 - abs(objPos); 
            float a = min(min(inBox.x,inBox.y),inBox.z);

            // box up filter clip
            float3 up = ddy(worldPos);
            float3 right = ddx(worldPos);
            float3 n = normalize(cross(up,right));
            boxUp = saturate(dot(n,boxWorldUp)+0.2);

            a *=  isBoxUpClip ? boxUp : 1;

            return float4(objPos+0.5,a);
        }

    ENDHLSL
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100

        zwrite off
        blend srcAlpha oneMinusSrcAlpha
        cull front
        ztest always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            // #pragma shader_feature ALPHA_TEST
            #pragma shader_feature _NOISE_ON

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 fogCoord : TEXCOORD1;
                float3 ray:TEXCOORD02;
                float4 screenPos:TEXCOORD3;
                float3 boxWorldUp:TEXCOORD4;
                float3 worldPos : TEXCOORD5;
            };

            sampler2D _MainTex;
            
            float4 _MainTex_ST;
            float4 _CameraDepthTexture_TexelSize;

            CBUFFER_START(UnityPerMaterial)
            int _BoxUpClip;
            half _FogOn;
            half _FogNoiseOn;
            half _DepthFogOn;
            half _HeightFogOn;
            half4 _NoiseScaleOffset;
            half _NoiseIntensity;
            half4 _NoiseColor;
            CBUFFER_END

            // _FogOn,need define first
            #include "../../../PowerShaderLib/Lib/FogLib.hlsl"

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.ray = worldPos - _WorldSpaceCameraPos;
                o.boxWorldUp = mul(unity_ObjectToWorld,float3(0,1,0));
                o.fogCoord = CalcFogFactor(worldPos.xyz,o.vertex.z,_HeightFogOn,_DepthFogOn);
                o.worldPos = worldPos;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertex.xy/_ScaledScreenParams.xy;
                float3 ray = normalize(i.ray);

                float depth = GetScreenDepth(screenUV);
                // float depth01 = Linear01Depth(depth);
                float eyeDepth = LinearEyeDepth(depth);
                
                float isBoxUp;
                float4 objPos = GetObjectPosFromDepth(eyeDepth,ray,_BoxUpClip,i.boxWorldUp,isBoxUp/**/);


                // sample the texture
                half4 col = tex2D(_MainTex, objPos.xz);
                float isInBox = smoothstep(0,0.1,objPos.w);

                // #if defined(ALPHA_TEST)
                // clip(isInBox);
                // #endif

                // noise pcg
                float2 noise = 0;
                float3 screenCol = 0;
                #if defined(_NOISE_ON)
                    noise = GetNoise(pcg2d(i.vertex.xy* _NoiseScaleOffset.xy + _Time.zz* _NoiseScaleOffset.zw) ) * _NoiseIntensity;
                    screenCol = GetScreenColor(screenUV + noise) * _NoiseColor;
                #endif
                // update with noise
                col.xyz += screenCol *(!isInBox);
                col.w *= max(0.2*noise,isInBox);

                // =========== fog
                float fogNoise = 0;
                #if defined(_DEPTH_FOG_NOISE_ON)
                branch_if(_FogNoiseOn)
                {
                    half4 weights=float4(1,.1,.1,1);
                    fogNoise = CalcWorldNoise(i.worldPos,_FogNoiseTilingOffset,-_GlobalWindDir,weights);
                }
                #endif

                BlendFogSphereKeyword(col.rgb/**/,i.worldPos.xyz,i.fogCoord.xy,_HeightFogOn,fogNoise,_DepthFogOn); // 2fps


                return col;
            }
            ENDHLSL
        }
    }
}
