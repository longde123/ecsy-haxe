package ecsy;

import ecsy.Component.ComponentConstructor;
import haxe.ds.Either;
import haxe.macro.Expr.Error;


class Matcher {
    public var allOfComponents:Array<ComponentConstructor>;
    public var noneOfComponents:Array<ComponentConstructor>;
    public var mandatory:Bool;
    public var results:Array<Entity>;
    public var added:Array<Entity>;
    public var removed:Array<Entity>;
    public var changed:Array<Entity>;
    public var listen_added:Bool;
    public var listen_removed:Bool;
    public var listen_changed:Bool;

    public function new():Void {
        mandatory = true;
        results = [];
        added = [];
        removed = [];
        changed = [];
        allOfComponents = [];
        noneOfComponents = [];

        listen_added = true;
        listen_removed = true;
        listen_changed = true;
    }

    public function allOf(allOfComponents:Array<ComponentConstructor>):Matcher {
        this.allOfComponents = allOfComponents;
        return this;
    }

    public function noneOf(noneOfComponents:Array<ComponentConstructor>):Matcher {
        this.noneOfComponents = noneOfComponents;
        return this;
    }

}

class System {
    public var _mandatoryQueries:Array<Query>;
    public var world:World;
    public var enabled:Bool;
    public var _queries:Array<Query>;
    public var priority:Int;
    public var executeTime:Float;
    public var initialized:Bool;
    public var order:Int;
    var querieConfigs:Array<Matcher>;

    public function canExecute() {
        if (this._mandatoryQueries.length == 0) return true;
        for (i in 0... this._mandatoryQueries.length) {
            var query = this._mandatoryQueries[i];
            if (query.entities.length == 0) {
                return false;
            }
        }
        return true;
    }

    public function execute(delta:Float, time:Float) {

    }

    public function init(attributes):Void {

    }

    public function new(world, attributes:{priority:Int}) {
        this.world = world;
        this.enabled = true;
        // @todo Better naming :)
        this._queries = [];
        this.priority = 0;
        // Used for stats
        this.executeTime = 0;
        if (attributes != null) {
            this.priority = attributes.priority;
        }
        this._mandatoryQueries = [];

        this.initialized = true;
    }

    public function initQueries(configQ:Dynamic) {
        this.querieConfigs = [];
        for (f in Reflect.fields(configQ)) {
            this.querieConfigs.push(cast Reflect.field(configQ, f));
        }
        for (query in this.querieConfigs) {
            configQueries(query);
        }
    }

    function addQueryListener(query:Query, eventName, eventList:Array<Entity>) {
        query.eventDispatcher.addEventListener(
            eventName,
            function(entity, comp) {
                // @fixme overhead?
                if (eventList.indexOf(entity) == -1)
                    eventList.push(entity);
            }
        );
    }

    function configQueries(queryConfig:Matcher) {
        var Components = queryConfig.allOfComponents;
        if (Components.length == 0) {
            throw ("'components' attribute can't be empty in a query");
        }
        var query:Query = this.world.entityManager.queryComponents(queryConfig.allOfComponents, queryConfig.noneOfComponents);
        this._queries.push(query) ;
        if (queryConfig.mandatory == true) {
            this._mandatoryQueries.push(query);
        }
        queryConfig.results = query.entities ;
        if (queryConfig.listen_added) {
            addQueryListener(query, Query.ENTITY_ADDED, queryConfig.added);
        }
        if (queryConfig.listen_removed) {
            addQueryListener(query, Query.ENTITY_REMOVED, queryConfig.removed);
        }
        if (queryConfig.listen_changed) {
            query.reactive = true;
            addQueryListener(query, Query.COMPONENT_CHANGED, queryConfig.changed);
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

//  public function  toJSON() {
//      var json = {
//        name: this.constructor.name,
//        enabled: this.enabled,
//        executeTime: this.executeTime,
//        priority: this.priority,
//        queries: {}
//      };
//
//      if (this.constructor.queries) {
//        var queries = this.constructor.queries;
//        for (let queryName in queries) {
//          let query = this.queries[queryName];
//          let queryDefinition = queries[queryName];
//          let jsonQuery = (json.queries[queryName] = {
//            key: this._queries[queryName].key
//          });
//
//          jsonQuery.mandatory = queryDefinition.mandatory === true;
//          jsonQuery.reactive =
//            queryDefinition.listen &&
//            (queryDefinition.listen.added === true ||
//              queryDefinition.listen.removed === true ||
//              queryDefinition.listen.changed === true ||
//              Array.isArray(queryDefinition.listen.changed));
//
//          if (jsonQuery.reactive) {
//            jsonQuery.listen = {};
//
//            const methods = ["added", "removed", "changed"];
//            methods.forEach(method => {
//              if (query[method]) {
//                jsonQuery.listen[method] = {
//                  entities: query[method].length
//                };
//              }
//            });
//          }
//        }
//      }
//
//      return json;
//    }
}
  

  