struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    float3 normal : NORMAL;
    float4 worldPos : TEXCOORD1;
    float4 localPos : TEXCOORD2;
};

float4 _OffsetLocalPos;
float4 _OffsetLocalRot;

float4 _RotationSpeed;

sampler2D _MainTex;
float4 _MainTex_ST;

void offsetLocalPosition (inout appdata v, in float4 offset)
{
    v.vertex.x += offset.x;
    v.vertex.y += offset.y;
    v.vertex.z += offset.z;
}

void rotateLocalRotaion_X (inout appdata v, in float degree)
{
    // 로컬 위치 YZ평면 회전
    float rad = radians(degree);
    float cosTheta = cos(rad);
    float sinTheta = sin(rad);

    float2 rotatedPosition;
    rotatedPosition.x = v.vertex.y * cosTheta - v.vertex.z * sinTheta;
    rotatedPosition.y = v.vertex.y * sinTheta + v.vertex.z * cosTheta;
    v.vertex = float4(v.vertex.x, rotatedPosition.x, rotatedPosition.y, v.vertex.w);
}

void rotateLocalRotaion_Y (inout appdata v, in float degree)
{
    // 로컬 위치 XZ평면 회전
    float rad = radians(degree);
    float cosTheta = cos(rad);
    float sinTheta = sin(rad);

    float2 rotatedPosition;
    rotatedPosition.x = v.vertex.x * cosTheta - v.vertex.z * sinTheta;
    rotatedPosition.y = v.vertex.x * sinTheta + v.vertex.z * cosTheta;
    v.vertex = float4(rotatedPosition.x, v.vertex.y, rotatedPosition.y, v.vertex.w);
}

void rotateLocalRotaion_Z (inout appdata v, in float degree)
{
    // 로컬 위치 XY평면 회전
    float rad = radians(degree);
    float cosTheta = cos(rad);
    float sinTheta = sin(rad);

    float2 rotatedPosition;
    rotatedPosition.x = v.vertex.x * cosTheta - v.vertex.y * sinTheta;
    rotatedPosition.y = v.vertex.x * sinTheta + v.vertex.y * cosTheta;
    v.vertex = float4(rotatedPosition.x, rotatedPosition.y, v.vertex.z, v.vertex.w);
}