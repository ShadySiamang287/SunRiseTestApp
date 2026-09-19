import common;

[[vk::binding(0, 0)]]
Texture2D<float4> hdrIn;

[[vk::binding(1, 0)]]
SamplerState gSampler;

[shader("fragment")]
float4 toneMappingFrag(FullPassVertOut input) : SV_Target0 {
    float2 texCoord = float2(input.uv.x, 1.0 - input.uv.y);
    float3 hdrColor = hdrIn.SampleLevel(gSampler, texCoord, 0).xyz;

    // Reinhard tone mapping
    float3 mappedColor = hdrColor / (hdrColor + 1.0);

    return float4(mappedColor, 1.0);

}