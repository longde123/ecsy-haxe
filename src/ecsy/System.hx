package ecsy;

import ecsy.Query.Matcher;


class System {

    public var world:World;
    public var enabled:Bool;
    public var _queries:Array<Query>;
    public var priority:Int;
    public var executeTime:Float;
    public var initialized:Bool;
    public var order:Int;
    var querieConfigs:Array<Matcher>;

    public function canExecute() {
        for (matcher in this.querieConfigs) {
            if (matcher.mandatory && matcher.results.length == 0) {
                return false;
            }
        }
        return true;
    }

    public function execute(delta:Float, time:Float) {

    }


    public function new(world,  priority:Int=0) {
        this.world = world;
        this.enabled = true;
        // @todo Better naming :)
        this._queries = [];
        this.priority = 0;
        // Used for stats
        this.executeTime = 0;
        this.priority =  priority;


        this.initialized = true;
    }

    public function initQueries(configQ:Array<Matcher>) {
        this.querieConfigs = configQ;

        for (query in this.querieConfigs) {
            configQueries(query);
        }
    }


    function configQueries(queryConfig:Matcher) {
        var Components = queryConfig.allOfComponents;
        if (Components.length == 0) {
            throw ("'components' attribute can't be empty in a query");
        }
        var query:Query = this.world.entityManager.queryComponents(queryConfig);

        this._queries.push(query) ;


        if (queryConfig.listen_added) {
            query.eventDispatcher.addEventListener(
                Query.ENTITY_ADDED,
                function(entity, comp) {
                    // @fixme overhead?
                    if (queryConfig.added.indexOf(entity) == -1)
                        queryConfig.added.push(entity);
                }
            );
        }
        if (queryConfig.listen_removed) {
            query.eventDispatcher.addEventListener(
                Query.ENTITY_REMOVED,
                function(entity, comp) {
                    // @fixme overhead?
                    if (queryConfig.removed.indexOf(entity) == -1)
                        queryConfig.removed.push(entity);
                }
            );

        }
        if (queryConfig.listen_changed) {
            query.reactive = true;
            query.eventDispatcher.addEventListener(
                Query.COMPONENT_CHANGED,
                function(entity, comp) {
                    // @fixme overhead?
                    if (queryConfig.changed.indexOf(entity) == -1)
                        queryConfig.changed.push(entity);
                }
            );

        }
    }

    public function stop() {
        this.executeTime = 0;
        this.enabled = false;
    }

    public function play() {
        this.enabled = true;
    }


    function clearEvent(query:Matcher) {
        if (query.listen_added) {
            query.added = [];
        }
        if (query.listen_removed) {
            query.removed = [];
        }
        if (query.listen_changed) {
            query.changed = [];
        }
    }
    // @question rename to clear queues?
    public function clearEvents() {
        for (query in this.querieConfigs) {
            clearEvent(query);
        }
    }

}
  

  