import common;

[[vk::binding(0, 0)]]
Texture2D<float4> gAlbedo;

[[vk::binding(1, 0)]]
Texture2D<float4> gNormal;

[[vk::binding(2, 0)]]
Texture2D<float> gDepth;

[[vk::binding(3, 0)]]
SamplerState gSampler;

[shader("fragment")]
float4 lightFrag(FullPassVertOut input) : SV_Target0 {
    float4 albedo = gAlbedo.Sample(gSampler, input.uv);
    float3 normal = normalize(gNormal.Sample(gSampler, input.uv).xyz);
    float depth = gDepth.Sample(gSampler, input.uv);
    return albedo;
}