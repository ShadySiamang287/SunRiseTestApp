import common;

[[vk::binding(0, 0)]]
Texture2D<float4> gAlbedo;

[[vk::binding(1, 0)]]
Texture2D<float4> gNormal;

[[vk::binding(2, 0)]]
Texture2D<float> gDepth;

[[vk::binding(3, 0)]]
SamplerState gSampler;

float3 ReconstructWorldPosition(float2 texCoord, float depth, FrameData frameData) {
    float2 ndc = texCoord * 2.0 - 1.0;
    ndc.y = 1.0f - texCoord.y * 2.0f;
    float4 clipSpacePosition = float4(ndc, depth, 1.0);

    float4 viewPosition = mul(frameData.inverseProjection, clipSpacePosition);
    viewPosition /= viewPosition.w;

    float4 worldPosition = mul(frameData.inverseView, viewPosition);
    return worldPosition.xyz;
}

float3 CalculateDirectionalLight(DirectionalLight light, float3 normal, float3 albedo) {
    float3 lightDir = normalize(-light.directionIntensity.xyz);
    float intensity = light.directionIntensity.w;
    float3 colour = light.color.rgb;
    float NdotL = max(dot(normal, lightDir), 0.0);
    return albedo * colour * intensity * NdotL;
}

float3 CalculatePointLight( PointLight light, float3 worldPosition, float3 normal, float3 albedo) {
    float3 lightPosition =
        light.positionRange.xyz;

    float range =
        light.positionRange.w;

    float3 lightColor =
        light.colorIntensity.xyz;

    float intensity =
        light.colorIntensity.w;

    float3 toLight =
        lightPosition - worldPosition;

    float distanceToLight =
        length(toLight);

    if (distanceToLight >= range)
        return float3(0.0f);

    float3 lightDirection =
        toLight / max(distanceToLight, 0.0001f);

    float NdotL =
        max(dot(normal, lightDirection), 0.0f);

    // Smoothly reach zero at the specified range.
    float rangeFactor =
        saturate(1.0f - distanceToLight / range);

    rangeFactor *= rangeFactor;

    //Simple inverse-square-ish attenuation.
    float attenuation =
        rangeFactor /
        max(distanceToLight * distanceToLight, 0.01f);

    return albedo
        * lightColor
        * intensity
        * NdotL
        * attenuation;
}

[shader("fragment")]
float4 lightFrag(FullPassVertOut input) : SV_Target0 {
    FrameData frameData = pc.frameData[0];

    PointLight light = pc.pointLights[0];

    float2 texCoord = float2(input.uv.x, 1.0 - input.uv.y);

    float3 albedo = gAlbedo.SampleLevel(gSampler, texCoord, 0).xyz;
    float3 normal = normalize(gNormal.SampleLevel(gSampler, texCoord, 0).xyz);
    float depth = gDepth.SampleLevel(gSampler, texCoord, 0);

    if (depth >= 1.0)
        return float4(0.02, 0.02, 0.02, 1.0);

    float3 worldPosition = ReconstructWorldPosition(texCoord, depth, frameData);

    float3 lighting = albedo * 0.03;

    for (uint i = 0; i < frameData.directionalLightCount; ++i) {
        lighting += CalculateDirectionalLight(pc.directionalLights[i], normal, albedo);
    }

    for (uint i = 0; i < frameData.pointLightCount; ++i) {
        lighting += CalculatePointLight(pc.pointLights[i], worldPosition, normal, albedo);
    }
    return float4(lighting, 1.0);
}