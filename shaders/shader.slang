struct VSInput {
    float2 inPosition;
    float3 inColor;
};

struct VSOutput
{
    float4 pos : SV_Position;
    float3 color;
};

struct FrameData {
    float4x4 model;
    float4x4 view;
    float4x4 projection;
}

struct PushConstant {
    FrameData* frameData;
}

[[vk::push_constant]]
PushConstant pc;

[shader("vertex")]
VSOutput vertMain(VSInput input) {
    VSOutput output;
    FrameData frameData = pc.frameData[0];
    output.pos = mul(frameData.projection, mul(frameData.view, mul(frameData.model, float4(input.inPosition, 0.0, 1.0))));
    output.color = input.inColor;
    return output;
}

[shader("fragment")]
float4 fragMain(VSOutput vertIn) : SV_TARGET {
    return float4(vertIn.color, 1.0);
}