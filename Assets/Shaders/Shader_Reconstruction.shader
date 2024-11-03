// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/Shader_Reconstruction"
{
    Properties
    {
        _BaseMap ("Texture", 2D) = "white" {}

        _IDMask ("ID Mask Map", 2D) = "white" {}
        _DirectionMask ("Direction Mask Map", 2D) = "white" {}

        _RecontructionRate ("Recontruction Rate", Range (0.0, 1.0)) = 0

        _DirectionDegree ("Direction Degree", Float) = 0
        _DirectionOffsetDegree ("Direction Random Degree", Float) = 0.5

        _RotationDegree ("Rotation Degree", Float) = 0
        _RandomSeed ("Random Seed", Int) = 12345

        _FloatingSpeed ("Floating Speed", Float) = 10
        _FloatingDirectionDegree ("Floating Direction Degree", Float) = 1
        _FloatingRotationDegree ("Floating Rotation Degree", Float) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            // #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Shader_Utils.cginc"

            // sampler2D _BaseMap;
            // float4 _BaseMap_ST;

            sampler2D _IDMask;
            float4 _IDMask_ST;
            
            sampler2D _DirectionMask;
            float4 _DirectionMask_ST;
            
            float _RecontructionRate;

            float _DirectionDegree;
            float _DirectionOffsetDegree;
            float _RotationDegree;
            float _RandomSeed;

            float _FloatingSpeed;
            float _FloatingDirectionDegree;
            float _FloatingRotationDegree;

            float customRandom (in float value)
            {
                return frac (sin (value * -_RandomSeed) * 12345.6789);
            }

            float customRandom_Cos (in float value)
            {
                return frac (cos (value * -_RandomSeed) * 12345.6789);
            }

            v2f vert (appdata_full v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                o.uv2 = TRANSFORM_TEX(v.texcoord2, _BaseMap);
                // UNITY_TRANSFER_FOG(o, o.vertex);

                // Sample _IDMask texture in the vertex shader

                // 랜덤 값
                float4 idCol = tex2Dlod(_IDMask, float4(o.uv, 0.0, 1.0));
                float3 randomOffset = 
                float3(customRandom(idCol+10.0), customRandom_Cos(idCol+10.25), customRandom(idCol+10.5));
                
                // 로테이션
                rotateLocalRotaion_X 
                (v, (randomOffset.x * _RotationDegree + cos (_Time * _FloatingSpeed * randomOffset.x) * _FloatingRotationDegree) * _RecontructionRate);
                rotateLocalRotaion_Y 
                (v, (randomOffset.y * _RotationDegree + sin (_Time * _FloatingSpeed * randomOffset.y) * _FloatingRotationDegree) * _RecontructionRate);
                rotateLocalRotaion_Z 
                (v, (randomOffset.z * _RotationDegree + cos (_Time * _FloatingSpeed * randomOffset.z) * _FloatingRotationDegree) * _RecontructionRate);

                // 위치 Offset
                float4 directionCol = tex2Dlod(_DirectionMask, float4(o.uv2, 0.0, 1.0));
                directionCol -= 0.5;
                directionCol *= 2;
                
                v.vertex.xyz += (directionCol.xyz * _DirectionDegree + randomOffset * _DirectionOffsetDegree) 
                * _RecontructionRate;
                
                o.vertex = UnityObjectToClipPos(v.vertex);

                    // 본래 정보 계산
                o.localPos = v.vertex;
                o.worldPos = mul (unity_ObjectToWorld, o.localPos);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
                // compute bitangent from cross product of normal and tangent
                half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                half3 wBitangent = cross(o.worldNormal, wTangent) * tangentSign;
                // output the tangent space matrix
                o.tspace0 = half3(wTangent.x, wBitangent.x, o.worldNormal.x);
                o.tspace1 = half3(wTangent.y, wBitangent.y, o.worldNormal.y);
                o.tspace2 = half3(wTangent.z, wBitangent.z, o.worldNormal.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_BaseMap, i.uv);
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);

                half3 tnormal = UnpackNormal(tex2D(_BumpMap, i.uv));
                half3 worldNormal;
                worldNormal.x = dot(i.tspace0, tnormal);
                worldNormal.y = dot(i.tspace1, tnormal);
                worldNormal.z = dot(i.tspace2, tnormal);

                half nl = max (0, dot (worldNormal, _WorldSpaceLightPos0.xyz));
                float4 diff = nl * _LightColor0;

                // 하나의 포인트 라이트 계산 추가
                float3 lightPosWorld = float3(unity_4LightPosX0[0], unity_4LightPosY0[0], unity_4LightPosZ0[0]);
                float3 lightDir = normalize(lightPosWorld - i.worldPos);
                float lightDist = distance(lightPosWorld, i.worldPos);
                float3 lightColor = unity_LightColor[0].rgb;
    
                // 감쇠 계산 적용
                float attenuation 
                = 1.0 / (unity_4LightAtten0[0] + unity_4LightAtten0[0] * lightDist + unity_4LightAtten0[0] * lightDist * lightDist);
                attenuation = max (0, attenuation);
    
                // 포인트 라이트의 강도 계산 (조명 방향과 표면 노멀 사이의 각도 고려)
                float pointLightIntensity = max(0.0, dot(worldNormal, lightDir)) * attenuation;
    
                // 최종 라이트 색상 적용
                float3 pointLight = pointLightIntensity * lightColor;
    
                // 기존 조명 색상에 더하기
                diff.rgb += pointLight;
                diff.rgb += ShadeSH9(half4(worldNormal,1));

                col *= diff;

                return float4(col.rgb, 1.0);
            }
            ENDCG
        }
    }
}
