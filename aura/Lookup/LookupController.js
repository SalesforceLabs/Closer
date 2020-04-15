({
	handleKeyUp: function(component, event, helper) {
		let timeoutId = component.get('v.timeoutId')
		if (timeoutId) clearTimeout(timeoutId)
		timeoutId = setTimeout(
			$A.getCallback(() => {
				let query = component.get('v.query').trim()
				helper.fireEvent(component, 'SearchQuery', { query })
			}),
			300
		)
		component.set('v.timeoutId', timeoutId)
	}
	
})