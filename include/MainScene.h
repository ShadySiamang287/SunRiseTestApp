#pragma once

#include <SceneManagement/BaseScene.h>
#include <vulkan/vulkan_raii.hpp>

#include <Graphics/Buffers.h>

#include <glm/glm.hpp>

#include <Graphics/vertex.h>

namespace SUN { class AssetManager; }

class MainScene : public SUN::BaseScene{
public:
    explicit MainScene(SUN::AssetManager& assetManager);
    ~MainScene() override;

    void Update(const float& dt) override;
    void Render(SUN::RenderContext& context) override;
};
