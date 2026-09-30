#include <EntryPoint.h>
#include "GameLayer.h"

class GameApp : public SUN::Application{
public:
    GameApp(){
        PushLayer(std::make_unique<GameLayer>(GetAssetManager()));
    }
};

SUN::Application* SUN::CreateApplication() {
    return new GameApp();
}
