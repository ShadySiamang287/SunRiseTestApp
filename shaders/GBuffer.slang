import common;

[[vk::binding(0, 0)]] Texture2D<float4> gTextures[];
[[vk::binding(1, 0)]] SamplerState gTextureSampler;

[[vk::push_constant]]
PushConstant pc;

float3 CalculateNormal(
    float2 uv,
    float3 normal,
    float4 tangent,
    uint normalTextureIndex
) {
    float3 N = normalize(normal);

    if (normalTextureIndex == 0) {
        return N;
    }

    float3 T = normalize(tangent.xyz);
    T = normalize(T - N * dot(N, T));

    float3 B = cross(N, T) * tangent.w;

    uint textureIndex =
        NonUniformResourceIndex(normalTextureIndex);

    float3 sampledNormal =
        gTextures[textureIndex]
            .Sample(gTextureSampler, uv)
            .xyz;

    sampledNormal = sampledNormal * 2.f - 1.f;

    float3x3 TBN = float3x3(T, B, N);

    return normalize(mul(sampledNormal, TBN));
}

[shader("fragment")]
GBufferOutput gBufferFrag(VSOutput vertIn) {
    MaterialData material =
        pc.materialData[vertIn.materialIndex];

    uint albedoIndex =
        NonUniformResourceIndex(material.albedoTextureIndex);

    uint metallicRoughnessIndex =
        NonUniformResourceIndex(material.materialTextureIndex);

    float4 albedoSample =
        gTextures[albedoIndex]
            .Sample(gTextureSampler, vertIn.uv);

    float4 metallicRoughnessSample =
        gTextures[metallicRoughnessIndex]
            .Sample(gTextureSampler, vertIn.uv);

    float3 baseColor =
        albedoSample.rgb * material.baseColorFactor.rgb;

    float metallic =
        metallicRoughnessSample.b * material.metallicFactor;

    float roughness =
        metallicRoughnessSample.g * material.roughnessFactor;

    float3 worldNormal =
        CalculateNormal(
            vertIn.uv,
            vertIn.normal,
            vertIn.tangent,
            material.normalTextureIndex
        );

    GBufferOutput output;

    // RGB = base colour, A = metallic.
    output.albedo = float4(baseColor, metallic);

    // RGB = normal, A = roughness.
    output.normal = float4(worldNormal, roughness);

    return output;
}
