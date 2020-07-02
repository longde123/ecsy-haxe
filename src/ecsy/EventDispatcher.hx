package ecsy;
import haxe.ds.StringMap;
typedef Stats = { fired:Int,
    handled:Int};
class EventDispatcher {
    var _listeners:StringMap<Array<Entity -> Component -> Void>>;
    var stats:Stats;

    public function new() {
        this._listeners = new StringMap<Array<Entity -> Component -> Void>>();
        this.stats = {
            fired: 0,
            handled: 0
        };
    }

    /**
     * Add an event listener
     * @param {String} eventName Name of the event to listen
     * @param {Function} listener Callback to trigger when the event is fired
     */
    public function addEventListener(eventName, listener) {
        var listeners = this._listeners;
        if (!listeners.exists(eventName)) {
            listeners.set(eventName, []);
        }
        var listenerArray = listeners.get(eventName);
        if (!Lambda.has(listenerArray, listener)) {
            listenerArray.push(listener);
        }
    }

    /**
     * Check if an event listener is already added to the list of listeners
     * @param {String} eventName Name of the event to check
     * @param {Function} listener Callback for the specified event
     */
    public function hasEventListener(eventName, listener) {
        return (this._listeners.exists(eventName) &&
        Lambda.has(this._listeners.get(eventName), listener)
        );
    }

    /**
     * Remove an event listener
     * @param {String} eventName Name of the event to remove
     * @param {Function} listener Callback for the specified event
     */
    public function removeEventListener(eventName, listener) {
        if (this._listeners.exists(eventName)) {
            var listenerArray = this._listeners.get(eventName);
            if (Lambda.has(listenerArray, listener))
                listenerArray.remove(listener);
        }
    }

    /**
     * Dispatch an event
     * @param {String} eventName Name of the event to dispatch
     * @param {Entity} entity (Optional) Entity to emit
     * @param {Component} component
     */
    public function dispatchEvent(eventName, entity:Entity, component:Component = null) {
        this.stats.fired++;

        if (this._listeners.exists(eventName)) {
            var listenerArray = this._listeners.get(eventName);
            var array = listenerArray.copy();

            for (i in 0...array.length) {
                var fun:Entity -> Component -> Void = array[i];
                fun(entity, component);
            }
        }
    }

    /**
     * Reset stats counters
     */
    public function resetCounters() {
        this.stats.fired = this.stats.handled = 0;
    }
}
  