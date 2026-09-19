import common;

[[vk::binding(0, 0)]]
Texture2D<float4> hdrIn;

[[vk::binding(1, 0)]]
Texture2D<float4> bloomIn;

[[vk::binding(2, 0)]]
SamplerState gSampler;

float3 ReinhardLuminance(float3 color)
{
    float luminance =
        dot(color, float3(0.2126, 0.7152, 0.0722));

    float mappedLuminance =
        luminance / (1.0 + luminance);

    return color *
           (mappedLuminance / max(luminance, 0.0001));
}

[shader("fragment")]
float4 toneMappingFrag(FullPassVertOut input) : SV_Target0 {
    float2 texCoord = float2(input.uv.x, 1.0 - input.uv.y);
    float3 hdrColor = hdrIn.SampleLevel(gSampler, texCoord, 0).xyz;

    float3 bloomColor = bloomIn.SampleLevel(gSampler, texCoord, 0).rgb;

    float bloomStrength = 0.1;

    float3 combined = hdrColor + bloomColor * bloomStrength;

    // ACES tone mapping
    float3 mappedColor = ReinhardLuminance(combined);

    return float4(mappedColor, 1.0);

}