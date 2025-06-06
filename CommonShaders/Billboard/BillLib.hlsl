#if !defined(BILL_LIB_HLSL)
#define BILL_LIB_HLSL
    #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
    #include "../../../PowerShaderLib/UrpLib/URP_GI.hlsl"
    #include "../../../PowerShaderLib/Lib/BillboardLib.hlsl"
    #include "../../../PowerShaderLib/Lib/NatureLib.hlsl"
    #include "../../../PowerShaderLib/Lib/MaterialLib.hlsl"

    #include "../../../PowerShaderLib/Lib/MatCapLib.hlsl"
    #include "../../../PowerShaderLib/URPLib/URP_MotionVectors.hlsl"
    #include "../../../PowerShaderLib/URPLib/Lighting.hlsl"
    
    // nothing
    // #if defined(INSTANCING_ON)
        // #define UnityPerMaterial _UnityPerMaterial
    // #endif

    // define variables
    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
        UNITY_DEFINE_INSTANCED_PROP(half4,_MainTex_ST)
        UNITY_DEFINE_INSTANCED_PROP(half4,_Color)
        
        // UNITY_DEFINE_INSTANCED_PROP(float,_FullFaceCamera)
        UNITY_DEFINE_INSTANCED_PROP(half,_Cutoff)
        UNITY_DEFINE_INSTANCED_PROP(half,_RotateShadow)

        UNITY_DEFINE_INSTANCED_PROP(half,_WindOn)
        UNITY_DEFINE_INSTANCED_PROP(half4,_WindAnimParam)
        UNITY_DEFINE_INSTANCED_PROP(half4,_WindDir)
        UNITY_DEFINE_INSTANCED_PROP(half,_WindSpeed)
        // UNITY_DEFINE_INSTANCED_PROP(half,_ApplyMainLightColor)

        UNITY_DEFINE_INSTANCED_PROP(half,_SnowIntensity)
        UNITY_DEFINE_INSTANCED_PROP(half2,_SnowNoiseTiling)
        
        UNITY_DEFINE_INSTANCED_PROP(half,_ApplyEdgeOn)
        UNITY_DEFINE_INSTANCED_PROP(half,_SnowIntensityUseMainTexA)

        UNITY_DEFINE_INSTANCED_PROP(half,_FogOn)
        UNITY_DEFINE_INSTANCED_PROP(half,_FogNoiseOn)
        UNITY_DEFINE_INSTANCED_PROP(half,_DepthFogOn)
        UNITY_DEFINE_INSTANCED_PROP(half,_HeightFogOn)

        UNITY_DEFINE_INSTANCED_PROP(half2,_DiffuseRange)
        
        UNITY_DEFINE_INSTANCED_PROP(half4,_MatCap_ST)
        UNITY_DEFINE_INSTANCED_PROP(half,_MatCapScale)
        UNITY_DEFINE_INSTANCED_PROP(half,_Metallic)

        UNITY_DEFINE_INSTANCED_PROP(half,_TopdownLine)
        UNITY_DEFINE_INSTANCED_PROP(half,_DiffuseBlend)
        
    //---------Cloud shadows
        // UNITY_DEFINE_INSTANCED_PROP(half,_CloudShadowOn)
        // UNITY_DEFINE_INSTANCED_PROP(half4,_CloudNoiseTilingOffset)
        // UNITY_DEFINE_INSTANCED_PROP(half,_CloudNoiseRangeMin)
        // UNITY_DEFINE_INSTANCED_PROP(half,_CloudNoiseRangeMax)
        // UNITY_DEFINE_INSTANCED_PROP(half,_CloudNoiseOffsetStop)
        // UNITY_DEFINE_INSTANCED_PROP(half4,_CloudShadowColor)
        // UNITY_DEFINE_INSTANCED_PROP(half,_CloudBaseShadowIntensity)
        // UNITY_DEFINE_INSTANCED_PROP(half,_CloudShadowIntensity)

    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

    // define shortcot getters
    #define _MainTex_ST UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_MainTex_ST)
    #define _Color UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Color)
    #define _FullFaceCamera UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_FullFaceCamera)
    #define _Cutoff UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Cutoff)
    #define _RotateShadow UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_RotateShadow)

    #define _WindOn UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_WindOn)
    #define _WindAnimParam UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_WindAnimParam)
    #define _WindDir UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_WindDir)
    #define _WindSpeed UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_WindSpeed)
    #define _ApplyMainLightColor UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_ApplyMainLightColor)

    #define _SnowIntensity UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_SnowIntensity)
    #define _SnowNoiseTiling UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_SnowNoiseTiling)
    
    #define _ApplyEdgeOn UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_ApplyEdgeOn)
    #define _SnowIntensityUseMainTexA UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_SnowIntensityUseMainTexA)

    #define _FogOn UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_FogOn)
    #define _FogNoiseOn UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_FogNoiseOn)
    #define _DepthFogOn UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_DepthFogOn)
    #define _HeightFogOn UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_HeightFogOn)
    #define _DiffuseRange UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_DiffuseRange)

    #define _MatCap_ST UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_MatCap_ST)
    #define _MatCapScale UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_MatCapScale)
    #define _Metallic UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Metallic)
    #define _TopdownLine UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_TopdownLine)
    #define _DiffuseBlend UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_DiffuseBlend)
    // cloud shadow
    #define _DiffuseBlend UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_DiffuseBlend)
    #define _CloudNoiseTilingOffset UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_CloudNoiseTilingOffset)
    #define _CloudNoiseRangeMin UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_CloudNoiseRangeMin)
    #define _CloudNoiseRangeMax UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_CloudNoiseRangeMax)
    #define _CloudNoiseOffsetStop UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_CloudNoiseOffsetStop)
    #define _CloudShadowColor UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_CloudShadowColor)
    #define _CloudBaseShadowIntensity UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_CloudBaseShadowIntensity)
    #define _CloudShadowIntensity UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_CloudShadowIntensity)
    

        // half _CloudShadowOn;
    // half4 _CloudNoiseTilingOffset;
    // half _CloudNoiseRangeMin;
    // half _CloudNoiseRangeMax;
    // half _CloudNoiseOffsetStop;

    // half4 _CloudShadowColor;
    // half _CloudBaseShadowIntensity;
    // half _CloudShadowIntensity;

    // _FogOn,need define first
    #include "../../../PowerShaderLib/Lib/FogLib.hlsl"

    half _DrawChildrenStaticOn;

    struct appdata
    {
        float4 vertex : POSITION;
        float3 normal:NORMAL;
        float4 color:COLOR;
        float2 uv : TEXCOORD0;
        float2 uv1:TEXCOORD1;
        DECLARE_MOTION_VS_INPUT(prevPos);
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct v2f
    {
        float4 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
        float3 normal:TEXCOORD1;
        float4 worldPos:TEXCOORD2;
        float4 fogCoord:TEXCOORD3;
        float3 vertexNormal:TEXCOORD4;
        // motion vectors
        DECLARE_MOTION_VS_OUTPUT(6,7);
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    sampler2D _MainTex;
    TEXTURE2D(_MatCap);SAMPLER(sampler_MatCap);

    float4x4 _CameraYRot;

    v2f vertBill (appdata v)
    {
        v2f o = (v2f)0;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_TRANSFER_INSTANCE_ID(v, o);

        v.vertex.xyz = mul(_CameraYRot,v.vertex).xyz;
        float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
        float3 n = v.vertex.xyz;
        o.normal = n;

        #if defined(_WIND_ON)
        branch_if(IsWindOn())
        {
            float4 attenParam = v.color.x;
            float3 posAtten = v.vertex.xyz ;
            posAtten *= lerp(1,0.1,_DrawChildrenStaticOn);

            worldPos = WindAnimationVertex(worldPos,posAtten.xyz,n,attenParam * _WindAnimParam, _WindDir,_WindSpeed).xyz;
        }
        #endif
        #if defined(_FACE_CAMERA)
        o.vertex = TransformBillboardObjectToHClip(v.vertex ,1);
        #else
        o.vertex = TransformWorldToHClip(worldPos);
        #endif        

        o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
        o.uv.zw = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;

        o.worldPos.xyz = worldPos;
        o.fogCoord.xy = CalcFogFactor(worldPos.xyz,o.vertex.z,_HeightFogOn,_DepthFogOn);
        o.vertexNormal = (v.normal);

        CALC_MOTION_POSITIONS_WORLD((v.prevPos.xyz),worldPos,o,o.vertex);

        return o;
    }

    float4 fragBill (v2f i,out float4 outputNormal:SV_TARGET1,out float4 outputMotionVectors:SV_TARGET2) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(i);

        float2 mainUV = i.uv.xy;
        float2 lightmapUV = i.uv.zw;
        float3 worldPos = i.worldPos;

        // float3 n = CalcSphereWorldNormal(unity_ObjectToWorld,i.worldPos);
        float3 localPos = i.normal;
        float3 n = normalize(localPos);

        // sample the texture
        float4 mainTex = tex2D(_MainTex, mainUV) * _Color;

        float3 albedo = mainTex.xyz;
        float alpha = mainTex.w;

        #if defined(_SNOW_ON)
        branch_if(IsSnowOn())
        {
            float3 startPos = unity_ObjectToWorld._14_24_34 + i.normal;
            float3 snowColor = CalcNoiseSnowColor(albedo,1,startPos.xzy,float4(_SnowNoiseTiling.xy,0,0));
            // return float4(snowColor,1);
            half snowAtten = (_SnowIntensityUseMainTexA ? alpha : 1) * _SnowIntensity;            
            albedo = MixSnow(albedo,snowColor,snowAtten,n,_ApplyEdgeOn);
        }
        #endif

        #if defined(ALPHA_TEST)
            clip(alpha - _Cutoff);
        #endif
        
        //-------- output mrt
        // output world normal
        outputNormal = half4(n.xyz,0);
        // output motion
        outputMotionVectors = CALC_MOTION_VECTORS(i);        

        // =========== gi 
        half3 giDiff = CalcGIDiff(n,albedo,lightmapUV);
        half3 col = giDiff;

        //  =========== shadow
        float4 shadowCoord = TransformWorldToShadowCoord(worldPos);
        Light mainLight = GetMainLight(shadowCoord,worldPos,1,1);

        // =========== direct light (nl)
        float topdownRate = saturate(localPos.y - _TopdownLine.x);

        half nl = saturate(dot(n,mainLight.direction) * mainLight.shadowAttenuation);
        nl = lerp(nl,topdownRate,_DiffuseBlend);
        nl = saturate(smoothstep(_DiffuseRange.x,_DiffuseRange.y,nl) + 0);
        // return nl;

        // code control
        nl =lerp(nl,1,_DrawChildrenStaticOn);

        half3 radiance = mainLight.color * nl;

        half3 diffCol = albedo * (1- _Metallic);
        half3 specCol = lerp(0.04,albedo,_Metallic);

        // =========== specular
        // float3 n1 = normalize(cross( ddy(i.worldPos) , ddx(i.worldPos) ));
        float4 matCap = SampleMatCap(_MatCap,sampler_MatCap,i.vertexNormal,_MatCap_ST,0);
        float3 specTerm = matCap.xyz * _MatCapScale;

        half3 directColor = (diffCol + specCol * specTerm) * radiance;
        col += directColor;

        // branch_if(_CloudShadowOn)
        // {
        //     half3 cloudNoise = CalcCloudShadow(TEXTURE2D_ARGS(_WeatherNoiseTexture,sampler_WeatherNoiseTexture),worldPos,_CloudNoiseTilingOffset,_CloudNoiseOffsetStop,
        //     _CloudNoiseRangeMin,_CloudNoiseRangeMax,_CloudShadowColor,_CloudShadowIntensity,_CloudBaseShadowIntensity);
        //     col.xyz *= lerp(1,cloudNoise,nl);
        //     // return cloudNoise.xyzx;
        // }
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
        return float4(col,alpha);
    }
#endif //BILL_LIB_HLSL