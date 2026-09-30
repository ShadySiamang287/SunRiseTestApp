import common;

[[vk::binding(0, 0)]] Texture2D<float4> gTextures[];
[[vk::binding(1, 0)]] SamplerState gTextureSampler;

float3 CalculateNormal(float2 uv, float3 normal, float4 tangent, uint normalTextureIndex) {
    float3 N = normalize(normal);
    float3 T = normalize(tangent.xyz);

    T = normalize(T - N * dot(N, T));
    float3 B = cross(N, T) * tangent.w;
    float3 sampledNormal = gTextures[NonUniformResourceIndex(normalTextureIndex)].Sample(gTextureSampler, uv).xyz;
    sampledNormal = sampledNormal * 2.f - 1.f;
    float3x3 TBN = float3x3(T, B, N);

    return normalize(mul(sampledNormal, TBN));
}

[shader("fragment")]
GBufferOutput gBufferFrag(VSOutput vertIn) {

    uint albedoIndex = NonUniformResourceIndex(vertIn.albedoTextureIndex);
    uint metallicRoughnessIndex = NonUniformResourceIndex(vertIn.materialTextureIndex);
    float4 albedoSample = gTextures[albedoIndex].Sample(gTextureSampler, vertIn.uv);
    float4 metallicRoughnessSample = gTextures[metallicRoughnessIndex].Sample(gTextureSampler,vertIn.uv);

    float3 baseColor = albedoSample.rgb * vertIn.color;
    float metallic = metallicRoughnessSample.b * vertIn.metallicFactor;
    float roughness = metallicRoughnessSample.g * vertIn.roughnessFactor;

    float3 worldNormal = CalculateNormal(vertIn.uv, vertIn.normal, vertIn.tangent, vertIn.normalTextureIndex);
    GBufferOutput output;

    /// RGB = Base colour
    /// A = metallic
    output.albedo = float4(baseColor, metallic);

    /// RGB = Normal
    /// A = roughness
    output.normal = float4(worldNormal, roughness);
    return output;
}