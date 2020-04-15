({
	share: function(component, event, helper) {
		helper.component = component
		let userId = component.get('v.userId')
		let recordId = component.get('v.recordId')
		helper
			.fireApex('c.shareContentCategories', {
				recordId,
				userId
			})
			.then(res => {
				$A.get('e.force:closeQuickAction').fire()
			})
			.catch(errors => {
				errors.forEach(error => {
					let message = 'Make sure the user has permission to view the object.'
					if (error.message === 'USER_NOT_FOUND') {
						message = 'The user was not found.'
					}
					let toast = $A.get('e.force:showToast')
					toast.setParams({
						title: 'There was a problem sharing.',
						message,
						type: 'error'
					})
					toast.fire()
				})
			})
	},
	unShare: function(component, event, helper) {
		helper.component = component
		let userId = component.get('v.userId')

		let recordId = component.get('v.recordId')
		helper
			.fireApex('c.unShareContentCategories', {
				recordId,
				userId
			})
			.then(res => {
				$A.get('e.force:closeQuickAction').fire()
			})
			.catch(errors => {
				errors.forEach(error => {
					let message =
						'Make sure the selected user is not the owner of the record.'
					if (error.message === 'USER_NOT_FOUND') {
						message = 'The user was not found.'
					}
					let toast = $A.get('e.force:showToast')
					toast.setParams({
						title: 'There was a problem sharing.',
						message,
						type: 'error'
					})
					toast.fire()
				})
			})
	}
})