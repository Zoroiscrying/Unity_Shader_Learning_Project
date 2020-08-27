// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Zoroiscrying/CommandBuffer/Command_GaussianBlur_Taker"
{
    Properties
    {
        _BlurTex ("Blur Texture", 2D) = "white" {}
		_BlurIntensity ("Blur Intensity", Range(0.0, 1.0)) = 0.5
    }
    SubShader
    {
		Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
		CULL OFF
		LOD 100
 
        //Vertical and Horizontal blur
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
                float4 pos : POSITION;
				float2 uvblur : TEXCOORD0;
				float4 uvgrab : TEXCOORD1;  
            };
            
            sampler2D _BlurTex;
			float4 _BlurTex_ST;
			float _BlurIntensity;
			//grab textures that command buffer sends
            sampler2D _GrabBlurTexture_0;
			sampler2D _GrabBlurTexture_1;
			sampler2D _GrabBlurTexture_2;
			sampler2D _GrabBlurTexture_3;
 
            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uvblur = TRANSFORM_TEX(v.uv, _BlurTex);
                o.uvgrab = ComputeGrabScreenPos(o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float surfSmooth = 1-tex2D(_BlurTex, i.uvblur) * _BlurIntensity;
				
				//surfsmooth为1是最清晰的意思
				surfSmooth = clamp(0, 1, surfSmooth);

				half4 refraction;

				half4 ref00 = tex2Dproj(_GrabBlurTexture_0, i.uvgrab);
				half4 ref01 = tex2Dproj(_GrabBlurTexture_1, i.uvgrab);
				half4 ref02 = tex2Dproj(_GrabBlurTexture_2, i.uvgrab);
				half4 ref03 = tex2Dproj(_GrabBlurTexture_3, i.uvgrab);
                
                //决定surfsmooth是在哪一层，00如果是1代表surfsmooth在0.75在1.00之间，即应采用ref00，最清晰的图像。
                
                //最清晰
				float step00 = smoothstep(0.75, 1.00, surfSmooth);
				
				float step01 = smoothstep(0.5, 0.75, surfSmooth);
				float step02 = smoothstep(0.05, 0.5, surfSmooth);
				
				//最模糊
				float step03 = smoothstep(0.00, 0.05, surfSmooth);
                
                //lerp顺序（ref03代表最模糊，ref00代表最清晰）
                //从ref03到ref02，用step02决定（0.05 到 0.5 是较模糊到一般模糊的过渡）
                //从上述图到ref01，用step01决定（0.5 到 0.75 是一般模糊到较清晰的过渡）
                //从上述图到ref00，用step00决定（0.75 到 1 是较清晰到清晰的过渡）
                //从ref03到上述图，用step03决定（0.00 到 0.05 是最模糊到较模糊的过渡）
                //一个surfsmooth为1的计算，最终结果应该是ref00.
                //一个surfsmooth为0的计算，最终结果应该是ref03.
                
				refraction = lerp(ref03, lerp( lerp( lerp(ref03, ref02, step02), ref01, step01), ref00, step00), step03);
				
				return refraction + fixed4(0.05, 0.05, 0.05, 0);
            }
            ENDCG
        }
    }
}
