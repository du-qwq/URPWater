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
            
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            TEXTURE2D(_FoamTex);
            SAMPLER(sampler_FoamTex);

            
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
            };
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _NormalTex);

                float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);
                float3 tangentWS = TransformObjectToWorldDir(IN.tangentOS.xyz);

                normalWS = normalize(normalWS);
                tangentWS = normalize(tangentWS);

                float tangentSign = IN.tangentOS.w;
                float3 bitangentWS = normalize(cross(normalWS, tangentWS) * tangentSign);

                OUT.tangentWS = tangentWS;
                OUT.bitangentWS = bitangentWS;
                OUT.normalWS = normalWS;
                
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
                
                float2 refractOffset = normalTS.xy * _RefractStrength;
                float2 refractUV = screenUV + refractOffset;
                float3 refractColor = SampleSceneColor(refractUV);
                
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
                
                float fresnel = pow(1.0 - saturate(dot(worldNormal, viewDir)), _FresnelPower);
                fresnel *= _FresnelStrength;
                fresnel = saturate(fresnel);

                float3 fakeReflection = _ReflectionTint.rgb * _ReflectionStrength;
                
                float3 waterBodyBase = lerp(refractColor, litWater, 0.6);
                float3 waterBody = lerp(waterBodyBase, fakeReflection, fresnel);
                
                float3 finalCol = waterBody + foamCol;

                return half4(finalCol, alpha * _BaseColor.a);
            }
            ENDHLSL
        }
    }
}