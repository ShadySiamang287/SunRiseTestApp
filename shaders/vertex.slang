import common;

[[vk::push_constant]]
PushConstant pc;

[shader("vertex")]
VSOutput vertMain(VSInput input,uint instanceID: SV_VulkanInstanceID) {
    FrameData frameData = pc.frameData[0];
    ObjectData obj = pc.objectData[instanceID];
    
    float4 worldPos = mul(obj.model, float4(input.inPosition, 1.0));
    
    VSOutput output;
    output.pos = mul(frameData.projection, mul(frameData.view, worldPos));
    output.normal = normalize(mul((float3x3)obj.normalMatrix, input.inNormal)); // Use the input normal value
    output.color = input.inColor;
    output.uv = input.inUV;
    output.albedoTextureIndex = obj.albedoTextureIndex;
    return output;
}