#if !defined(SHADER_FLOW_PASS_VERSION1)
#define SHADER_FLOW_PASS_VERSION1
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
float4 _Color;

v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv;
    return o;
}

half4 frag (v2f i) : SV_Target
{
    return _Color;
}
#endif //SHADER_FLOW_PASS_VERSION1