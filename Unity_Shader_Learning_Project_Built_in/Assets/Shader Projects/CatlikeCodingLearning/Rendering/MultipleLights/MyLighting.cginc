            
            //#include "UnityCG.cginc"
            #if !defined(MY_LIGHTING_INCLUDED)
            #define MY_LIGHTING_INCLUDED

            #include "AutoLight.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "UnityStandardUtils.cginc"
            #include "UnityPBSLighting.cginc"
            
            #endif

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                
                #if defined(VERTEXLIGHT_ON)
		        float3 vertexLightColor : TEXCOORD3;
	            #endif
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed3 _Tint;
            //float4 _SpecularTint;
            float _Smoothness;
            float _Metallic;
            
            void ComputeVertexLightColor (inout v2f i) {
                #if defined(VERTEXLIGHT_ON)
                ////the position of the first light (x component)
                //float3 lightPos = float3(
                //    unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x
                //);
                //float3 lightVec = lightPos - i.worldPos;
                //float3 lightDir = normalize(lightVec);
                //float ndotl = DotClamped(i.normal, lightDir);
                //float attenuation = 1 / (1 + dot(lightVec, lightVec * unity_4LightAtten0.x));
                //i.vertexLightColor = unity_LightColor[0].rgb * ndotl * attenuation;
                
                //compute all the vertex lights
                i.vertexLightColor = Shade4PointLights(
                    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                    unity_LightColor[0].rgb, unity_LightColor[1].rgb,
                    unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                    unity_4LightAtten0, i.worldPos, i.normal
                );
	            #endif
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //the fourth homogeneous coordinate must be 0
                
                //o.normal = mul((float3x3)unity_ObjectToWorld， v.normal);
                //o.normal = normalize(mul(transpose((float3x3)unity_ObjectToWorld), v.normal));
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                ComputeVertexLightColor(o);
                return o;
            }
            
            UnityIndirect CreateIndirectLight (v2f i) {
                UnityIndirect indirectLight;
                indirectLight.diffuse = 0;
                indirectLight.specular = 0;
            
                #if defined(VERTEXLIGHT_ON)
                    indirectLight.diffuse = i.vertexLightColor;
                #endif
                
                //calculate Spherical Harmonic Lightings and add it to the Indirect Light data
                #if defined(FORWARD_BASE_PASS)
                indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
                #endif
                
                return indirectLight;
            }
            
            UnityLight CreateLight (v2f i) {
                UnityLight light;
                //The _WorldSpaceLightPos0 variable contains the current light's position. 
                //But in case of a directional light, it actually holds the direction towards the light.
                
                //light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
                
                #if defined(POINT) || defined(SPOT) || defined(POINT_COOKIE)
		        light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
	            #else
		        light.dir = _WorldSpaceLightPos0.xyz;
	            #endif
                
                //float3 lightVec = _WorldSpaceLightPos0.xyz - i.worldPos;
	            //float attenuation = 1 / (1+(dot(lightVec, lightVec)));
	            
	            //calculate the attenuation of a light using the macro below
	            //Note that the macro defines the variable in the current scope. So we shouldn't declare it ourselves anymore.
	            UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
                light.color = _LightColor0.rgb * attenuation;
                light.ndotl = DotClamped(i.normal, light.dir);
                return light;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //PBR Lighting Calculation
                i.normal = normalize(i.normal);
				//float3 lightDir = _WorldSpaceLightPos0.xyz;
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

				//float3 lightColor = _LightColor0.rgb;
				float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

				float3 specularTint;
				float oneMinusReflectivity;
				albedo = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularTint, oneMinusReflectivity
				);
				
				//UnityLight light;
				//light.color = lightColor;
				//light.dir = lightDir;
				//light.ndotl = DotClamped(i.normal, lightDir);
				
				UnityIndirect indirectLight;
				indirectLight.diffuse = 0;
				indirectLight.specular = 0;

				return UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, _Smoothness,
					i.normal, viewDir,
					CreateLight(i), CreateIndirectLight(i)
				);
            }