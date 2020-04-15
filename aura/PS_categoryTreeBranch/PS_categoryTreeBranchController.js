({
	update: function(component, event, helper) {
		setTimeout(
			$A.getCallback(function() {
				let node = component.get('v.node')
				if (node) {
					let button = component.find('node-button').getElement()
					if (button.classList.contains('icon-helper_expanded')) {
            component.set("v.expanded", true)
					}
				}
			}),
			50
		)
	},

	expandBranch: function(component, event, helper) {
		let currentElement = event.currentTarget
		let expanded = component.get('v.expanded')
		component.set('v.expanded', !expanded)
		expanded
			? $A.util.removeClass(currentElement, 'icon-helper_expanded')
			: $A.util.addClass(currentElement, 'icon-helper_expanded')
	},

	selectContentCategory: function(component, event, helper) {
		let contentCategoryId = event.currentTarget.getAttribute(
			'data-content-category-id'
		)
		let selectActiveContentCategoryEvent = component.getEvent(
			'SelectActiveContentCategory'
		)
		selectActiveContentCategoryEvent.setParams({
			contentCategoryId: contentCategoryId
		})
		selectActiveContentCategoryEvent.fire()
	},

	handleDragStart: function(component, event, helper) {
		event.stopPropagation()
		let target = event.currentTarget
		$A.util.addClass(target, 'dragging')
		component.set('v.expanded', false)
		$A.util.removeClass(target, 'icon-helper_expanded')
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

		let toggleTopLevelDragSpot = component.getEvent('ToggleTopLevelDragSpot')
		toggleTopLevelDragSpot.fire()
	},

	handleDragEnd: function(component, event, helper) {
		event.stopPropagation()
		let target = event.currentTarget
		$A.util.removeClass(target, 'dragging')
		$A.util.removeClass(target, 'hovered')
		let toggleTopLevelDragSpot = component.getEvent('ToggleTopLevelDragSpot')
		toggleTopLevelDragSpot.fire()
	},

	handleDragOver: function(component, event, helper) {
		event.preventDefault()
		event.stopPropagation()
	},

	handleDragEnter: function(component, event, helper) {
		event.preventDefault()
		event.stopPropagation()
		let target = event.currentTarget
		$A.util.addClass(target, 'hovered')
	},

	handleDragLeave: function(component, event, helper) {
		event.preventDefault()
		event.stopPropagation()
		let target = event.currentTarget
		$A.util.removeClass(target, 'hovered')
	},

	handleDrop: function(component, event, helper) {
		event.preventDefault()
		event.stopPropagation()
		let target = event.currentTarget
		$A.util.removeClass(target, 'hovered')

		let targetId = event.currentTarget.getAttribute('data-content-category-id')
		let data = JSON.parse(event.dataTransfer.getData('text/plain'))
		
		$A.util.removeClass(event.currentTarget, 'drag-target')

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