({
	handleSearchResultSelected: function(component, event, helper) {
		const { userid: userId, username: userName } = event.currentTarget.dataset
		helper.fireEvent(component, 'SearchResultSelected', { userId, userName })
	}
})