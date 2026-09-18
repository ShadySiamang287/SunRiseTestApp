import common;

[shader("fragment")]
GBufferOutput gBufferFrag(VSOutput vertIn) {
    GBufferOutput output;
    output.normal = float4(vertIn.color, 1);
    output.albedo = float4(vertIn.normal, 1);
    return output;
}