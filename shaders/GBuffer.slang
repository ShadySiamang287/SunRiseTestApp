import common;

[[vk::binding(0, 0)]] Texture2D<float4> gTextures[];
[[vk::binding(1, 0)]] SamplerState gTextureSampler;

[shader("fragment")]
GBufferOutput gBufferFrag(VSOutput vertIn) {

    uint textureIndex = NonUniformResourceIndex(vertIn.albedoTextureIndex);
    float4 texel = gTextures[textureIndex].Sample(gTextureSampler, vertIn.uv);

    GBufferOutput output;
    output.albedo = texel * float4(vertIn.color, 1);
    output.normal = float4(normalize(vertIn.normal), 1);
    return output;
}