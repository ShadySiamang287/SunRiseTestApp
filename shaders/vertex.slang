import common;

[[vk::push_constant]]
PushConstant pc;

[shader("vertex")]
VSOutput vertMain(VSInput input,
                  uint instanceID: SV_VulkanInstanceID,
                ) {
    VSOutput output;
    FrameData frameData = pc.frameData[0];
    ObjectData obj = pc.objectData[instanceID];
    float4 worldPos = mul(obj.model, float4(input.inPosition, 1.0));
    output.pos = mul(frameData.projection, mul(frameData.view, worldPos));
    output.color = input.inColor;
    output.normal = normalize(mul((float3x3)obj.normalMatrix, input.inNormal)); // Use the input normal value
    return output;
}