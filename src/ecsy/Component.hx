package ecsy;


typedef ComponentConstructor = Class<Component>;

class Component {


    public function new() {
        reset();
    }

    public function reset() {}


}
class SystemStateComponent extends Component {}
class TagComponent extends Component {}
class RemoveEntityTagComponent extends Component {}


  
