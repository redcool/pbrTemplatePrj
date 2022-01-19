#if !defined(PBR_FORWARD_PASS_HLSL)
#define PBR_FORWARD_PASS_HLSL
#include "Lib/Core/CommonUtils.hlsl"
#include "Lib/Core/TangentLib.hlsl"
#include "Lib/Core/BSDF.hlsl"
#include "Lib/Core/Fog.hlsl"
#include "Lib/PBRInput.hlsl"
#include "Lib/URP_MainLightShadows.hlsl"


struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal:NORMAL;
    float4 tangent:TANGENT;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    TANGENT_SPACE_DECLARE(1,2,3);
    float4 shadowCoord:TEXCOORD4;
    float4 fogFactor:TEXCOORD5;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

v2f vert (appdata v)
{
    v2f o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v,o);

    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    TANGENT_SPACE_COMBINE(v.vertex,v.normal,v.tangent,o/**/);
    o.shadowCoord = TransformWorldToShadowCoord(p);
    o.fogFactor.x = ComputeFogFactor(o.vertex.z);


    return o;
}

float4 frag (v2f i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);

    TANGENT_SPACE_SPLIT(i);
    float2 mainUV = i.uv;

    float4 pbrMask = tex2D(_PbrMask,mainUV);
    float metallic = pbrMask.r * _Metallic;
    float smoothness = pbrMask.g * _Smoothness;
    float occlusion = lerp(1,pbrMask.b,_Occlusion);
    float roughness = 1 - smoothness;

    float3 tn = UnpackScaleNormal(tex2D(_NormalMap,mainUV),_NormalScale);
    float3 n = normalize(TangentToWorld(i.tSpace0,i.tSpace1,i.tSpace2,tn));

    float3 l = (_MainLightPosition.xyz);
    float3 v = normalize(UnityWorldSpaceViewDir(worldPos));
    float3 h = normalize(l+v);
    
    float lh = saturate(dot(l,h));
    float nh = saturate(dot(n,h));
    float nl = saturate(dot(n,l));
    float a = max(roughness * roughness, HALF_MIN_SQRT);
    float a2 = max(a * a ,HALF_MIN);

    float nv = saturate(dot(n,v));
// return v.xyzx;


    float shadowAtten = CalcShadow(i.shadowCoord,worldPos);
    // return shadowAtten;
//--------- lighting
    float4 albedo = tex2D(_MainTex, mainUV);
    float radiance = _MainLightColor * nl * shadowAtten;
    
    float specTerm = 0;

    if(_SpecularOn){
        // if(_PbrMode == 0){
        #if defined(_PBRMODE_PBR)
            specTerm = MinimalistCookTorrance(nh,lh,a,a2);
            // specTerm = D_GGXNoPI(nh,a2);
        // }else if(_PbrMode == 1){
        #elif defined(_PBRMODE_ANISO)
            float3 t = vertexTangent;//(cross(n,float3(0,1,0)));
            float3 b = vertexBinormal;//cross(t,n);
            if(_CalcTangent){
                t = cross(n,float3(0,1,0));
                b = cross(t,n);
            }
            float th = dot(t,h);
            float bh = dot(b,h);
            float anisoRough = _AnisoRough + 0.5;
            specTerm = D_GGXAnisoNoPI(th,bh,nh,anisoRough,1 - anisoRough);
        #elif defined(_PBRMODE_CHARLIE)
        // }else if(_PbrMode == 2){
            specTerm = D_CharlieNoPI(nh, roughness);
        // }
        #endif
    }

    float3 specColor = lerp(0.04,albedo,metallic);
    
    float3 diffColor = albedo.xyz * (1- metallic);
    float3 directColor = (diffColor + specColor * specTerm) * radiance;
// return directColor.xyzx;
//------- gi
    float3 giColor = 0;
    float3 giDiff = ShadeSH9(float4(n,1)) * diffColor;

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

    float4 col = 1;
    col.rgb = directColor + giColor;
//------ fog
    col.rgb = MixFog(col.xyz,i.fogFactor.x);
    return col;
}

#endif //PBR_FORWARD_PASS_HLSL