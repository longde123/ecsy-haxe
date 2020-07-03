import ecsy.Query.Matcher;
import haxe.ds.Either;

import ecsy.World;
import ecsy.System;
import ecsy.Component;
class Hello extends Component {

}
typedef HelloQueries = {hello:Matcher};

class HelloSystem extends System {
    var queries:HelloQueries;
    var queries_hello:Matcher;
    // This method will get called on every frame by default
    public function new(world, attributes) {
        super(world, attributes);
        queries_hello=new Matcher().allOf([Hello]);
        // Define a query of entities that have "Velocity" and "Position" components
        queries = {
            hello:  queries_hello
        };
        var querieConfigs=[queries_hello];
        initQueries(querieConfigs);
    }

    override public function execute(delta:Float, time:Float) {
        trace("hello_execute");
        for(r in queries_hello.added){
            trace("hello_added");
            trace(r.getComponent(Hello));
        }
        for(r in queries_hello.removed){
            trace("hello_removed");
            trace(r );
        }
        for(r in queries_hello.results){
            trace("hello_results");
            trace(r.getComponent(Hello) );
        }


    }

}

class Main {

    static public function main() {
       new Main();
    }
    var world : World;
    var lastTime:Float  ;
    public function new():Void {

        lastTime=0;
        // Create world and register the components and systems on it
        world = new World();
        world.registerComponent(Hello);
        world.registerSystem(HelloSystem);

        var entity= world.createEntity().addComponent(Hello);


        trace("Hello, world 1");
        run();
        trace("Hello, world 2");
        run();

        trace("Hello, world 3");
        entity.removeComponent(Hello);
        run();

    }

    function run  () {

        // Compute delta and elapsed time

        var time = Date.now().getTime();
        var delta = time - lastTime;

        // Run all the systems
        world.execute(delta, time);

        lastTime = time;
    }
}
