Shader "Zoroiscrying/RenderingLearning/TextureWithDetail"
{
    Properties
    {
        _MainTex ("Splat Map", 2D) = "white" {}
        [NoScaleOffset]_Texture1 ("Texture 1", 2D) = "white" {}
		[NoScaleOffset]_Texture2 ("Texture 2", 2D) = "white" {}
        [NoScaleOffset] _Texture3("Texture 3", 2D)= "white" {}
		[NoScaleOffset] _Texture4("Texture 4", 2D)= " white" {}
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
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uvSplat : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Texture1, _Texture2, _Texture3, _Texture4;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uvSplat = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 splat = tex2D(_MainTex, i.uvSplat);
                fixed4 col = 					
                    tex2D(_Texture1, i.uv) * splat.r +
					tex2D(_Texture2, i.uv) * splat.g +
					tex2D(_Texture3, i.uv) * splat.b +
					tex2D(_Texture4, i.uv) * (1 - splat.r - splat.g - splat.b);
                return col;
            }
            ENDCG
        }
    }
}
