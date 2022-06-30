#if !defined(PBR_FORWARD_PASS_HLSL)
#define PBR_FORWARD_PASS_HLSL
#include "Core/Common.hlsl"
#include "Core/TangentLib.hlsl"
#include "Core/BSDF.hlsl"
#include "Core/Fog.hlsl"
#include "PBRInput.hlsl"

#include "Core/URPLib/Lighting.hlsl"


struct appdata
{
    half4 vertex : POSITION;
    half2 uv : TEXCOORD0;
    half2 uv1:TEXCOORD1;
    half3 normal:NORMAL;
    half4 tangent:TANGENT;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    half4 uv : TEXCOORD0; // mainUV,lightmapUV
    half4 vertex : SV_POSITION;
    TANGENT_SPACE_DECLARE(1,2,3);
    half4 shadowCoord:TEXCOORD4;
    half4 fogFactor:TEXCOORD5;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

v2f vert (appdata v)
{
    v2f o = (v2f)0;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v,o);

    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    o.uv.zw = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;

    TANGENT_SPACE_COMBINE(v.vertex,v.normal,v.tangent,o/**/);
    o.shadowCoord = TransformWorldToShadowCoord(worldPos);
    o.fogFactor.x = ComputeFogFactor(o.vertex.z);


    return o;
}

half4 frag (v2f i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);

    TANGENT_SPACE_SPLIT(i);
    half2 mainUV = i.uv.xy;

    half4 pbrMask = tex2D(_PbrMask,mainUV);
    half metallic = pbrMask.r * _Metallic;
    half smoothness = pbrMask.g * _Smoothness;
    half occlusion = lerp(1,pbrMask.b,_Occlusion);
    half roughness = 1 - smoothness;

    half3 tn = UnpackScaleNormal(tex2D(_NormalMap,mainUV),_NormalScale);
    half3 n = normalize(TangentToWorld(i.tSpace0,i.tSpace1,i.tSpace2,tn));

    half3 l = (_MainLightPosition.xyz);
    half3 v = normalize(UnityWorldSpaceViewDir(worldPos));
    half3 h = normalize(l+v);
    
    half lh = saturate(dot(l,h));
    half nh = saturate(dot(n,h));
    half nl = saturate(dot(n,l));
    half a = max(roughness * roughness, HALF_MIN_SQRT);
    half a2 = max(a * a ,HALF_MIN);

    half nv = saturate(dot(n,v));
// return v.xyzx;

    half4 shadowMask = SampleShadowMask(i.uv.zw);
    // return shadowMask;
    half shadowAtten = CalcShadow(i.shadowCoord,worldPos,shadowMask,_ReceiveShadow,_MainLightShadowSoftScale);
    // return shadowAtten;
//--------- lighting
    half4 mainTex = tex2D(_MainTex, mainUV) * _Color;
    half3 albedo = mainTex.xyz;
    half alpha = mainTex.w;

    half3 radiance = _MainLightColor.xyz * nl * shadowAtten;
    
    half specTerm = 0;

    if(_SpecularOn){
        // if(_PbrMode == 0){
        #if defined(_PBRMODE_PBR)
            specTerm = MinimalistCookTorrance(nh,lh,a,a2);
            // specTerm = D_GGXNoPI(nh,a2);
        // }else if(_PbrMode == 1){
        #elif defined(_PBRMODE_ANISO)
            half3 t = vertexTangent;//(cross(n,half3(0,1,0)));
            half3 b = vertexBinormal;//cross(t,n);
            if(_CalcTangent){
                t = cross(n,half3(0,1,0));
                b = cross(t,n);
            }
            b += n * _AnisoShift;
            
            half th = dot(t,h);
            half bh = dot(b,h);
            half anisoRough = _AnisoRough + 0.5;
            specTerm = D_GGXAnisoNoPI(th,bh,nh,anisoRough,1 - anisoRough);
        #elif defined(_PBRMODE_CHARLIE)
        // }else if(_PbrMode == 2){
            specTerm = D_CharlieNoPI(nh, roughness);
        // }
        #endif
    }

    half3 specColor = lerp(0.04,albedo,metallic);

    if(_TFOn){
        half3 thinFilm = ThinFilm(1- nv,_TFScale,_TFOffset,_TFSaturate,_TFBrightness);
        specColor = (specColor+1) * thinFilm;
    }
    
    half3 diffColor = albedo.xyz * (1- metallic);
    half3 directColor = (diffColor + specColor * specTerm) * radiance;
// return directColor.xyzx;
//------- gi
    half3 giColor = 0;
    half3 giDiff = 0;

    #if defined(LIGHTMAP_ON)
        giDiff = SampleLightmap(i.uv.zw) * diffColor;
    #else
        giDiff = ShadeSH9(half4(n,1)) * diffColor;
    #endif

    half mip = roughness * (1.7 - roughness * 0.7) * 6;
    half3 reflectDir = reflect(-v,n);
    half4 envColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0,reflectDir,mip);
    envColor.xyz = DecodeHDR(envColor,unity_SpecCube0_HDR);

    half surfaceReduction = 1/(a2+1);
    
    half grazingTerm = saturate(smoothness + metallic);
    half fresnelTerm = Pow4(1-nv);
    half3 giSpec = surfaceReduction * envColor.xyz * lerp(specColor,grazingTerm,fresnelTerm);
    giColor = (giDiff + giSpec) * occlusion;
// return giColor.xyzx;

    half4 col = 1;
    col.rgb = directColor + giColor;
    #if defined(_ADDITIONAL_LIGHTS_ON)
    col.xyz += CalcAdditionalLights(worldPos,diffColor,specColor,n,v,a,a2,0,0,shadowMask);
    #endif
//------ fog
    col.rgb = MixFog(col.xyz,i.fogFactor.x);
    col.a = alpha;
    return col;
}

#endif //PBR_FORWARD_PASS_HLSL