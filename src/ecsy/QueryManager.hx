package ecsy;

import haxe.ds.Either;
import ecsy.Component.ComponentConstructor;
import Lambda;
import haxe.ds.StringMap;
class QueryManager {
    public var _world:World;
    public var _queries:StringMap<Query>;

    public function new(world:World) {
        this._world = world;

        // Queries indexed by a unique identifier for the components it has
        this._queries = new StringMap<Query>();
    }

    public function onEntityRemoved(entity:Entity) {
        for (query in this._queries.iterator()) {
            if (Lambda.has(entity.queries, query)) {
                query.removeEntity(entity);
            }
        }
    }

    /**
     * Callback when a component is added to an entity
     * @param {Entity} entity Entity that just got the new component
     * @param {Component} Component Component added to the entity
     */
    public function onEntityComponentAdded(entity:Entity, component:ComponentConstructor) {
        // @todo Use bitmask for checking components?

        // Check each indexed query to see if we need to add this entity to the list
        for (query in this._queries.iterator()) {

            if (Lambda.has(query.notComponents, component)
            && Lambda.has(query.entities, entity)) {
                query.removeEntity(entity);
                continue;
            }

            // Add the entity only if:
            // Component is in the query
            // and Entity has ALL the components of the query
            // and Entity is not already in the query
            if (
            !Lambda.has(query.components, component) ||
            !query.match(entity) ||
            Lambda.has(query.entities, entity)
            )
                continue;

            query.addEntity(entity);
        }
    }

    /**
     * Callback when a component is removed from an entity
     * @param {Entity} entity Entity to remove the component from
     * @param {Component} Component Component to remove from the entity
     */
    public function onEntityComponentRemoved(entity:Entity, component:ComponentConstructor) {
        for (query in this._queries.iterator()) {


            if (
            Lambda.has(query.notComponents, component) &&
            !Lambda.has(query.entities, entity) &&
            query.match(entity)
            ) {
                query.addEntity(entity);
                continue;
            }

            if (
            Lambda.has(query.components, component) &&
            Lambda.has(query.entities, entity) &&
            !query.match(entity)
            ) {
                query.removeEntity(entity);
                continue;
            }
        }
    }

    /**
     * Get a query for the specified components
     * @param {Component} Components Components that the query should have
     */
    public function getQuery(allOfComponents:Array<ComponentConstructor>, noneOfComponents:Array<ComponentConstructor>) {
        var key:String = Util.queryKey(allOfComponents, noneOfComponents);
        var query:Query = cast this._queries.get(key);
        if (!this._queries.exists(key)) {
            query = new Query( allOfComponents, noneOfComponents, this._world.entityManager);
            this._queries.set(key, query);
        }
        return query;
    }

    /**
     * Return some stats from this class
     */
    public function stats() {
//        var stats = {};
//        for (queryName in this._queries.keys()) {
//            stats[queryName] = this._queries.get(queryName).stats();
//        }
//        return stats;
    }
}
  