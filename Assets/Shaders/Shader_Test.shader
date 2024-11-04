Shader "Unlit/Shader_Test"
{
	Properties 
    {
        _BaseMap ("Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (0, 0, 0, 1)
        _SecondTex ("Texture Second", 2D) = "white" {}
        _Smoothness ("Smoothness", float) = 0
        _Metallic ("Metalness", float) = 0
        [HDR] _Emission ("Emission", Color) = (0,0,0,1)
	}

	SubShader 
    {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow
        #pragma target 3.0

		sampler2D _BaseMap;
		sampler2D _SecondTex;
		fixed4 _Color;

        float _Smoothness;
        float _Metallic;

        half3 _Emission;

		struct Input 
        {
			float2 uv_BaseMap;
			float2 uv2_SecondTex;
		};

        void vert(inout appdata_full data)
        {
            
        }

        // SurfaceOutputStandard
        // fixed3 Albedo
        // fixed3 Normal
        // half3 Emission
        // half Metalic
        // half Smoothness
        // half Occulusion
        // fixed alpha

        /*
        float3 n = UnpackNormal(tex2D(_BumpTex, IN.uv_BumpTex));
        // R -> smoothness *
        // G -> Metallic
        // B -> None
        // A -> Occlusion

        o.Albedo = c.rgb;
        o.Normal = n;
        */

		void surf (Input i, inout SurfaceOutputStandard o) 
        {
			fixed4 col = tex2D(_BaseMap, i.uv_BaseMap);
			col *= _Color;
            // col *= tex2D (_MainTex, i.uv2_SecondTex);
            // col *= tex2D (_MainTex, i.uv2_SecondTex);
            o.Albedo = col.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;
            o.Emission = _Emission;
            o.Alpha = 0;
            // o.AlphaTest = 0;
		}
        
		ENDCG
	}
}