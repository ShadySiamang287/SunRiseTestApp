import common;

[shader("vertex")]
VSOutput vertMain(VSInput input) {
    VSOutput output;
    FrameData frameData = pc.frameData[0];
    output.pos = mul(frameData.projection, mul(frameData.view, mul(frameData.model, float4(input.inPosition, 0.0, 1.0))));
    output.color = input.inColor;
    output.normal = float3(0.0, 0.0, 1.0); // Placeholder normal value
    return output;
}