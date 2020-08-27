// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Zoroiscrying/RenderingLearning/FirstNewShader"
{
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
		[HDR]_Tint ("Tint", Color) = (1, 1, 1, 1)
	}

    SubShader
    {
        Pass
        {
            CGPROGRAM
            //Tell the CGPROGRAM to mark 'xxx' and 'xxx' as the 'vertex' and 'fragment' function of this CGPROGRAM
            #pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram
			#include "UnityCG.cginc"
			
            struct VertexData {
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};
			
            struct Interpolators {
				float4 position : SV_POSITION;
				float2 uv:TEXCOORD0;
				//float3 localPosition : TEXCOORD0;
			};
			
            fixed4 _Tint;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			Interpolators MyVertexProgram(VertexData v) 
			{
			    Interpolators i;
			    //i.localPosition = v.position.xyz;
			    i.uv = TRANSFORM_TEX(v.uv, _MainTex);
			    i.position = UnityObjectToClipPos(v.position);
			    return i;
			}
			
            float4 MyFragmentProgram(Interpolators i):SV_TARGET 
			{
			    return tex2D(_MainTex, i.uv) * _Tint;
			}

            ENDCG
        }
    }
}
