#include "MainScene.h"

#include <AssetManagement/AssetManager.h>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include <filesystem>
#include <memory>
#include <vector>

#include <Renderer/Renderer3D.h>
#include <SceneManagement/Entity.h>
#include <SceneManagement/Systems/RenderSystem.h>
#include <SceneManagement/Components.h>

#include <Logger.h>

#include "FlyCameraSystem.h"

MainScene::MainScene(SUN::AssetManager& assetManager) {
    using namespace SUN;

    // -------------------------------------------------------------------------
    // Camera
    // -------------------------------------------------------------------------

    Entity cameraEntity = CreateEntity("Camera");
    cameraEntity.AddComponent<CameraComponent>();
    cameraEntity.AddComponent<FlyCameraComponent>();

    auto& camera =
        cameraEntity.GetComponent<CameraComponent>().Camera;

    camera.Position = {
        0.0f,
        5.0f,
        15.0f
    };

    // -------------------------------------------------------------------------
    // glTF / Sponza test
    // -------------------------------------------------------------------------

    const std::filesystem::path sponzaPath =
        "assets/glTF/Spoonza/sponza.glb";

    if (auto sponza = assetManager.LoadModel(sponzaPath)) {
        for (const auto& primitive : sponza->primitives) {
            Entity entity = CreateEntity(primitive.name);

            auto& meshComponent =
                entity.AddComponent<MeshComponent>();

            meshComponent.mesh = primitive.mesh;
            meshComponent.LocalTransform = primitive.transform;
            auto& material = entity.AddComponent<MaterialComponent>();
            material.AlbedoTexture = primitive.albedoTexture;
            material.NormalTexture = primitive.normalTexture;
            material.MaterialTexture = primitive.materialTexture;
            material.metalicFactor = primitive.metalicFactor;
            material.roughnessFactor = primitive.roughnessFactor;
        }
    } else {
        // ---------------------------------------------------------------------
        // Fallback bindless-texture test when Sponza has not been copied yet.
        // ---------------------------------------------------------------------

        const std::vector<Vertex> vertices = {
            // position               normal            colour              uv
            {{-0.5f, -0.5f, 0.0f}, {0.f, 0.f, 1.f}, {1.f, 1.f, 1.f}, {0.f, 1.f}},
            {{ 0.5f, -0.5f, 0.0f}, {0.f, 0.f, 1.f}, {1.f, 1.f, 1.f}, {1.f, 1.f}},
            {{ 0.5f,  0.5f, 0.0f}, {0.f, 0.f, 1.f}, {1.f, 1.f, 1.f}, {1.f, 0.f}},
            {{-0.5f,  0.5f, 0.0f}, {0.f, 0.f, 1.f}, {1.f, 1.f, 1.f}, {0.f, 0.f}}
        };

        const std::vector<uint32_t> indices = {
            0, 1, 2,
            2, 3, 0
        };

        auto mesh = std::make_shared<Mesh>();
        mesh->buffer.Init(
            vertices.data(),
            vertices.size() * sizeof(Vertex),
            sizeof(Vertex),
            indices.data(),
            indices.size() * sizeof(uint32_t),
            vk::IndexType::eUint32
        );

        const AssetID checkerTexture = assetManager.LoadTexture(
            "assets/textures/bindless_test_checker.png",
            true
        );

        const AssetID stripeTexture = assetManager.LoadTexture(
            "assets/textures/bindless_test_stripes.png",
            true
        );

        auto spawnPlane =
            [this, &mesh](
                const std::string& name,
                glm::vec3 position,
                AssetID albedoTexture)
            {
                Entity entity = CreateEntity(name);

                entity.AddComponent<MeshComponent>().mesh = mesh;
                entity.AddComponent<MaterialComponent>().AlbedoTexture =
                    albedoTexture;

                entity.GetComponent<TransformComponent>().Position =
                    position;
            };

        spawnPlane(
            "Checker",
            glm::vec3(-1.0f, 0.0f, 0.0f),
            checkerTexture
        );

        spawnPlane(
            "Stripes",
            glm::vec3(1.0f, 0.0f, 0.0f),
            stripeTexture
        );
    }

    // -------------------------------------------------------------------------
    // Lighting
    // -------------------------------------------------------------------------

    Entity directionalEntity =
        CreateEntity("Directional Light");

    auto& directional =
        directionalEntity.AddComponent<DirectionalLightComponent>();

    directional.Colour = {
        1.0f,
        0.95f,
        0.85f
    };

    directional.intensity = 1.5f;

    directionalEntity
        .GetComponent<TransformComponent>()
        .Rotation = glm::angleAxis(
            glm::radians(-35.0f),
            glm::vec3(1.0f, 0.0f, 0.0f)
        );

    // -------------------------------------------------------------------------
    // Point lights distributed through the atrium.
    // These are intentionally placed in pairs so roughness/metallic response
    // can be compared across both sides of the scene.
    // -------------------------------------------------------------------------

    auto spawnPointLight =
        [this](
            const std::string& name,
            const glm::vec3& position,
            const glm::vec3& colour,
            float intensity,
            float range)
        {
            Entity lightEntity = CreateEntity(name);

            auto& light =
                lightEntity.AddComponent<PointLightComponent>();

            light.Colour = colour;
            light.intensity = intensity;
            light.range = range;

            lightEntity
                .GetComponent<TransformComponent>()
                .Position = position;
        };

    constexpr float pointIntensity = 120.0f;
    constexpr float pointRange = 10.0f;

    spawnPointLight(
        "Point Light Left Front",
        {-4.0f, 2.5f, 6.0f},
        {1.0f, 0.72f, 0.52f},
        pointIntensity,
        pointRange
    );

    spawnPointLight(
        "Point Light Right Front",
        {4.0f, 2.5f, 6.0f},
        {0.52f, 0.72f, 1.0f},
        pointIntensity,
        pointRange
    );

    spawnPointLight(
        "Point Light Left Centre",
        {-4.0f, 2.5f, 0.0f},
        {1.0f, 0.85f, 0.65f},
        pointIntensity,
        pointRange
    );

    spawnPointLight(
        "Point Light Right Centre",
        {4.0f, 2.5f, 0.0f},
        {0.65f, 0.85f, 1.0f},
        pointIntensity,
        pointRange
    );

    spawnPointLight(
        "Point Light Left Rear",
        {-4.0f, 2.5f, -6.0f},
        {1.0f, 0.72f, 0.52f},
        pointIntensity,
        pointRange
    );

    spawnPointLight(
        "Point Light Right Rear",
        {4.0f, 2.5f, -6.0f},
        {0.52f, 0.72f, 1.0f},
        pointIntensity,
        pointRange
    );

    spawnPointLight(
        "Point Light Upper Front",
        {0.0f, 6.0f, 5.0f},
        {1.0f, 0.95f, 0.85f},
        160.0f,
        12.0f
    );

    spawnPointLight(
        "Point Light Upper Rear",
        {0.0f, 6.0f, -5.0f},
        {1.0f, 0.95f, 0.85f},
        160.0f,
        12.0f
    );
}

MainScene::~MainScene() {
}

void MainScene::Update(const float& dt) {
    FlyCameraSystem::Update(mRegistry, dt);
}

void MainScene::Render(SUN::RenderContext& context) {
    auto camView = mRegistry.view<SUN::CameraComponent>();
    SUN::Camera cam =
        camView.get<SUN::CameraComponent>(camView.front()).Camera;

    auto& renderer = context.renderer;
    renderer->BeginScene(cam);
    SUN::RenderSystem::Render(*this, renderer);
    renderer->EndScene(context);
}
