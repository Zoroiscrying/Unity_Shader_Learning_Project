// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

            
            //#include "UnityCG.cginc"
            #if !defined(MY_LIGHTING_INCLUDED)
            #define MY_LIGHTING_INCLUDED

            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "UnityStandardUtils.cginc"
           
            
            #endif

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            //used for forward shading
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                
                //#if defined(SHADOWS_SCREEN)
                //float4 shadowCoordinates : TEXCOORD4;
                //#endif
                SHADOW_COORDS(4)
                
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
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //the fourth homogeneous coordinate must be 0
                
                //o.normal = mul((float3x3)unity_ObjectToWorld， v.normal);
                //o.normal = normalize(mul(transpose((float3x3)unity_ObjectToWorld), v.normal));
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                //#if defined(SHADOWS_SCREEN)
                //    o.shadowCoordinates = ComputeScreenPos(o.vertex);
                //#endif
                TRANSFER_SHADOW(o);
                ComputeVertexLightColor(o);
                return o;
            }
            
            float3 BoxProjection (
                float3 direction, float3 position,
                float4 cubemapPosition, float3 boxMin, float3 boxMax
            ) {
                #if UNITY_SPECCUBE_BOX_PROJECTION
                    UNITY_BRANCH
                    if (cubemapPosition.w > 0) {
                        float3 factors =
                            ((direction > 0 ? boxMax : boxMin) - position) / direction;
                        float scalar = min(min(factors.x, factors.y), factors.z);
                        direction = direction * scalar + (position - cubemapPosition);
                    }
                #endif
                return direction;
            }
            
            UnityIndirect CreateIndirectLight (v2f i, float3 viewDir) {
                UnityIndirect indirectLight;
                indirectLight.diffuse = 0;
                indirectLight.specular = 0;
            
                #if defined(VERTEXLIGHT_ON)
                    indirectLight.diffuse = i.vertexLightColor;
                #endif
                
                //calculate Spherical Harmonic Lightings and add it to the Indirect Light data
                #if defined(FORWARD_BASE_PASS)
                    indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
                    float3 reflectionDir = reflect(-viewDir, i.normal);
                    //float roughness = 1 - _Smoothness;
                    //roughness *= 1.7 - 0.7 * roughness;
                    //float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(
                    //    unity_SpecCube0, reflectionDir, roughness * UNITY_SPECCUBE_LOD_STEPS
                    //);
                    Unity_GlossyEnvironmentData envData;
                    envData.roughness = 1 - _Smoothness;
                    //envData.reflUVW = reflectionDir;
                    float interpolator = unity_SpecCube0_BoxMin.w;
                    envData.reflUVW = BoxProjection(
                        reflectionDir, i.worldPos,
                        unity_SpecCube0_ProbePosition,
                        unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
                    );
                    //indirectLight.specular = DecodeHDR(envSample, unity_SpecCube0_HDR);
                    float3 probe0 = Unity_GlossyEnvironment(
                        UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
                    );
                    #if UNITY_SPECCUBE_BLENDING
                        UNITY_BRANCH
                        if (interpolator < 0.99999) {
                            float3 probe1 = Unity_GlossyEnvironment(
                                UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
                                unity_SpecCube0_HDR, envData
                            );
                            indirectLight.specular = lerp(probe1, probe0, interpolator);
                        }
                        else {
                            indirectLight.specular = probe0;
                        }
                    #else
                         indirectLight.specular = probe0;
                    #endif
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
	            
                //#if defined(SHADOWS_SCREEN)
                //    //float attenuation = tex2D(_ShadowMapTexture, i.shadowCoordinates.xy/i.shadowCoordinates.w);
                //    float attenuation = SHADOW_ATTENUATION(i);
                //    //float attenuation = 0;
                //#else
                //    UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
                //#endif
                UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
                
                //float3 lightVec = _WorldSpaceLightPos0.xyz - i.worldPos;
	            //float attenuation = 1 / (1+(dot(lightVec, lightVec)));
	            
	            //calculate the attenuation of a light using the macro below
	            //Note that the macro defines the variable in the current scope. So we shouldn't declare it ourselves anymore.
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
				
				//UnityIndirect indirectLight;
				//indirectLight.diffuse = 0;
				//indirectLight.specular = 0;

				return UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, _Smoothness,
					i.normal, viewDir,
					CreateLight(i), CreateIndirectLight(i, viewDir)
				);
            }
