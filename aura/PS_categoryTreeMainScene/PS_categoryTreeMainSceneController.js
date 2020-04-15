({
	init: function(component, event, helper) {
		let reloadData = component.find('recordData')
		if (reloadData) {
			reloadData.reloadRecord(true)
		}
	},

	navigateToRecord: function(component, event, helper) {
		let recordId = event.currentTarget.getAttribute('data-record-id')
		let navEvt = $A.get('e.force:navigateToSObject')
		navEvt.setParams({
			recordId: recordId
		})
		navEvt.fire()
	},

	toggleNewContentCategory: function(component, event, helper) {
		let createRecordEvent = $A.get('e.force:createRecord')
		createRecordEvent.setParams({
			entityApiName: 'Closer__Content_Category__c'
		})
		createRecordEvent.fire()
	},

	openFile: function(component, event, helper) {
		let contentDocumentId = event.currentTarget.getAttribute(
			'data-content-document-id'
		)
		$A.get('e.lightning:openFiles').fire({
			recordIds: [contentDocumentId]
		})
	},

	handleTileDropzoneClick: function(component, event, helper) {
		event.stopPropagation()
		event.preventDefault()
		component.find('tileInput').length
			? component
					.find('tileInput')
					.filter(el => el)
					.forEach(el => {
						el.getElement().click()
					})
			: component
					.find('tileInput')
					.getElement()
					.click()
	},
	handleBannerDropzoneClick: function(component, event, helper) {
		event.stopPropagation()
		event.preventDefault()
		component.find('bannerInput').length
			? component
					.find('bannerInput')
					.filter(el => el)
					.forEach(el => {
						el.getElement().click()
					})
			: component
					.find('bannerInput')
					.getElement()
					.click()
	},

	handleAddContentClick: function(component, event, helper) {
		event.stopPropagation()
		event.preventDefault()

		let {
			ContentCategory: { Id }
		} = component.get('v.activeContentCategory')
		var relatedListEvent = $A.get('e.force:navigateToRelatedList')
		relatedListEvent.setParams({
			relatedListId: 'CombinedAttachments',
			parentRecordId: Id
		})
		relatedListEvent.fire()
	},

	handleFileChange: function(component, event, helper) {
		let parentElement = event.currentTarget.parentNode
		let input = event.currentTarget
		let files = input.files
		helper.handleFileUploadEvent(component, files, parentElement)
	},

	handleDrop: function(component, event, helper) {
		event.stopPropagation()
		event.preventDefault()
		event.dataTransfer.dropEffect = 'copy'
		let currentTarget = event.currentTarget
		let dataTransfer = event.dataTransfer
		let files = dataTransfer.files
		helper.handleFileUploadEvent(component, files, currentTarget)
		event.currentTarget.classList.remove
		$A.util.removeClass(event.currentTarget, 'file-drag-target')
		$A.util.removeClass(event.currentTarget, 'shade-hover')
	},

	handleDragOver: function(component, event, helper) {
		event.stopPropagation()
		event.preventDefault()
	},

	handleDragEnter: function(component, event, helper) {
		event.stopPropagation()
		event.preventDefault()
		event.currentTarget.classList.add('file-drag-target')
		event.currentTarget.childNodes[1].classList.add('shade-hover')
	},

	handleDragLeave: function(component, event, helper) {
		event.stopPropagation()
		event.preventDefault()
		$A.util.removeClass(event.currentTarget, 'file-drag-target')
		$A.util.removeClass(event.currentTarget, 'shade-hover')
	}
})