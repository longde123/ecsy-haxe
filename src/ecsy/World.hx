package ecsy;

typedef WorldOptions = {
    entityPoolSize:Int
};
class World {

    public static var DEFAULT_OPTIONS:WorldOptions = {
        entityPoolSize: 0
    };
    public var options:WorldOptions;
    public var componentsManager:ComponentManager;
    public var entityManager:EntityManager;
    public var systemManager:SystemManager;
    public var enabled:Bool;
    public var lastTime:Float;

    public function new(options = null) {
        if (options == null) {
            options = DEFAULT_OPTIONS;
        }
        this.options = options;

        this.componentsManager = new ComponentManager();
        this.entityManager = new EntityManager(this);
        this.systemManager = new SystemManager(this);

        this.enabled = true;


        this.lastTime = Date.now().getTime();
    }

    public function registerComponent(Component) {
        this.componentsManager.registerComponent(Component);
        return this;
    }

    public function registerSystem(System, attributes = null) {
        this.systemManager.registerSystem(System, attributes);
        return this;
    }

    public function unregisterSystem(System) {
        this.systemManager.unregisterSystem(System);
        return this;
    }

    public function getSystem(SystemClass) {
        return this.systemManager.getSystem(SystemClass);
    }

    public function getSystems() {
        return this.systemManager.getSystems();
    }

    public function execute(delta:Float, time:Float) {

        if (delta == 0) {
            time = Date.now().getTime();
            delta = time - this.lastTime;
            this.lastTime = time;
        }
        if (this.enabled) {
            this.systemManager.execute(delta, time);
        }
    }

    public function stop() {
        this.enabled = false;
    }

    public function play() {
        this.enabled = true;
    }

    public function createEntity() {
        return this.entityManager.createEntity();
    }

    public function stats() {
//        var stats = {
//            entities: this.entityManager.stats(),
//            system: this.systemManager.stats()
//        };

        //  console.log(JSON.stringify(stats, null, 2));
    }
}