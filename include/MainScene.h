#pragma once

#include <SceneManagement/BaseScene.h>
#include <vulkan/vulkan_raii.hpp>

#include <Graphics/Buffers.h>

#define GLM_FORCE_RADIANS
#define GLM_FORCE_DEPTH_ZERO_TO_ONE
#include <glm/glm.hpp>

#include <Graphics/vertex.h>


struct FrameData {
    glm::mat4 model;
    glm::mat4 view;
    glm::mat4 proj;
};

class MainScene : public SUN::BaseScene{
public:
    MainScene();
    ~MainScene() override;

    void Update() override;
    void Render() override;

private:
    SUN::DescriptorResources mLightingDescriptors; 
    vk::raii::Pipeline mGbufferPipeline = nullptr;
    vk::raii::Pipeline mLightingPipeline = nullptr;
    vk::raii::PipelineLayout mPipelineLayout = nullptr;
    vk::raii::PipelineLayout mLightingLayout = nullptr;
    SUN::GeometryBuffer mMeshBuffer;
    SUN::ShaderBuffer mFrameDataBuffer;
    FrameData mFrameData;
};
