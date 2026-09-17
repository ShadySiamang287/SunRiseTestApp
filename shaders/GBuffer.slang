import common;

[shader("fragment")]
GBufferOutput gBufferFrag(VSOutput vertIn) {
    GBufferOutput output;
    output.albedo = float4(vertIn.color, 1);
    output.normal = float4(0, 1, 0, 1);
    return output;
}