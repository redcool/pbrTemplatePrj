Shader "Template/Unlit"
{
    Properties
    {
        _TexA ("Texture", 2D) = "white" {}
        _TexB("_TexB",2d) = ""{}
    }

HLSLINCLUDE
 #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "../PowerXXX/PowerShaderLib/Lib/MathLib.hlsl"

#define WHITEPOINT_X 0.950456
#define WHITEPOINT_Y 1.0
#define WHITEPOINT_Z 1.088754
#define WHITEPOINT float3(0.950456,1,1.088754)
#define MIN3(A,B,C) (((A) <= (B)) ? min(A,C) : min(B,C))

#define INVGAMMACORRECTION(t) (((t) <= 0.0404482362771076)? ((t)/12.92) : pow(((t) + 0.055)/1.055, 2.4))
#define GAMMACORRECTION(t) (((t) <= 0.0031306684425005883) ? (12.92*(t)) : (1.055*pow((t), 0.416666666666666667) - 0.055))
#define LABF(t) ((t >= 8.85645167903563082e-3) ? pow(t,0.333333333333333) : (841.0/108.0)*(t) + (4.0/29.0))
#define LABINVF(t) ((t >= 0.206896551724137931) ? ((t)*(t)*(t)) : (108.0/841.0)*((t) - (4.0/29.0)))

#define MIN3(A,B,C) (((A) <= (B)) ? min(A,C) : min(B,C))
#define MAX3(A,B,C) (((A) >= (B)) ? max(A,C) : max(B,C))
#define Rad2Deg 57.295779
#define Deg2Rad 0.0174533

float3 RgbToXyz(float3 rgb){
    static float3x3 XYZ = float3x3(
        0.4123955889674142161,0.3575834307637148171,0.1804926473817015735,
        0.2125862307855955516,0.7151703037034108499,0.07220049864333622685,
        0.01929721549174694484,0.1191838645808485318,0.9504971251315797660
    );
    
    return mul(XYZ,rgb);
}

float3 XyzToRgb(float3 xyz){
    static float3x3 RGB = float3x3(
        3.2406, - 1.5372, - 0.4986,
        -0.9689, 1.8758, 0.0415,
        0.0557, - 0.2040, 1.0570
    );
    xyz = mul(RGB,xyz);

    float m = MIN3(xyz.x,xyz.y,xyz.z);
    xyz *= lerp(1,-1,(m <0));
    return saturate(xyz);
}

float3 XyzToLab(float3 xyz){
    xyz /= WHITEPOINT;
    xyz = float3(LABF(xyz.x),LABF(xyz.y),LABF(xyz.z));
    return float3(116*xyz.y-16,500*(xyz.x-xyz.y),200*(xyz.y - xyz.z));
}
float3 LabToXyz(float3 lab){
    float l = (lab.x+16)/116;
    float a = l + lab.y/500;
    float b = l - lab.z*200;
    return float3(LABINVF(a),LABINVF(l),LABINVF(b)) * WHITEPOINT;
}

float3 XyzToLch(float3 xyz){
    float3 lab = XyzToLab(xyz);
    float c = sqrt(dot(lab.yz,lab.yz));
    float h = atan2(lab.z,lab.y)* Rad2Deg;
    h += 360*(h<0);
    return float3(lab.x,c,h);
}

float3 LchToXyz(float3 lch){
    float a = lch.y * cos(lch.z * Deg2Rad);
    float b = lch.y * sin(lch.z * Deg2Rad);
    return LabToXyz(float3(lch.x,a,b));
}

float3 RgbToLch(float3 rgb){
    return XyzToLch(RgbToXyz(rgb));
}



float3 LchToRgb(float3 lch){
    return XyzToRgb(LchToXyz(lch));
}



ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

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

            sampler2D _TexA;
            sampler2D _TexB;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                // v.vertex.xy *= 2;
                // o.vertex = v.vertex;
                o.uv = v.uv;
                return o;
            }

            float3 BlendHue(float3 a,float3 b){
                // a = pow(a,.45);
                // b = pow(b,.45);
                
// return XyzToLab(LabToXyz(a));
                a = RgbToLch(a);
                b = RgbToLch(b);
                a = float3(a.x,b.yz);
                return LchToRgb(a);
                return 0;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 colA = tex2D(_TexA, i.uv);
                float4 colB = tex2D(_TexB,i.uv);

                float3 col = BlendHue(colA.xyz,colB.xyz);
                return col.xyzx;
            }
            ENDHLSL
        }
    }
}
