({
	handleQuery: function(component, event, helper) {
		let { query } = event.getParams()
		if (!query.length) {
			component.set('v.searchResults', [])
      component.set('v.selectedName', null)
      component.set('v.value', null)
			return
		}
		if (query.length < 3) return
		helper
			.fireApex(component,'c.userSearch', { query })
			.then(searchResults => {
				component.set('v.searchResults', searchResults)
			})
			.catch(e => {
				console.log('error: ', e)
			})
	},
	handleSearchResultSelected: function(component, event, helper) {
		const { userId, userName } = event.getParams()
		component.set('v.searchResults', [])
		component.set('v.selectedName', userName)
		component.set('v.value', userId)
	}
})