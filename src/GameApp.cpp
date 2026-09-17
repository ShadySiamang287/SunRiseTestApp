#include <EntryPoint.h>
#include "GameLayer.h"

class GameApp : public SUN::Application{
public:
    GameApp(){
        PushLayer(std::make_unique<GameLayer>());
    }
};

SUN::Application* SUN::CreateApplication() {
    return new GameApp();
}
