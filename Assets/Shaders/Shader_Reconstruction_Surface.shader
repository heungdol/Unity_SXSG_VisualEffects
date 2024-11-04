Shader "SXSG/Shader_Reconstruction_Surface"
{
    Properties
    {
        _BaseMap ("Albedo (RGB)", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        
        _DirectionMask ("Direction Map Texture", 2D) = "gray" {}
        _IDMask ("ID Texture", 2D) = "white" {}       

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
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow
        #pragma target 3.0

        sampler2D _BaseMap;

        struct Input
        {
            float2 uv_BaseMap;
            float2 uv2_DirectionMask;
        };

        sampler2D _DirectionMask;
        float4 _DirectionMask_ST;
        
        sampler2D _IDMask;
        float4 _IDMask_ST;
        
        UNITY_INSTANCING_BUFFER_START(Props)
        
        float _RecontructionRate;
        
        float _DirectionDegree;
        float _DirectionOffsetDegree;
        float _RotationDegree;
        float _RandomSeed;
        
        float _FloatingSpeed;
        float _FloatingDirectionDegree;
        float _FloatingRotationDegree;
        
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        UNITY_INSTANCING_BUFFER_END(Props)

        
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

        float customRandom (in float value)
        {
            return frac (sin (value * -_RandomSeed) * 12345.6789);
        }

        float customRandom_Cos (in float value)
        {
            return frac (cos (value * -_RandomSeed) * 12345.6789);
        }

        void vert(inout appdata_full data)
        {
            // 두 개의 UV 좌표
            float2 uv = data.texcoord.xy;
            float2 uv2 = data.texcoord2.xy;
            
            // 랜덤 값
            float4 idCol = tex2Dlod(_IDMask, float4(uv, 0.0, 1.0));
            float3 randomOffset = 
            float3(customRandom(idCol+10.0), customRandom_Cos(idCol+10.25), customRandom(idCol+10.5));
            
            // 로테이션
            rotateLocalRotaion_X 
            (data, (randomOffset.x * _RotationDegree + cos (_Time * _FloatingSpeed * randomOffset.x) * _FloatingRotationDegree) * _RecontructionRate);
            rotateLocalRotaion_Y 
            (data, (randomOffset.y * _RotationDegree + sin (_Time * _FloatingSpeed * randomOffset.y) * _FloatingRotationDegree) * _RecontructionRate);
            rotateLocalRotaion_Z 
            (data, (randomOffset.z * _RotationDegree + cos (_Time * _FloatingSpeed * randomOffset.z) * _FloatingRotationDegree) * _RecontructionRate);

            // 위치 Offset
            float4 directionCol = tex2Dlod(_DirectionMask, float4(uv2, 0.0, 1.0));
            directionCol -= 0.5;
            directionCol *= 2;
            
            data.vertex.xyz += (directionCol.xyz * _DirectionDegree + randomOffset * _DirectionOffsetDegree) 
            * _RecontructionRate;    
        }   

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_BaseMap, IN.uv_BaseMap) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
