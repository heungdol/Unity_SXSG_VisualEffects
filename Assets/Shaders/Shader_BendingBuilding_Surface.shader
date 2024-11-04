Shader "SXSG/Shader_BendingBuilding_Surface"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _BaseMap ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _PivotX ("Pivot X (WorldPos)", Float) = 50
        _PivotY ("Pivot Y (WorldPos)", Float) = 100
        _InnerX ("Inner X (LocalPos)", Float) = 10

        _BendingRatio ("Bending Ratio", Range (0.0, 1.0)) = 0.0
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
		};

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        
        float _BendingRatio;
        
        UNITY_INSTANCING_BUFFER_START(Props)
        
        float _PivotY;
        float _PivotX;
        float _InnerX;

        UNITY_INSTANCING_BUFFER_END(Props)

        void vert(inout appdata_full data)
        {
            // 월드 위치
            float4 worldPos = mul(unity_ObjectToWorld, data.vertex);
            float4 worldInnerPos = mul (unity_ObjectToWorld, float4(_InnerX, 0.0, 0.0, 1.0));
            
            // 영향을 받을 부분 판단 (일정 높이 이상)
            float isUpperThanStartHeight = step (_PivotY, worldPos.y);

            // 반지름
            float radius = (_PivotX - worldPos.x);

            // 하나의 기준 축을 이용하여 계산 (부피에 따른 적절한 비율로 계산하기 위함)
            float radiusInner = (_PivotX - worldInnerPos.x);
            
            float length = abs (worldPos.y - _PivotY);
            float angle = length / radiusInner;

            // 길이와 각을 이용하여 굽힘 정도 계산
            float4 offsetWorldPos = float4 (0.0, 0.0, 0.0, 0.0);
            offsetWorldPos.y = sin (angle) * radius;
            offsetWorldPos.x = cos (angle) * -radius;

            float4 pivotWorldPos = float4 (_PivotX, _PivotY, worldPos.z, 1.0);

            // Bending 적용
            float ratio = isUpperThanStartHeight * _BendingRatio;
            float3 bentWorldPos = lerp(worldPos, offsetWorldPos + pivotWorldPos, ratio);
            data.vertex = mul (unity_WorldToObject, float4(bentWorldPos, 1.0));
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
