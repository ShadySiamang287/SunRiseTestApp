import common;

[[vk::binding(0, 0)]]
Texture2D<float> gSSAO;

[[vk::binding(1, 0)]]
SamplerState gSampler;

[shader("fragment")]
float ssaoBlur(FullPassVertOut input) : SV_Target0 {

    float2 texCoord = float2(
        input.uv.x,
        1.0 - input.uv.y
    );

    uint width;
    uint height;
    gSSAO.GetDimensions(width, height);
    float2 texelSize = 1.0 / float2(width, height);
    float result = 0.0;
    for (int x = -2; x < 2; x++) {
        for (int y = -2; y < 2; y++) {
            float2 offset = float2(float(x), float(y)) * texelSize;
            result += gSSAO.Sample(gSampler, texCoord + offset).r;
        }
    }
    return result / (4.0 * 4.0);
}