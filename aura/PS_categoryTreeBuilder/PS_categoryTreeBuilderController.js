({
	init: function(component, event, helper) {
		console.log(
			'activeContentCategory: ',
			component.get('v.activeContentCategory')
		)
		helper.handleGetAllContentCategories(arguments)
		window.addEventListener(
			'dragover',
			function(e) {
				e = e || event
				e.preventDefault()
			},
			false
		)
		window.addEventListener(
			'drop',
			function(e) {
				e = e || event
				e.preventDefault()
			},
			false
		)
	},
	toggleTopLevelDragSpot: function(component, event, helper) {
		let el = component.find('topLevelDropSpot').getElement()
		if (el && el.classList.contains('new-branch-helper_active')) {
			$A.util.removeClass(el, 'new-branch-helper_active')
		} else {
			$A.util.addClass(el, 'new-branch-helper_active')
		}
	},

	handleNavigateBackToComponent: function(component, event, helper) {
		const { currentTabId } = event.getParams()
		if (currentTabId) return
		helper.handleGetContentCategoryWithAttachments(arguments)
		helper.handleGetAllContentCategories(arguments)
	},

	handleFileUpsert: function(component, event, helper) {
		let args = arguments
		let data = event.getParam('data')
		let action = component.get('c.upsertFile')
		action.setParams(data)
		action.setCallback(this, function(response) {
			let state = response.getState()
			let contentVersion = response.getReturnValue()
			if (state === 'SUCCESS') {
				// LEFT OFF HERE, update the active content category with the newly attached tile or banner
				let activeContentCategory = component.get('v.activeContentCategory')
				if (contentVersion.Closer__is_banner__c) {
					activeContentCategory.banner = contentVersion
				} else if (contentVersion.Closer__is_tile__c) {
					activeContentCategory.tile = contentVersion
				}
				let toastMessage
				if (contentVersion.Closer__is_banner__c) {
					toastMessage = 'Banner has been updated!'
				} else if (contentVersion.Closer__is_tile__c) {
					toastMessage = 'Tile has been updated!'
				} else {
					toastMessage = 'Content has been updated!'
					$A.get('e.force:refreshView').fire()
				}
				component.set('v.activeContentCategory', activeContentCategory)
				component.set('v.isMainSceneLoading', false)
				let PopToast = component.getEvent('PS_PopToast')
				PopToast.setParams({
					title: 'Success!',
					message: toastMessage,
					type: 'success',
					duration: 2000
				})
				PopToast.fire()
			} else {
				let PopToast = component.getEvent('PS_PopToast')
				PopToast.setParams({
					title: 'Error!',
					message: data,
					type: 'error',
					duration: 2000
				})
				PopToast.fire()
			}
		})
		$A.enqueueAction(action)
	},

	handleActiveContentCategory: function(component, event, helper) {
		component.set('v.showNewContentCategory', false)
		helper.handleGetContentCategoryWithAttachments(arguments)
	},

	handleContentCategoryParentChange: function(component, event, helper) {
		helper.handleUpdateContentCategoryParent(arguments)
	},

	handleRefresh: function(component, event, helper) {
		helper.handleGetAllContentCategories(arguments)
	},

	handleToast: function(component, event, helper) {
		let params = event.getParams()
		let toastEvent = $A.get('e.force:showToast')
		toastEvent.setParams({
			title: params.title || '',
			message: params.message || '',
			type: params.type || '',
			duration: params.duration || 1000
		})
		toastEvent.fire()
	},

	handleDragStart: function(component, event, helper) {
		event.stopPropagation()
		let target = event.currentTarget
		target.classList.add('dragging')

		event.dataTransfer.effectAllowed = 'move'
		event.dataTransfer.setData(
			'text/plain',
			JSON.stringify({
				sourceId: event.currentTarget.getAttribute('data-content-category-id'),
				parentId: event.currentTarget.getAttribute(
					'data-content-category-parent-id'
				)
			})
		)
		let el = component.find('topLevelDropSpot')
		if (el) $A.util.addClass('new-branch-helper_active')
	},

	handleDragEnd: function(component, event, helper) {
		event.stopPropagation()
		let target = event.currentTarget
		let parentNode = target.parentNode
		target.classList.remove('dragging', 'hovered')
		let el = component.find('topLevelDropSpot').getElement()
		el ? el.classList.remove('new-branch-helper_active') : ''
	},

	handleDragOver: function(component, event, helper) {
		event.preventDefault()
		let target = event.currentTarget
		target.classList.add('hovered')
	},

	handleDragEnter: function(component, event, helper) {
		event.preventDefault()
		let target = event.currentTarget
		target.classList.add('hovered')
	},

	handleDragLeave: function(component, event, helper) {
		event.preventDefault()
		let target = event.currentTarget
		target.classList.remove('hovered')
	},

	handleDrop: function(component, event, helper) {
		event.preventDefault()
		let target = event.currentTarget
		target.classList.remove('hovered')

		let targetId = event.currentTarget.getAttribute('data-content-category-id')
		let data = JSON.parse(event.dataTransfer.getData('text/plain'))
		event.currentTarget.classList.remove('drag-target')
		if (targetId != data.sourceId) {
			let contentCategoryParentChange = component.getEvent(
				'ContentCategoryParentChange'
			)
			contentCategoryParentChange.setParams({
				targetId: targetId,
				sourceId: data.sourceId,
				sourceParentId: data.parentId
			})
			contentCategoryParentChange.fire()
		}
	}
})