#pragma once

#include <SceneManagement/BaseScene.h>
#include <vulkan/vulkan_raii.hpp>

class MainScene : public SUN::BaseScene{
public:
    MainScene();
    ~MainScene() override = default;

    void Render() override;

private:
    vk::raii::Pipeline mPipeline = nullptr;
    vk::raii::PipelineLayout mPipelineLayout = nullptr;
};