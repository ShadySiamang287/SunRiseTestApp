import common;

[[vk::input_attachment_index(0)]]
SubpassInput<float4> gAlbedo;

[[vk::input_attachment_index(1)]]
SubpassInput<float4> gNormal;

[shader("fragment")]
float4 lightFrag(FullPassVertOut input) : SV_Target0 {
    return gAlbedo.SubpassLoad();
}