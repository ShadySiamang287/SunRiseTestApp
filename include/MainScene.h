#pragma once

#include <SceneManagement/BaseScene.h>
#include <vulkan/vulkan_raii.hpp>

#include <Graphics/Buffers.h>

#include <glm/glm.hpp>

#include <Graphics/vertex.h>

class MainScene : public SUN::BaseScene{
public:
    MainScene();
    ~MainScene() override;

    void Update(const float& dt) override;
    void Render(SUN::RenderContext& context) override;
};
