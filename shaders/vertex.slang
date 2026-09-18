import common;

[shader("vertex")]
VSOutput vertMain(VSInput input) {
    VSOutput output;
    FrameData frameData = pc.frameData[0];
    output.pos = mul(frameData.projection, mul(frameData.view, float4(input.inPosition,  1.0)));
    output.color = input.inColor;
    output.normal = normalize(input.inNormal); // Use the input normal value
    return output;
}