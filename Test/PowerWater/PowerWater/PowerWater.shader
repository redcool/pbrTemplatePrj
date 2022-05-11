Shader "URP/PowerOcean"
{
    Properties
    {
        [Header(Fresnel Color)]
        _Color1("_Color1",color) = (.3,.3,.3,1)
        _Color2("_Color2",color) = (1,1,1,1)

        [Header(Main)]
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Normal)]
        [NoScaleOffset]_NormalMap("_NormalMap",2d) = "bump"{}
        _NormalScale("_NormalScale",float) = .3
        _NormalSpeed("_NormalSpeed",float) = 1
        _NormalTiling("_NormalTiling",float) = 1

        [Header(Wave)]
        _WaveTiling("_WaveTiling",vector) = (0.1,1,0,0)
        _WaveDir("_WaveDir",vector) = (-1,0,0,0)
        _WaveScale("_WaveScale",float) = 1
        _WaveSpeed("_WaveSpeed",float) = 1
        _WaveStrength("_WaveStrength",float) = 1

        [Header(PBR Mask)]
        _PBRMask("_PBRMask(Metallic:R,Smoothness:G,Occlusion:B)",2d)="white"{}
        _Metallic("_Metallic",range(0,1)) = 0.5
        _Smoothness("_Smoothness",range(0,1)) = 0.5
        _Occlusion("_Occlusion",range(0,1)) = 0

        [Header(Depth)]
        _Depth("_Depth",float) = 1
        _DepthColor("_DepthColor",color) = (.2,.2,.2,1)
        _ShallowColor("_ShallowColor",color) = (1,1,1,1)

        [Header(Refraction)]
        _RefractionIntensity("_RefractionIntensity",float) = 1

        [Header(Foam)]
        _FoamTex("_FoamTex",2d) = ""{}
        _FoamDepthMin("_FoamDepthMin",range(0,1)) = 0
        _FoamDepthMax("_FoamDepthMax",range(0,1)) = 1
        _FoamSpeed("_FoamSpeed",float) = 1

        [Header(Caustics)]
        _CausticsIntensity("_CausticsIntensity",range(0,1)) = 1
        _CausticsSpeed("_CausticsSpeed",float) = 1
        _CausticsTiling("_CausticsTiling",float) = 1
    }
    SubShader
    {
        Tags{"Queue"="Transparent"}
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION


            // #define _REFLECTION_PROBE_BLENDING
            // #define _REFLECTION_PROBE_BOX_PROJECTION
            #include "PowerWaterForwardPass.hlsl"

            
            ENDHLSL
        }
    }
}
