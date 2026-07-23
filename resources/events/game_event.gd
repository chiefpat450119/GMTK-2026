class_name GameEvent
extends Resource
## Generic event channel 
##
## Create GameEvent Resource and assign it a name matching its use
## e.g. "player_dead_event" 
## Paired with GameEventListener. see game_event_listener.gd
## stores array of listeners. listeners are in charge of registering themselves. 
## _listeners should not be manually initialized

var _listeners : Array[GameEventListener]

# Use this method to raise event
# Array traversed backwards to avoid issues in the case that a listener removes 
# itself from the list
func raise():
	for i in range(_listeners.size() - 1, -1, -1):
		_listeners[i].recieve_signal()


func register(listener : GameEventListener):
	_listeners.append(listener)

func deregister(listener : GameEventListener):
	_listeners.erase(listener)
