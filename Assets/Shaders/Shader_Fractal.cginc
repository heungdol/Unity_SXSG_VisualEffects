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

void inverseLocalPosition_X (inout appdata v)
{
    v.vertex.x *= -1;
}

void calculateVert (inout appdata v, inout v2f o, in float startAngle, in float isInverse)
{
    // 로컬 회전 Offset
    rotateLocalRotaion_X (v, _OffsetLocalRot.x);
    rotateLocalRotaion_Y (v, _OffsetLocalRot.y);
    rotateLocalRotaion_Z (v, _OffsetLocalRot.z);

    // 시간에 따른 회전
    rotateLocalRotaion_X (v, degrees(_Time * _RotationSpeed.x));
    rotateLocalRotaion_Y (v, degrees(_Time * _RotationSpeed.y));
    rotateLocalRotaion_Z (v, degrees(_Time * _RotationSpeed.z));
    
    // 로컬 위치 Offset
    offsetLocalPosition (v, _OffsetLocalPos);
    
    // X축 반전 (짝수번째 Pass인 경우)
    if (isInverse > 0.5)
    {
        inverseLocalPosition_X (v);
    }

    // 기준 각도로 회전 (XY) 
    rotateLocalRotaion_Z (v, startAngle);

    // 본래 정보 계산
    o.localPos = v.vertex;
    o.vertex = UnityObjectToClipPos(o.localPos);
    o.worldPos = mul (unity_ObjectToWorld, o.localPos);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.normal = v.normal;
}

float isBetweenAngle (in v2f i, in float startAngle, in float gapAngle)
{
    // 사이각 판단
    float isBetweenAngle = 1.0;

    // 깔끔한 컷팅을 위해 frag에서 수행
    // 시작 앵글
    float rad = radians (-startAngle - gapAngle);
    float cosTheta = cos (rad);
    float sinTheta = sin (rad);
    float rotatedPosX = i.localPos.x * cosTheta  - i.localPos.y *sinTheta;

    isBetweenAngle *= step (rotatedPosX, 0);
    
    // 끝 앵글
    rad = radians (-startAngle + gapAngle);
    cosTheta = cos (rad);
    sinTheta = sin (rad);
    rotatedPosX = i.localPos.x * cosTheta  - i.localPos.y *sinTheta;

    isBetweenAngle *= (1 - step (rotatedPosX, 0));

    return isBetweenAngle;
}

fixed4 calculateColor (inout v2f i)
{
    fixed4 col = tex2D(_MainTex, i.uv);
    return col;
}
