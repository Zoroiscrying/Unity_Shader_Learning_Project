Shader "Zoroiscrying/RenderingLearning/TransparentShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Tint("Tint", Color) = (1,1,1,1)
        _AlphaCutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        [HideInInspector]_SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector]_DstBlend ("_DstBlend", Float) = 0
		[HideInInspector] _ZWrite ("_ZWrite", Float) = 1
    }
    SubShader
    {

        Pass
        {
            Tags { "RenderType"="Transparent"}
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            // forward add - Blend [_SrcBlend] one // additive blend
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            float4 _Tint;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _AlphaCutoff;

            float GetAlpha (v2f i) {
                return _Tint.a * tex2D(_MainTex, i.uv.xy).a;
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float alpha = GetAlpha(i);
                #if defined(_RENDERING_CUTOUT)
                    clip(alpha - _AlphaCutoff);
                #endif
                
                fixed4 col = tex2D(_MainTex, i.uv);
                
                #if defined(_RENDERING_FADE)
                    col.a = alpha;
                #endif
                return col;
            }
            ENDCG
        }
        
        Pass
        {
            Tags 
            {
				"LightMode" = "ShadowCaster"
			}
			CGPROGRAM
			
            #pragma target 3.0

            #pragma multi_compile_shadowcaster
            
            #pragma shader_feature _SEMITRANSPARENT_SHADOWS
            #pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _SMOOTHNESS_ALBEDO
            
			#pragma vertex vert
			#pragma fragment MyShadowFragmentProgram

			#include "../MultipleLights/MyShadow.cginc"
        
            ENDCG
        }
    }
    CustomEditor "TransparentShaderGUI"
}
