package ecsy;

import Lambda;
class SystemManager {
    public var _systems:Array<System>;
    public var _executeSystems:Array<System>;
    public var world:World;
    public var lastExecutedSystem:System;

    public function new(world) {
        this._systems = [];
        this._executeSystems = []; // Systems that have `execute` method
        this.world = world;
        this.lastExecutedSystem = null;
    }

    public function registerSystem(SystemClass:Class<System>, attributes) {
        var systemClass = this.getSystem(SystemClass);
        if (systemClass != null) {
            trace("System ${SystemClass} already registered.");
            return this;
        }

        var system:System = cast Type.createInstance(SystemClass, [this.world, attributes]);
        system.init(attributes);
        system.order = this._systems.length;
        this._systems.push(system);
        this._executeSystems.push(system);
        this.sortSystems();
        return this;
    }

    public function unregisterSystem(SystemClass) {
        var system = this.getSystem(SystemClass);
        if (system == null) {
            trace(
                "Can unregister system '${SystemClass.name}'. It doesn't exist."
            );
            return this;
        }

        this._systems.remove(system);

        this._executeSystems.remove(system);

        // @todo Add system.unregister() call to free resources
        return this;
    }

    public function sortSystems() {
        this._executeSystems.sort(function(a:System, b:System) {
            var p = a.priority - b.priority;
            if (p == 0) {
                p = a.order - b.order;
            }
            return p ;
        });
    }

    public function getSystem(SystemClass:Class<System>) {
        return Lambda.find(this._systems, function(s) return Std.is(s, SystemClass));
    }

    public function getSystems() {
        return this._systems;
    }

    public function removeSystem(SystemClass:System) {
        if (!Lambda.has(this._systems, SystemClass)) return;

        this._systems.remove(SystemClass);
    }

    public function executeSystem(system:System, delta, time) {

        if (system.initialized) {
            if (system.canExecute()) {
                var startTime = Date.now().getTime();
                system.execute(delta, time);
                system.executeTime = Date.now().getTime() - startTime;
                this.lastExecutedSystem = system;
                system.clearEvents();
            }
        }
    }


    public function stop() {
        for (system in this._executeSystems) {
            system.stop();
        }
    }

    public function execute(delta:Float, time:Float, forcePlay = false) {

        for (system in this._executeSystems) {

            if (forcePlay || system.enabled) {
                this.executeSystem(system, delta, time);
            }
        }
    }

    public function stats() {
        var stats = {
            numSystems: this._systems.length,
            systems: {}
        };
//
//        for (i in 0... this._systems.length) {
//            var system:System = this._systems[i];
//            var systemStats = (stats.systems[system.constructor.name] = {
//                queries: {},
//                executeTime: system.executeTime
//            });
//            for (name in system.ctx) {
//                systemStats.queries[name] = system.ctx[name].stats();
//            }
//        }

        return stats;
    }
}