import common;

static const float PI = 3.14159265359;

[[vk::binding(0, 0)]]
Texture2D<float4> gAlbedo;

[[vk::binding(1, 0)]]
Texture2D<float4> gNormal;

[[vk::binding(2, 0)]]
Texture2D<float> gDepth;

[[vk::binding(3, 0)]]
Texture2D<float> gSSAO;

[[vk::binding(4, 0)]]
SamplerState gSampler;

[[vk::push_constant]]
PushConstant pc;

struct LightingOut {
    float4 color : SV_Target0;
    float4 bright : SV_Target1;
}

float3 ReconstructWorldPosition(float2 texCoord, float depth, FrameData frameData) {
    float2 ndc = texCoord * 2.0 - 1.0;
    ndc.y = 1.0f - texCoord.y * 2.0f;
    float4 clipSpacePosition = float4(ndc, depth, 1.0);

    float4 viewPosition = mul(frameData.inverseProjection, clipSpacePosition);
    viewPosition /= viewPosition.w;

    float4 worldPosition = mul(frameData.inverseView, viewPosition);
    return worldPosition.xyz;
}

float3 CalculateDirectionalLight(DirectionalLight light, float3 normal, float3 viewDirection, float3 albedo, float metallic, float roughness) {
    float3 lightDir = normalize(-light.directionIntensity.xyz);
    float intensity = light.directionIntensity.w;
    float3 colour = light.color.rgb;

    float3 radiance = colour * intensity;

    return EvaluateBRDF(normal, viewDirection, lightDir, albedo, metallic, roughness, radiance);
}

float3 CalculatePointLight( PointLight light, float3 worldPosition, float3 normal, float3 viewDirection, float3 albedo, float metallic, float roughness) {
    float3 lightPosition = light.positionRange.xyz;

    float range =
        light.positionRange.w;

    float3 lightColor = light.colorIntensity.xyz;

    float intensity = light.colorIntensity.w;

    float3 toLight = lightPosition - worldPosition;

    float distanceToLight = length(toLight);

    if (distanceToLight >= range)
        return float3(0.0f);

    float3 lightDirection = toLight / max(distanceToLight, 0.0001f);

    float rangeFactor = saturate(1.0 - distanceToLight / range);
    rangeFactor *= rangeFactor;

    //Simple inverse-square-ish attenuation.
    float attenuation = rangeFactor / max(distanceToLight * distanceToLight, 0.01f);

    float3 radiance = lightColor * intensity * attenuation;

    return EvaluateBRDF(normal, viewDirection, lightDirection, albedo, metallic, roughness, radiance);
}

float4 CalculateLighting(float2 texCoord, float3 albedo, float3 normal, float metallic, float roughness, float depth, float occlusion, FrameData frameData) {

    if (depth >= 1.0)
        return float4(0.02, 0.02, 0.02, 1.0);

    float3 worldPosition = ReconstructWorldPosition(texCoord, depth, frameData);

    float3 lighting = albedo * 0.03 * occlusion;

    float3 viewDirection = normalize(frameData.cameraPosition.xyz - worldPosition);

    for (uint i = 0; i < frameData.directionalLightCount; ++i) {
        lighting += CalculateDirectionalLight(pc.directionalLights[i], normal, viewDirection, albedo, metallic, roughness);
    }

    for (uint i = 0; i < frameData.pointLightCount; ++i) {
        lighting += CalculatePointLight(pc.pointLights[i], worldPosition, normal, viewDirection, albedo, metallic, roughness);
    }

    return float4(lighting, 1.f);
}

[shader("fragment")]
LightingOut lightFrag(FullPassVertOut input) : SV_Target0 {
    FrameData frameData = pc.frameData[0];


    float2 texCoord = float2(input.uv.x, 1.0 - input.uv.y);

    float4 albedoSample = gAlbedo.SampleLevel(gSampler, texCoord, 0);
    float4 normalSample = gNormal.SampleLevel(gSampler, texCoord, 0);

    float3 albedo = albedoSample.rgb;
    float3 normal = normalize(normalSample.rgb);

    float occlusion = gSSAO.Sample(gSampler, texCoord);

    float metallic = albedoSample.a;
    metallic = saturate(metallic);
    float roughness = normalSample.a;
    roughness = clamp(roughness, 0.04, 1.f);
    float depth = gDepth.SampleLevel(gSampler, texCoord, 0);

    LightingOut output;
    float4 lighting = CalculateLighting(texCoord, albedo, normal, metallic, roughness, depth, occlusion, frameData);
    output.color = lighting;

    float brightness = dot(
        lighting.xyz,
        float3(0.2126, 0.7152, 0.0722)
    );

    if (brightness > 1.0)
        output.bright = lighting;
    else
        output.bright = float4(0.0, 0.0, 0.0, 1.0);

    return output;
}

float DistributionGGX(float3 N, float3 H, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;

    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;

    float denominator = NdotH2 * (a2 - 1.0) + 1.0;

    denominator = PI * denominator * denominator;

    return a2 / max(denominator, 0.000001);
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;

    return NdotV / (NdotV * (1.0 - k) + k);
}

float GeometrySmith(float3 N, float3 V, float3 L, float roughness){
    float NdotV = max(dot(N, V), 0.0);

    float NdotL = max(dot(N, L), 0.0);

    float ggxV = GeometrySchlickGGX(NdotV, roughness);

    float ggxL = GeometrySchlickGGX(NdotL, roughness);

    return ggxV * ggxL;
}

float3 FresnelSchlick(float cosTheta, float3 F0){
    return F0 + (1.0 - F0) * pow(saturate(1.0 - cosTheta), 5.0);
}

float3 EvaluateBRDF(float3 N,float3 V,float3 L,float3 albedo,float metallic, float roughness, float3 radiance){
    float NdotL = max(dot(N, L), 0.0);

    float NdotV = max(dot(N, V), 0.0);

    if (NdotL <= 0.0 || NdotV <= 0.0)
        return float3(0.0);

    float3 H = normalize(V + L);

    // Dielectrics use roughly 4% reflectance.
    // Metals use their base colour as F0.
    float3 F0 = lerp(float3(0.04), albedo, metallic);

    float D = DistributionGGX(N, H, roughness);

    float G = GeometrySmith(N, V, L, roughness);

    float3 F = FresnelSchlick(max(dot(H, V), 0.0), F0);

    float3 numerator = D * G * F;

    float denominator = 4.0 * NdotV * NdotL;

    float3 specular = numerator / max(denominator, 0.0001);

    float3 kS = F;

    float3 kD =float3(1.0) - kS;

    // Metals do not have diffuse reflection.
    kD *= 1.0 - metallic;

    float3 diffuse = kD * albedo / PI;

    return (diffuse + specular) * radiance * NdotL;
}