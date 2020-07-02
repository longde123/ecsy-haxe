import haxe.ds.Either;

import ecsy.World;
import ecsy.System;
import ecsy.Component;
class Hello extends Component {

}
typedef HelloQueries = {hello:Matcher};

class HelloSystem extends System {
    var queries:HelloQueries;
    // This method will get called on every frame by default
    public function new(world, attributes) {
        super(world, attributes);

        // Define a query of entities that have "Velocity" and "Position" components
        queries = {
            hello:  new Matcher().allOf([Hello])
        };
        initQueries(queries);
    }

    override public function execute(delta:Float, time:Float) {
        trace("hello");
    }

}

class Main {

    static public function main() {
        trace("Hello, world!");
        // Create world and register the components and systems on it
        var world = new World();
        world.registerComponent(Hello);
        world.registerSystem(HelloSystem);
        world.createEntity().addComponent(Hello);

        var lastTime:Float = 0;
        var run = function() {
            // Compute delta and elapsed time
            var time = Date.now().getTime();
            var delta = time - lastTime;

            // Run all the systems
            world.execute(delta, time);

            lastTime = time;
        }
        run();
    }

}
