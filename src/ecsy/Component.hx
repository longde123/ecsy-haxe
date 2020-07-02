package ecsy;
typedef ComponentConstructor = Class<Component>;
class Component {


    public function new() {}

    public function copy(source:Dynamic) {
        return this;
    }

    public function clone() {
        return this;
    }

    public function reset() {}


}
class SystemStateComponent extends Component {}
class TagComponent extends Component {}


  
