Shader "Nature/BoxSceneFog"
{
    Properties
    {
        [GroupHeader(v0.0.1)]
        
        [Group(Base)]
        [GroupToggle(Base)]_FullScreenOn("_FullScreenOn",int) = 1

        [Group(SceneFog)]
        // [GroupItem(SceneFog)] _SceneFogMap("_SceneFogMap",2d)=""{}
        [GroupHeader(SceneFog,Main NoiseMap)]
        [GroupItem(SceneFog)] [NoScaleOffset] _FogMainNoiseMap("_FogMainNoiseMap",2d)=""{}
        [GroupItem(SceneFog)] _FogNoiseTilingOffset("_FogNoiseTilingOffset",vector) = (3,3,1,1)

        [GroupHeader(SceneFog,Detial NoiseMap)]
        [GroupItem(SceneFog)] [NoScaleOffset] _FogDetailNoiseMap("_FogDetailNoiseMap",2d)=""{}
        [GroupVectorSlider(SceneFog,layer1X layer1Y layer2X layer2Y,0_1 0_1 0_1 0_1 , Detail Noise Tiling,field)] _DetailFogTiling("_DetailFogTiling",vector) = (5,5,5,5)
        [GroupVectorSlider(SceneFog,layer1X layer1Y layer2X layer2Y,0_1 0_1 0_1 0_1 , Detail Noise Offset,field)] _DetailFogOffset("_DetailFogOffset",vector) = (1,1,1,1)
        
        
        // [GroupVectorSlider(HeightFog,rangeMin rangeMax,0_1 0_1)] _FogAreaScale("_FogAreaScale",vector) = (0,1,0,0)
        [GroupHeader(SceneFog,Others)]
        [GroupItem(SceneFog)] _SceneFogColor("_SceneFogColor",color) = (.5,.5,.5,.5)
        [GroupItem(SceneFog)] _WorldPosScale("_WorldPosScale",float) = 0.001

        [Group(HeightFog)]
        [GroupToggle(HeightFog)] _SceneHeightFogOn("_SceneHeightFogOn",float) = 1
        [GroupVectorSlider(HeightFog,min max,0_1 0_1,height fog range,field)] _HeightFogRange("_HeightFogRange",Vector) = (0,100,0,0)
        
        [GroupItem(HeightFog)]  _CameraFadeDist("_CameraFadeDist",float) = 10
// ================================================== stencil settings
        [Group(Stencil)]
        [GroupEnum(Stencil,UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 0
        [GroupItem(Stencil)]_Stencil ("Stencil ID", int) = 0
        [GroupEnum(Stencil,UnityEngine.Rendering.StencilOp)]_StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255        
//================================================= Blend
        // [Header(Blend)]
        // [Enum(UnityEngine.Rendering.BlendMode)]_SrcMode("_SrcMode",int) = 1
        // [Enum(UnityEngine.Rendering.BlendMode)]_DstMode("_DstMode",int) = 0

//================================================= settings
        [Group(Settings)]
        // [GroupToggle]_ZWriteMode("_ZWriteMode",int) = 1
        // [Enum(UnityEngine.Rendering.CompareFunction)]_ZTestMode("_ZTestMode",int) = 4
        [GroupEnum(Settings,UnityEngine.Rendering.CullMode)]_CullMode("_CullMode",int) = 0              
    }

HLSLINCLUDE
    #include "../../../PowerShaderLib/Lib/UnityLib.hlsl"
    #include "../../../PowerShaderLib/Lib/PowerUtils.hlsl"
    #include "../../../PowerShaderLib/Lib/SDF.hlsl"
    #include "../../../PowerShaderLib/Lib/NoiseLib.hlsl"
    #include "../../../PowerShaderLib/Lib/MathLib.hlsl"
    #include "../../../PowerShaderLib/URPLib/URP_Input.hlsl"

    sampler2D _SceneFogMap;
    sampler2D _FogMainNoiseMap,_FogDetailNoiseMap;

    sampler2D _HighlightTex;
    float4 _HighlightColor;

    CBUFFER_START(UnityPerMaterial)
    float _FullScreenOn;


    float3 _SceneMin;
    float3 _SceneMax;
    float4 _FogNoiseTilingOffset;
    float4 _DetailFogTiling,_DetailFogOffset;

    float _SceneHeightFogOn;
    // float _SceneHeightFogFading;
    float2 _HeightFogRange;

    float _CameraFadeDist;
    // float2 _FogAreaScale;
    float4 _SceneFogColor;
    float _WorldPosScale;
    CBUFFER_END

    float4 CalcFogFactor(float3 worldPos){
        float3 worldUV = worldPos * _WorldPosScale;

        float fogRate = 1; // sceneFog, dont need depth fog
        float heightFogRate = (_HeightFogRange.x - worldPos.y)/(_HeightFogRange.y-_HeightFogRange.x);
        fogRate *= heightFogRate;

        float4 sceneFogFactor = float4(worldUV,saturate(fogRate));

        // // --------- vertical linear fog
        float viewDist = abs(_WorldSpaceCameraPos.y - worldPos.y);

        float viewFade = lerp(0.1,1,viewDist / max(0.001,_CameraFadeDist));
        sceneFogFactor.w *= saturate(viewFade);

        return sceneFogFactor;
    }

    float4 CaclHighLight(float3 worldPos){
        // high light
        float4 highlightTex = tex2D(_HighlightTex,worldPos.xz);
        float highlight = abs(sin(_Time.y)) * highlightTex.x;
        return highlight * _HighlightColor;
    }

    float4 CalcFogColor(float3 worldUV){
        float4 noiseUV = worldUV.xzxy * _DetailFogTiling + _DetailFogOffset * _Time.xxxx;
        float2 noise = tex2D(_FogDetailNoiseMap,noiseUV.xy);
        noise += tex2D(_FogDetailNoiseMap,noiseUV.zw);

        // xz
        float2 mainOffset = _Time.xx * _FogNoiseTilingOffset.zw;
        float4 mainNoiseUV = worldUV.xzyz* _FogNoiseTilingOffset.xyxy + mainOffset.xyxy;

        float4 noiseMap = tex2D(_FogMainNoiseMap,mainNoiseUV.xy + noise *0.05);
        // noiseMap = (pow(noiseMap,5));
        return noiseMap * _SceneFogColor;
    }
ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100
        zwrite off
        ztest always
        cull [_CullMode]
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _CameraOpaqueTexture;
            sampler2D _CameraDepthTexture;



// #define _CameraDepthTexture _CameraDepthAttachment
// #define _CameraOpaqueTexture _CameraColorTexture

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = _FullScreenOn ? float4(v.vertex.xy * 2,0,1) : TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;
                float4 sceneColor = tex2D(_CameraOpaqueTexture,screenUV);

//============ world pos
                float depthTex = tex2D(_CameraDepthTexture,screenUV).x;
                float isFar = IsTooFar(depthTex.x);
                
                float3 worldPos = ScreenToWorldPos(screenUV,depthTex,UNITY_MATRIX_I_VP);
                // return worldPos.y>20;

                float4 worldUVfogFactor = CalcFogFactor(worldPos);
                float4 fogColor = CalcFogColor(worldUVfogFactor.xyz);
                return lerp(sceneColor,fogColor,worldUVfogFactor.w * (! isFar));
            }
            ENDHLSL
        }
    }
}
