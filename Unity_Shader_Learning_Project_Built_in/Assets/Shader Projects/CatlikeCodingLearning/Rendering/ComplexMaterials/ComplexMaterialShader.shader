Shader "Zoroiscrying/RenderingLearning/ComplexMaterialShader"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
        _Tint("Tint", Color) = (1,1,1)
        //[NoScaleOffset]_HeightMap ("Heights", 2D) = "gray" {}
        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        [NoScaleOffset] _MetallicMap ("Metallic", 2D) = "white" {}
        [Gamma]_Metallic ("Metallic", Range(0, 1)) = 0
        _DetailTex ("Detail Texture", 2D) = "gray" {}
        [NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
		_DetailBumpScale ("Detail Bump Scale", Float) = 1
        //_SpecularTint ("Specular", Color) = (0.5, 0.5, 0.5)
        [NoScaleOffset] _EmissionMap ("Emission", 2D) = "black" {}
		_Emission ("Emission", Color) = (0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {
				"LightMode" = "ForwardBase"
			}
        
            CGPROGRAM
            #pragma target 3.0
            #pragma shader_feature _METALLIC_MAP
            #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
            #pragma shader_feature _EMISSION_MAP
            #define FORWARD_BASE_PASS
            #pragma vertex vert
            #pragma fragment frag
            //#include "UnityCG.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "UnityStandardUtils.cginc"
            #include "UnityPBSLighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                #if defined(BINORMAL_PER_FRAGMENT)
                    float4 tangent : TEXCOORD2;
                #else
                    float3 tangent : TEXCOORD2;
                    float3 binormal : TEXCOORD3;
                #endif

	            float3 worldPos : TEXCOORD4;
            };

            sampler2D _MainTex, _DetailTex;
            float4 _MainTex_ST, _DetailTex_ST;
            fixed3 _Tint;
            sampler2D _NormalMap, _DetailNormalMap;
            //sampler2D _HeightMap;
            //float4 _HeightMap_TexelSize;
            //float4 _SpecularTint;
            float _Smoothness;
            sampler2D _MetallicMap;
            float _Metallic;
            float _BumpScale, _DetailBumpScale;
            sampler2D _EmissionMap;
            float3 _Emission;
            
            float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
                return cross(normal, tangent.xyz) *
                    (binormalSign * unity_WorldTransformParams.w);
            }
            
            float GetMetallic (v2f i) {
                #if defined(_METALLIC_MAP)
                    return tex2D(_MetallicMap, i.uv.xy).r;
                #else
                    return _Metallic;
                #endif
            }
            
            float GetSmoothness (v2f i) {
                float smoothness = 1;
                #if defined(_SMOOTHNESS_ALBEDO)
                    smoothness = tex2D(_MainTex, i.uv.xy).a;
                #elif defined(_SMOOTHNESS_METALLIC) && defined(_METALLIC_MAP)
                    smoothness = tex2D(_MetallicMap, i.uv.xy).a;
                #endif
                return smoothness * _Smoothness;
            }
            
            float3 GetEmission (v2f i) {
                #if defined(FORWARD_BASE_PASS)
                    #if defined(_EMISSION_MAP)
                        return tex2D(_EmissionMap, i.uv.xy) * _Emission;
                    #else
                        return _Emission;
                    #endif
                #else
                    return 0;
                #endif
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                #if defined(BINORMAL_PER_FRAGMENT)
                    o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                #else
                    o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
                    o.binormal = CreateBinormal(o.normal, o.tangent, v.tangent.w);
                #endif
                
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
                //the fourth homogeneous coordinate must be 0
                
                //o.normal = mul((float3x3)unity_ObjectToWorld， v.normal);
                //o.normal = normalize(mul(transpose((float3x3)unity_ObjectToWorld), v.normal));
                return o;
            }
            
            void InitializeFragmentNormal(inout v2f i) {
                //float2 du = float2(_HeightMap_TexelSize.x * 0.5, 0);
                //float u1 = tex2D(_HeightMap, i.uv - du);
                //float u2 = tex2D(_HeightMap, i.uv + du);
            //
                //float2 dv = float2(0, _HeightMap_TexelSize.y * 0.5);
                //float v1 = tex2D(_HeightMap, i.uv - dv);
                //float v2 = tex2D(_HeightMap, i.uv + dv);
            //
                //i.normal = float3(u1-u2, 1, v1-v2);
                
                //i.normal = tex2D(_NormalMap, i.uv).rgb * 2 - 1;
                
                //i.normal.xy = tex2D(_NormalMap, i.uv).wy * 2 - 1;
                //i.normal.xy *= _BumpScale;
            	//i.normal.z = sqrt(1 - saturate(dot(i.normal.xy, i.normal.xy)));  
                
                //the function 'UnpackScaleNormal' is equal to the lines of calculation above ↑
                //i.normal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
                
                //blending two normals
                float3 mainNormal =
                    UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
                float3 detailNormal =
                    UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);
                //i.normal =
                //    float3(mainNormal.xy + detailNormal.xy, mainNormal.z * detailNormal.z);
                //    //float3(mainNormal.xy / mainNormal.z + detailNormal.xy / detailNormal.z, 1);
                
                //i.normal = BlendNormals(mainNormal, detailNormal);
                
                float3 tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);
                //tangentSpaceNormal = tangentSpaceNormal.xzy;
            
                //float3 binormal = cross(i.normal, i.tangent.xyz) * (i.tangent.w * unity_WorldTransformParams.w);
                #if defined(BINORMAL_PER_FRAGMENT)
                    float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
                #else
                    float3 binormal = i.binormal;
                #endif
                
                i.normal = normalize(
                    tangentSpaceNormal.x * i.tangent +
                    tangentSpaceNormal.y * binormal +
                    tangentSpaceNormal.z * i.normal
                );
                //i.normal = i.normal.xzy;
                
                //i.normal = normalize(i.normal);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //PBR Lighting Calculation
                InitializeFragmentNormal(i);
                
				float3 lightDir = _WorldSpaceLightPos0.xyz;
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

				float3 lightColor = _LightColor0.rgb;
				float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
				albedo *= tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;

				float3 specularTint;
				float oneMinusReflectivity;
				albedo = DiffuseAndSpecularFromMetallic(
					albedo, GetMetallic(i), specularTint, oneMinusReflectivity
				);
				
				UnityLight light;
				light.color = lightColor;
				light.dir = lightDir;
				light.ndotl = DotClamped(i.normal, lightDir);
				
				UnityIndirect indirectLight;
				indirectLight.diffuse = 0.1;
				indirectLight.specular = 0.1;

				float4 color = UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, GetSmoothness(i),
					i.normal, viewDir,
					light, indirectLight
				);
				color.rgb += GetEmission(i);
				return color;
            }
            ENDCG
        }
    }
    CustomEditor "MyLightingShaderGui"
}
