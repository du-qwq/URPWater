Shader "Custom/Water"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (0.0, 0.5, 0.7, 0.5)
        _DepthScale("Depth Scale", Float) = 1
        
        [NoScaleOffset] _NormalTex("Normal Tex", 2D) = "bump" {}
        _NormalTiling("Normal Tiling", Float) = 1
        _NormalScale("Normal Scale", Range(0, 2)) = 1
        _NormalRefract("Normal Refract", Range(0, 1)) = 0.08
        _WaveXSpeed("Wave X Speed", Float) = 0.05
        _WaveYSpeed("Wave Y Speed", Float) = 0.08
        
        _SpecularPower("Specular Power", Range(1, 256)) = 64
        _SpecularStrength("Specular Strength", Range(0, 5)) = 1
        
        _ShallowColor("Shallow Color", Color) = (0.25, 0.75, 0.8, 1)
        _DeepColor("Deep Color", Color) = (0.0, 0.2, 0.35, 1)

        _DepthColorRange("Depth Color Range", Float) = 2
        _AlphaDepthRange("Alpha Depth Range", Float) = 2
        
        _FoamTex("Foam Tex", 2D) = "white" {}
        _FoamColor("Foam Color", Color) = (1, 1, 1, 1)

        _FoamRange("Foam Range", Float) = 1
        _FoamSoftness("Foam Softness", Float) = 0.5
        _FoamSpeed("Foam Speed", Float) = 0.15
        _FoamTiling("Foam Tiling", Float) = 1
        _FoamStrength("Foam Strength", Range(0, 3)) = 1
        
        _RefractStrength("Refract Strength", Range(0, 0.2)) = 0.03
        
        _FresnelPower("Fresnel Power", Range(1, 8)) = 5
        _FresnelStrength("Fresnel Strength", Range(0, 2)) = 1
        _ReflectionTint("Reflection Tint", Color) = (0.7, 0.85, 1.0, 1)
        _ReflectionStrength("Reflection Strength", Range(0, 2)) = 1
        _EnvReflectionRoughness("Env Reflection Roughness", Range(0, 1)) = 0.2
        
        _WaveA("Wave A (dirX, dirZ, steepness, wavelength)", Vector) = (1, 0, 0.15, 8)
        _WaveB("Wave B (dirX, dirZ, steepness, wavelength)", Vector) = (0.8, 0.6, 0.08, 4)

        _WaveSpeedA("Wave Speed A", Float) = 1.2
        _WaveSpeedB("Wave Speed B", Float) = 1.6
        
        _CrestFoamColor("Crest Foam Color", Color) = (1, 1, 1, 1)
        _CrestThreshold("Crest Threshold", Float) = 0.05
        _CrestSoftness("Crest Softness", Float) = 0.08
        _CrestSlopeStrength("Crest Slope Strength", Float) = 2
        _CrestFoamStrength("Crest Foam Strength", Range(0, 3)) = 1
        _CrestFoamTiling("Crest Foam Tiling", Float) = 2
        _CrestFoamSpeed("Crest Foam Speed", Float) = 0.2
        
        _CausticsTex("Caustics Tex", 2D) = "white" {}
        _CausticsColor("Caustics Color", Color) = (1, 1, 0.85, 1)
        _CausticsTiling("Caustics Tiling", Float) = 1.2
        _CausticsSpeed("Caustics Speed", Float) = 0.25
        _CausticsStrength("Caustics Strength", Range(0, 8)) = 1.5
        _CausticsDepthRange("Caustics Depth Range", Float) = 3.0
        _CausticsSharpness("Caustics Sharpness", Range(0.5, 4)) = 1.2
        
        _RippleOriginWS("Ripple Origin WS", Vector) = (0, 0, 0, 0)
        _RippleStartTime("Ripple Start Time", Float) = -1000

        _RippleSpeed("Ripple Speed", Float) = 2.0
        _RippleFrequency("Ripple Frequency", Float) = 18.0
        _RippleWidth("Ripple Width", Float) = 12.0
        _RippleLifetime("Ripple Lifetime", Float) = 3.0

        _RippleNormalStrength("Ripple Normal Strength", Float) = 0.12
        _RippleColor("Ripple Color", Color) = (1, 1, 1, 1)
        RippleColorStrength("Ripple Color Strength", Float) = 0.35
        
        _RippleFieldTex("Ripple Field Tex", 2D) = "black" {}
        _RippleFieldNormalStrength("Ripple Field Normal Strength", Float) = 1.2
        _RippleFieldColorStrength("Ripple Field Color Strength", Float) = 0.25
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            TEXTURE2D(_FoamTex);
            SAMPLER(sampler_FoamTex);
            TEXTURE2D(_CausticsTex);
            SAMPLER(sampler_CausticsTex);
            TEXTURE2D(_RippleFieldTex);
            SAMPLER(sampler_RippleFieldTex);

            
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float _DepthScale;
            
                float4 _NormalTex_ST;
                float _NormalTiling;
                float _NormalScale;
                float _NormalRefract;
                float _WaveXSpeed;
                float _WaveYSpeed;
            
                float _SpecularPower;
                float _SpecularStrength;

                half4 _ShallowColor;
                half4 _DeepColor;
                float _DepthColorRange;
                float _AlphaDepthRange;

                float4 _FoamTex_ST;
                half4 _FoamColor;
                float _FoamRange;
                float _FoamSoftness;
                float _FoamSpeed;
                float _FoamTiling;
                float _FoamStrength;

                float _RefractStrength;

                float _FresnelPower;
                float _FresnelStrength;
                half4 _ReflectionTint;
                float _ReflectionStrength;
                float _EnvReflectionRoughness;

                float4 _WaveA;
                float4 _WaveB;
                float _WaveSpeedA;
                float _WaveSpeedB;

                half4 _CrestFoamColor;
                float _CrestThreshold;
                float _CrestSoftness;
                float _CrestSlopeStrength;
                float _CrestFoamStrength;
                float _CrestFoamTiling;
                float _CrestFoamSpeed;

                float4 _CausticsTex_ST;
                half4 _CausticsColor;
                float _CausticsTiling;
                float _CausticsSpeed;
                float _CausticsStrength;
                float _CausticsDepthRange;
                float _CausticsSharpness;

                float4 _RippleOriginWS;
                float _RippleStartTime;
                
                float _RippleSpeed;
                float _RippleFrequency;
                float _RippleWidth;
                float _RippleLifetime;
                
                float _RippleNormalStrength;
                half4 _RippleColor;
                float _RippleColorStrength;

                float4 _RippleFieldTex_ST;
                float _RippleFieldNormalStrength;
                float _RippleFieldColorStrength;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv : TEXCOORD0;
                
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                float2 uv : TEXCOORD1;

                float3 tangentWS   : TEXCOORD2;
                float3 bitangentWS : TEXCOORD3;
                float3 normalWS    : TEXCOORD4;
                float waveHeight   : TEXCOORD5;
            };
            


            void ApplyGerstnerWave(
                float4 wave,
                float speed,
                float3 baseTangentWS,
                float3 baseBinormalWS,
                inout float3 positionWS,
                inout float3 tangentWS,
                inout float3 binormalWS
            )
            {
                float2 dir = normalize(wave.xy);
                float steepness = wave.z;
                float wavelength = max(wave.w, 0.001);

                float k = TWO_PI / wavelength;
                float a = steepness / k;

                float f = k * (dot(dir, positionWS.xz) - speed * _Time.y);

                float sinF = sin(f);
                float cosF = cos(f);

                // 顶点位移：仍然在世界空间里按波方向推动
                positionWS.x += dir.x * (a * cosF);
                positionWS.y += a * sinF;
                positionWS.z += dir.y * (a * cosF);

                // 关键：根据“基础切线/副切线”和波方向的关系，计算导数增量
                float du = dot(dir, normalize(baseTangentWS.xz));
                float dv = dot(dir, normalize(baseBinormalWS.xz));

                tangentWS += float3(
                    -dir.x * steepness * sinF * du,
                     steepness * cosF * du,
                    -dir.y * steepness * sinF * du
                );

                binormalWS += float3(
                    -dir.x * steepness * sinF * dv,
                     steepness * cosF * dv,
                    -dir.y * steepness * sinF * dv
                );
            }
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float baseHeightWS = OUT.positionWS.y;
                OUT.uv = TRANSFORM_TEX(IN.uv, _NormalTex);
                
                float3 baseNormalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                float3 baseTangentWS = normalize(TransformObjectToWorldDir(IN.tangentOS.xyz));

                float tangentSign = IN.tangentOS.w;
                float3 baseBinormalWS = normalize(cross(baseNormalWS, baseTangentWS) * tangentSign);
                
                float3 tangentWS = baseTangentWS;
                float3 binormalWS = baseBinormalWS;

                ApplyGerstnerWave(_WaveA, _WaveSpeedA, baseTangentWS, baseBinormalWS, OUT.positionWS, tangentWS, binormalWS);
                ApplyGerstnerWave(_WaveB, _WaveSpeedB, baseTangentWS, baseBinormalWS, OUT.positionWS, tangentWS, binormalWS);

                float3 normalWS = normalize(cross(binormalWS, tangentWS));
                tangentWS = normalize(tangentWS);
                binormalWS = normalize(cross(normalWS, tangentWS));

                OUT.tangentWS = tangentWS;
                OUT.bitangentWS = binormalWS;
                OUT.normalWS = normalWS;

                OUT.waveHeight = OUT.positionWS.y - baseHeightWS;
                OUT.positionHCS = TransformWorldToHClip(OUT.positionWS);

                return OUT;
            }
            
            
            float3 SampleFlowNormalTS(float2 uv)
            {
                float2 uv0 = uv * _NormalTiling;

                float2 flow1 = uv0 + float2(_WaveXSpeed * _Time.y, 0);
                float2 flow2 = float2(uv0.y, uv0.x) + float2(_WaveYSpeed * _Time.y, 0);

                float4 offsetSample = (SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, flow1) +
                                       SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, flow2)) * 0.5;

                float3 offsetNormal = UnpackNormal(offsetSample);
                float2 flowOffset = offsetNormal.xy * _NormalRefract;

                float3 n1 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, uv0 + flowOffset));
                float3 n2 = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, uv0 - flowOffset));

                float3 normalTS = normalize(n1 + n2);

                normalTS.xy *= _NormalScale;
                normalTS.z = sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy)));

                return normalTS;
            }

            float3 TransformTangentToWorldCustom(float3 normalTS, float3 tangentWS, float3 bitangentWS, float3 normalWS)
            {
                float3 worldNormal = normalize(
                tangentWS   * normalTS.x +
                bitangentWS * normalTS.y +
                normalWS    * normalTS.z);

                return worldNormal;
            }

            float SampleCaustics(float3 positionWS)
            {
                float2 uv1 = positionWS.xz * _CausticsTiling;
                float2 uv2 = positionWS.xz * (_CausticsTiling * 1.31);
            
                uv1 += float2(_CausticsSpeed * _Time.y, _CausticsSpeed * 0.35 * _Time.y);
                uv2 += float2(-_CausticsSpeed * 0.27 * _Time.y, _CausticsSpeed * 0.83 * _Time.y);
            
                float c1 = SAMPLE_TEXTURE2D(_CausticsTex, sampler_CausticsTex, uv1).r;
                float c2 = SAMPLE_TEXTURE2D(_CausticsTex, sampler_CausticsTex, uv2).r;
            
                float caustics = saturate(c1 + c2 - 0.65);
                caustics = pow(caustics, max(_CausticsSharpness, 0.0001));
            
                return caustics;
            }
            
            #define MAX_RIPPLES 4
            
            float4 _RippleOriginsWS[MAX_RIPPLES];
            float _RippleStartTimes[MAX_RIPPLES];
            
            float ComputeRippleSingle(
                float2 positionXZ,
                float2 rippleOriginXZ,
                float rippleStartTime,
                out float2 rippleDir,
                out float rippleRingMask
            )
            {
                float t = _Time.y - rippleStartTime;
            
                rippleDir = float2(0, 0);
                rippleRingMask = 0;
            
                if (t < 0.0 || t > _RippleLifetime)
                    return 0.0;
            
                float2 delta = positionXZ - rippleOriginXZ;
                float dist = length(delta);
            
                if (dist > 0.0001)
                    rippleDir = delta / dist;
            
                float waveFront = t * _RippleSpeed;
                float local = dist - waveFront;
            
                float envelope = exp(-abs(local) * _RippleWidth);
                envelope *= (1.0 - t / _RippleLifetime);
            
                float rippleWave = sin(local * _RippleFrequency) * envelope;
            
                rippleRingMask = saturate(envelope);
            
                return rippleWave;
            }
            
            void AccumulateRipples(
                float2 positionXZ,
                out float2 rippleOffsetXZ,
                out float rippleRingMask
            )
            {
                rippleOffsetXZ = float2(0, 0);
                rippleRingMask = 0.0;
            
                [unroll]
                for (int i = 0; i < MAX_RIPPLES; i++)
                {
                    float2 dir;
                    float ringMask;
            
                    float wave = ComputeRippleSingle(
                        positionXZ,
                        _RippleOriginsWS[i].xz,
                        _RippleStartTimes[i],
                        dir,
                        ringMask
                    );
            
                    rippleOffsetXZ += dir * wave;
                    rippleRingMask += ringMask;
                }
            
                rippleRingMask = saturate(rippleRingMask);
            }
            
            half4 frag(Varyings IN) : SV_Target
            {
                float2 screenUV = IN.positionHCS.xy / _ScaledScreenParams.xy;

                #if UNITY_REVERSED_Z
                    float sceneDepthRaw = SampleSceneDepth(screenUV);
                #else
                    float sceneDepthRaw = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(screenUV));
                #endif

                float sceneEyeDepth = LinearEyeDepth(sceneDepthRaw, _ZBufferParams);

                float3 positionVS = TransformWorldToView(IN.positionWS);
                float waterEyeDepth = -positionVS.z;

                float deltaDepth = max(0, sceneEyeDepth - waterEyeDepth);

                float depthLerp = saturate(deltaDepth / max(_DepthColorRange, 0.0001));
                float alpha = saturate(deltaDepth / max(_AlphaDepthRange, 0.0001));

                float3 waterDepthColor = lerp(_ShallowColor.rgb, _DeepColor.rgb, depthLerp);
                
                float3 normalTS = SampleFlowNormalTS(IN.uv);

                float3 worldNormal = TransformTangentToWorldCustom(
                    normalTS,
                    normalize(IN.tangentWS),
                    normalize(IN.bitangentWS),
                    normalize(IN.normalWS)
                );

                float2 rippleOffsetXZ;
                float rippleRingMask;
                AccumulateRipples(IN.positionWS.xz, rippleOffsetXZ, rippleRingMask);
                
                worldNormal = normalize(
                    worldNormal + float3(rippleOffsetXZ.x, 0, rippleOffsetXZ.y) * _RippleNormalStrength
                );

                
                
                float2 refractOffset = normalTS.xy * _RefractStrength;
                float2 refractUV = screenUV + refractOffset;
                float3 refractColor = SampleSceneColor(refractUV);

                float shallowCausticsMask = 1.0 - saturate(deltaDepth / max(_CausticsDepthRange, 0.0001));
                float causticsTex = SampleCaustics(IN.positionWS);
                float caustics = causticsTex * shallowCausticsMask * _CausticsStrength;
                
                Light mainLight = GetMainLight();

                float3 lightDir = normalize(mainLight.direction);
                float3 viewDir = normalize(_WorldSpaceCameraPos - IN.positionWS);
                float3 halfDir = normalize(lightDir + viewDir);

                float NdotL = saturate(dot(worldNormal, lightDir));
                float NdotH = saturate(dot(worldNormal, halfDir));

                float3 diffuse = waterDepthColor * NdotL * mainLight.color;
                float3 specular = pow(NdotH, _SpecularPower) * _SpecularStrength * mainLight.color;

                float3 litWater = diffuse + specular;
                
                float foamMask = 1.0 - saturate(deltaDepth / max(_FoamRange, 0.0001));
                foamMask = pow(foamMask, max(_FoamSoftness, 0.0001));

                float2 foamUV = TRANSFORM_TEX(IN.uv, _FoamTex);
                foamUV *= _FoamTiling;
                foamUV += float2(_FoamSpeed * _Time.y, _FoamSpeed * _Time.y);

                float foamTex = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, foamUV).r;
                float foam = foamTex * foamMask * _FoamStrength;
                float3 foamCol = foam * _FoamColor.rgb;

                float crestHeightMask = saturate(
                    (IN.waveHeight - _CrestThreshold) / max(_CrestSoftness, 0.0001)
                );

                float crestSlopeMask = pow(
                    saturate(1.0 - normalize(IN.normalWS).y),
                    _CrestSlopeStrength
                );

                float crestMask = saturate(crestHeightMask * crestSlopeMask);

                float2 crestUV = TRANSFORM_TEX(IN.uv, _FoamTex);
                crestUV *= _CrestFoamTiling;
                crestUV += float2(_CrestFoamSpeed * _Time.y, _CrestFoamSpeed * _Time.y);

                float crestTex = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, crestUV).r;
                float crestFoam = crestTex * crestMask * _CrestFoamStrength;
                float3 crestFoamCol = crestFoam * _CrestFoamColor.rgb;

                float fresnel = pow(1.0 - saturate(dot(worldNormal, viewDir)), _FresnelPower);
                fresnel *= _FresnelStrength;
                fresnel = saturate(fresnel);

                float3 reflectVector = reflect(-viewDir, worldNormal);

                half3 envReflection = GlossyEnvironmentReflection(
                    reflectVector,
                    IN.positionWS,
                    _EnvReflectionRoughness,
                    1.0h,
                    screenUV
                );

                envReflection *= _ReflectionTint.rgb * _ReflectionStrength;

                // float3 tintedRefract = refractColor * waterDepthColor;
                // float3 waterBodyBase = lerp(tintedRefract, litWater, 0.75);
                
                //float3 waterBodyBase = lerp(refractColor, litWater, 0.9);
                float3 tintedRefract = refractColor * waterDepthColor;
                float3 waterBodyBase = lerp(tintedRefract, litWater, 0.75);
                float3 waterBody = lerp(waterBodyBase, envReflection, fresnel);

                float3 causticsCol = caustics * _CausticsColor.rgb * (1.0 - fresnel) * 2.0;
                waterBody += causticsCol;
                
                float3 rippleCol = rippleRingMask * _RippleColor.rgb * _RippleColorStrength;
                float3 finalCol = waterBody + foamCol + crestFoamCol + rippleCol;

                return half4(finalCol, alpha * _BaseColor.a);
            }
            ENDHLSL
        }
    }
}