#include "FlyCameraSystem.h"

#include <SceneManagement/Components.h>
#include <Core/Input.h>
#include <Core/MouseCodes.h>

#define GLM_ENABLE_EXPERIMENTAL
#include <glm/gtx/norm.hpp>

#include <iostream>

void FlyCameraSystem::Update(entt::registry&  registry, const float& dt){
    using namespace SUN;
    auto cameras = registry.view<CameraComponent, FlyCameraComponent>();

    for (auto entity : cameras)
    {
        auto& camera = cameras.get<CameraComponent>(entity).Camera;
        auto& fly    = cameras.get<FlyCameraComponent>(entity);

        // Capture the mouse while looking around.
        if (Input::IsMousePressed(MouseButton::Right))
            Input::SetCursorMode(CursorMode::Disabled);

        if (Input::IsMouseReleased(MouseButton::Right))
            Input::SetCursorMode(CursorMode::Normal);

        // ---------------- Mouse Look ----------------

        if (Input::IsMouseDown(MouseButton::Right))
        {
            const glm::vec2 mouseDelta = Input::GetMouseDelta();

            fly.Yaw   += mouseDelta.x * fly.MouseSensitivity;
            fly.Pitch -= mouseDelta.y * fly.MouseSensitivity;

            fly.Pitch = glm::clamp(fly.Pitch, -89.0f, 89.0f);

            const glm::quat yawRotation =
                glm::angleAxis(glm::radians(fly.Yaw), glm::vec3(0.f, 1.f, 0.f));

            const glm::quat pitchRotation =
                glm::angleAxis(glm::radians(fly.Pitch), glm::vec3(1.f, 0.f, 0.f));

            camera.Rotation = glm::normalize(yawRotation * pitchRotation);
        }

        // ---------------- Movement ----------------

        glm::vec3 movement(0.0f);

        const glm::vec3 forward = camera.Rotation * glm::vec3(0.f, 0.f, -1.f);
        const glm::vec3 right   = camera.Rotation * glm::vec3(1.f, 0.f, 0.f);

        if (Input::IsKeyDown(KeyCode::W))
            movement += forward;

        if (Input::IsKeyDown(KeyCode::S))
            movement -= forward;

        if (Input::IsKeyDown(KeyCode::D))
            movement += right;

        if (Input::IsKeyDown(KeyCode::A))
            movement -= right;

        // World-space vertical movement.
        if (Input::IsKeyDown(KeyCode::Space))
            movement.y += 1.0f;

        if (Input::IsKeyDown(KeyCode::LeftCtrl))
            movement.y -= 1.0f;

        float speed = fly.MoveSpeed;

        if (Input::IsKeyDown(KeyCode::LeftShift))
            speed *= fly.SprintMultiplier;

        if (glm::length2(movement) > 0.0f)
        {
            camera.Position += glm::normalize(movement) * speed * dt;
        }
    }
}