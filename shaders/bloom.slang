
import common;

struct BloomPushContants {
    bool horizontal;
}

static const float weights[5] = {
    0.227027,
    0.1945946,
    0.1216216,
    0.054054,
    0.016216
};

[[vk::binding(0, 0)]]
Texture2D<float4> bloomImage;

[[vk::binding(1, 0)]]
SamplerState gSampler;

[[vk::push_constant]]
BloomPushContants pc;

[shader("fragment")]
float4 bloom(FullPassVertOut input) {
    float2 uv = float2(input.uv.x, 1.0 - input.uv.y);

    uint width;
    uint height;
    bloomImage.GetDimensions(width, height);

    float2 texelSize = 1.0 / float2(width, height);

    float3 result = bloomImage.SampleLevel(gSampler, uv,0) .rgb * weights[0];

    if (pc.horizontal != 0)
    {
        for (int i = 1; i < 5; ++i)
        {
            float2 offset = float2(texelSize.x * i, 0.0);

            result += bloomImage.SampleLevel(
                              gSampler,
                              uv + offset,
                              0
                ) .rgb * weights[i];

            result += bloomImage.SampleLevel(
                              gSampler,
                              uv - offset,
                              0
                ) .rgb * weights[i];
        }
    }
    else
    {
        for (int i = 1; i < 5; ++i)
        {
            float2 offset =float2(0.0, texelSize.y * i);

            result += bloomImage.SampleLevel(
                              gSampler,
                              uv + offset,
                              0
                ) .rgb * weights[i];

            result += bloomImage.SampleLevel(
                              gSampler,
                              uv - offset,
                              0
                ) .rgb * weights[i];
        }
    }
    return float4(result, 1.0);
}