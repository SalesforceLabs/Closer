({
	fireEvent: function(component, eventName, params) {
		var compEvent = component.getEvent(eventName)
		compEvent.setParams(params)
		compEvent.fire()
	}
})