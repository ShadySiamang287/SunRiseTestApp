import common;

[shader("fragment")]
GBufferOutput gBufferFrag(VSOutput vertIn) {
    GBufferOutput output;
    output.albedo = float4(vertIn.color, 1.0);
    output.normal = float4(normalize(vertIn.normal), 1.0);
    return output;
}