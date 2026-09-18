#pragma once

#include <entt/entt.hpp>
struct FlyCameraComponent
{
    float MoveSpeed = 1.0f;
    float SprintMultiplier = 3.0f;
    float MouseSensitivity = 0.12f;

    float Yaw   = -90.0f;
    float Pitch = 0.0f;

    bool FirstMouse = true;
    float LastMouseX = 0.0f;
    float LastMouseY = 0.0f;
};

class FlyCameraSystem{
    public:
    static void Update(entt::registry&  registry, const float& dt);
};