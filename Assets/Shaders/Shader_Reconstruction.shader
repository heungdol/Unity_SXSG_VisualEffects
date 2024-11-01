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
        Tags { "RenderType"="Opaque" }
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

            sampler2D _BaseMap;
            float4 _BaseMap_ST;

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

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
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
                float4 directionCol = tex2Dlod(_DirectionMask, float4(o.uv, 0.0, 1.0));
                directionCol -= 0.5;
                directionCol *= 2;
                
                v.vertex.xyz += (directionCol.xyz + randomOffset * _DirectionOffsetDegree) 
                * _DirectionDegree * _RecontructionRate;
                
                o.vertex = UnityObjectToClipPos(v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_BaseMap, i.uv);
                // apply fog
                // UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
