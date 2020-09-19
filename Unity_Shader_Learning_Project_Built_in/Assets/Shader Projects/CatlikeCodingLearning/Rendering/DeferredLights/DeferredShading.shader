Shader "Zoroiscrying/RenderingLearning/DeferredShading"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off 
        ZWrite Off 
        ZTest Always
        
        Stencil {
            Ref [_StencilNonBackground]
            ReadMask [_StencilNonBackground]
            CompBack Equal
            CompFront Equal
        }

        Pass
        {
            Blend [_SrcBlend] [_DstBlend]
			//Cull Off
			//ZTest Always
			ZWrite Off
        
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma exclude_renderers nomrt
            
            //#define SHADOWS_SCREEN
            //#pragma multi_compile_prepassfinal
            #pragma multi_compile_lightpass
			#pragma multi_compile _ UNITY_HDR_ON
            
            #include "MyDeferredShading.cginc"
            
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma exclude_renderers nomrt
            #include "UnityCG.cginc"

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _LightBuffer;
            
            fixed4 frag (v2f i) : SV_Target
            {
                // just invert the colors
                
                return -log2(tex2D(_LightBuffer, i.uv));
            }
            ENDCG
        }
    }
}
