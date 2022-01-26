Shader "Lit/pbr1_"
{
    /*
    lighting(pbr,charlie,aniso)
    shadow(main light)
    fog
    srp batched 

    instanced
    detail()
    alpha

    */
    Properties
    {
        [LineHeader(Main)]
        _MainTex ("Texture", 2D) = "white" {}
        
        _NormalMap("_NormalMap",2d)="bump"{}
        _NormalScale("_NormalScale",float) = 1

        [LineHeader(PBR Mask)]
        _PbrMask("_PbrMask",2d)="white"{}

        _Metallic("_Metallic",range(0,1)) = 0.5
        _Smoothness("_Smoothness",range(0,1)) = 0.5
        _Occlusion("_Occlusion",range(0,1)) = 0
            
        [LineHeader(Light Mode)]
        [Toggle]_SpecularOn("_SpecularOn",int) = 1
        // [Enum(PBR,0,Aniso,1,Charlie,2)]_PbrMode("_PbrMode",int) = 0
        [KeywordEnum(PBR,Aniso,Charlie)]_PbrMode("_PbrMode",int) = 0

        [Header(Aniso)]
        [Toggle]_CalcTangent("_CalcTangent",int) = 0
        _AnisoRough("_AnisoRough",range(-0.5,0.5)) = 0
        _AnisoShift("_AnisoShift",float) = 0
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
            #pragma target 3.0
            // #pragma multi_compile_fog
            #pragma multi_compile _PBRMODE_PBR _PBRMODE_ANISO _PBRMODE_CHARLIE
            #include "Lib/PBRForwardPass.hlsl"
            
            ENDHLSL
        }

        Pass{
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            
            #define SHADOW_PASS 
            #include "Lib/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass{
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag 

            #include "Lib/ShadowCasterPass.hlsl"

            ENDHLSL
        }
    }
}
