#include <EntryPoint.h>

class GameApp : public SUN::Application{
public:
    GameApp(){

    }

};

SUN::Application* SUN::CreateApplication() {
    return new GameApp();
}
