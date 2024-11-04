float4 _OffsetLocalPos;
float4 _OffsetLocalRot;

float4 _RotationSpeed;

void inverseLocalPosition_X (inout appdata_full v)
{
    v.vertex.x *= -1;
    v.normal.x *= -1;
}

void calculateVert (inout appdata_full v, inout v2f o, in float startAngle, in float isInverse)
{
    // 로컬 위치 Offset
    // offsetLocalPosition (v, float4(0.0, 0.0, _OffsetLocalPos.z, 1.0));
    
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
    o.pos = UnityObjectToClipPos(o.localPos);
    o.worldPos = mul (unity_ObjectToWorld, o.localPos);
    o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
    o.uv2 = TRANSFORM_TEX(v.texcoord2, _BaseMap);


    o.worldNormal = UnityObjectToWorldNormal(v.normal);
    half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
    // compute bitangent from cross product of normal and tangent
    half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
    half3 wBitangent = cross(o.worldNormal, wTangent) * tangentSign;
    // output the tangent space matrix
    o.tspace0 = half3(wTangent.x, wBitangent.x, o.worldNormal.x);
    o.tspace1 = half3(wTangent.y, wBitangent.y, o.worldNormal.y);
    o.tspace2 = half3(wTangent.z, wBitangent.z, o.worldNormal.z);
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
    fixed4 col = tex2D(_BaseMap, i.uv);

    half3 tnormal = UnpackNormal(tex2D(_BumpMap, i.uv));
    half3 worldNormal;
    worldNormal.x = dot(i.tspace0, tnormal);
    worldNormal.y = dot(i.tspace1, tnormal);
    worldNormal.z = dot(i.tspace2, tnormal);

    half nl = max (0, dot (worldNormal, _WorldSpaceLightPos0.xyz));
    float4 diff = nl * _LightColor0;
    diff.rgb += ShadeSH9(half4(worldNormal,1));

    col *= diff;

    return col;
}
