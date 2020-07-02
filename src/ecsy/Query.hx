package ecsy;

import ecsy.Component.ComponentConstructor;
import ecsy.Util;
import Lambda;

class Query {
    public static var ENTITY_ADDED = "Query#ENTITY_ADDED";
    public static var ENTITY_REMOVED = "Query#ENTITY_REMOVED";
    public static var COMPONENT_CHANGED = "Query#COMPONENT_CHANGED";
    /**
     * @param {Array(Component)} Components List of types of components to query
     */
    public var components:Array<ComponentConstructor>;
    public var notComponents:Array<ComponentConstructor>;
    public var reactive:Bool;
    public var entities:Array<Entity>;
    public var eventDispatcher:EventDispatcher;
    public var key:String;

    public function new(allOfComponents:Array<ComponentConstructor>, noneOfComponents:Array<ComponentConstructor>, manager:EntityManager) {
        this.components = allOfComponents;
        this.notComponents = noneOfComponents;
        if (this.components.length == 0) {
            throw ("Can't create a query without components");
        }

        this.entities = [];

        this.eventDispatcher = new EventDispatcher();

        // This query is being used by a reactive system
        this.reactive = false;

        this.key = Util.queryKey(allOfComponents, noneOfComponents);

        // Fill the query with the existing entities
        for (i in 0... manager._entities.length) {
            var entity = manager._entities[i];
            if (this.match(entity)) {
                // @todo ??? this.addEntity(entity); => preventing the event to be generated
                entity.queries.push(this);
                this.entities.push(entity);
            }
        }
    }

    /**
     * Add entity to this query
     * @param {Entity} entity
     */
    public function addEntity(entity:Entity) {
        entity.queries.push(this);
        this.entities.push(entity);

        this.eventDispatcher.dispatchEvent(Query.ENTITY_ADDED, entity);
    }

    /**
     * Remove entity from this query
     * @param {Entity} entity
     */
    public function removeEntity(entity:Entity) {
        var index = Lambda.has(this.entities, entity);
        if (index) {
            this.entities.remove(entity);
            entity.queries.remove(this);
            this.eventDispatcher.dispatchEvent(
                Query.ENTITY_REMOVED,
                entity
            );
        }
    }

    public function match(entity:Entity) {
        return (
            entity.hasAllComponents(this.components) &&
            !entity.hasAnyComponents(this.notComponents)
        );
    }
//
//    public function  toJSON() {
//      return {
//        key: this.key,
//        reactive: this.reactive,
//        components: {
//          included:  Lambda.map(this.Components,function(C:Component ) return C.name),
//          not: this.NotComponents.map(C => C.name)
//        },
//        numEntities: this.entities.length
//      };
//    }

    /**
     * Return stats for this query
     */
    public function stats() {
        return {
            numComponents: this.components.length,
            numEntities: this.entities.length
        };
    }
}
  

  