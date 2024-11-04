#include "UnityLightingCommon.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

// struct appdata
// {
//     float4 vertex : POSITION;
//     float2 uv : TEXCOORD0;
//     float3 normal : NORMAL;
// };

struct v2f
{
    // fixed4 diff : COLOR0;
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float2 uv2 : TEXCOORD1;
    float4 worldPos : TEXCOORD2;
    float4 localPos : TEXCOORD3;
    float3 worldNormal : TEXCROOD4;
    half3 tspace0 : TEXCOORD5; // tangent.x, bitangent.x, normal.x
    half3 tspace1 : TEXCOORD6; // tangent.y, bitangent.y, normal.y
    half3 tspace2 : TEXCOORD7; // tangent.z, bitangent.z, normal.z
    LIGHTING_COORDS(8, 9)
    // V2F_SHADOW_CASTER;
    // float4 tangent : TANGENT;
};

sampler2D _BaseMap;
float4 _BaseMap_ST;

sampler2D _BumpMap;
float4 _BumpMap_ST;

void offsetLocalPosition (inout appdata_full v, in float4 offset)
{
    v.vertex.x += offset.x;
    v.vertex.y += offset.y;
    v.vertex.z += offset.z;
}

void rotateLocalRotaion_X (inout appdata_full v, in float degree)
{
    // 로컬 위치 YZ평면 회전
    float rad = radians(degree);
    float cosTheta = cos(rad);
    float sinTheta = sin(rad);

    float2 rotatedPosition;
    rotatedPosition.x = v.vertex.y * cosTheta - v.vertex.z * sinTheta;
    rotatedPosition.y = v.vertex.y * sinTheta + v.vertex.z * cosTheta;
    v.vertex = float4(v.vertex.x, rotatedPosition.x, rotatedPosition.y, v.vertex.w);

    float2 rotatedNormal;
    rotatedNormal.x = v.normal.y * cosTheta - v.normal.z * sinTheta;
    rotatedNormal.y = v.normal.y * sinTheta + v.normal.z * cosTheta;
    v.normal = float3(v.normal.x, rotatedNormal.x, rotatedNormal.y);
}

void rotateLocalRotaion_Y (inout appdata_full v, in float degree)
{
    // 로컬 위치 XZ 평면 회전
    float rad = radians(degree);
    float cosTheta = cos(rad);
    float sinTheta = sin(rad);

    float2 rotatedPosition;
    rotatedPosition.x = v.vertex.x * cosTheta - v.vertex.z * sinTheta;
    rotatedPosition.y = v.vertex.x * sinTheta + v.vertex.z * cosTheta;
    v.vertex = float4(rotatedPosition.x, v.vertex.y, rotatedPosition.y, v.vertex.w);

    float2 rotatedNormal;
    rotatedNormal.x = v.normal.x * cosTheta - v.normal.z * sinTheta;
    rotatedNormal.y = v.normal.x * sinTheta + v.normal.z * cosTheta;
    v.normal = float3(rotatedNormal.x, v.normal.y, rotatedNormal.y);
}

void rotateLocalRotaion_Z (inout appdata_full v, in float degree)
{
    // 로컬 위치 XY평면 회전
    float rad = radians(degree);
    float cosTheta = cos(rad);
    float sinTheta = sin(rad);

    float2 rotatedPosition;
    rotatedPosition.x = v.vertex.x * cosTheta - v.vertex.y * sinTheta;
    rotatedPosition.y = v.vertex.x * sinTheta + v.vertex.y * cosTheta;
    v.vertex = float4(rotatedPosition.x, rotatedPosition.y, v.vertex.z, v.vertex.w);

    float2 rotatedNormal;
    rotatedNormal.x = v.normal.x * cosTheta - v.normal.y * sinTheta;
    rotatedNormal.y = v.normal.x * sinTheta + v.normal.y * cosTheta;
    v.normal = float3(rotatedNormal.x, rotatedNormal.y, v.normal.z);
}