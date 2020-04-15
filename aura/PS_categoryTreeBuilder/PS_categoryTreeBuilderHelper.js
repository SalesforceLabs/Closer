({
	handleGetAllContentCategories: function(args) {
		let [component, event, helper] = args
		let action = component.get('c.getAllContentCategories')
		action.setCallback(this, function(response) {
			let state = response.getState()
			let data = response.getReturnValue()
			if (state === 'SUCCESS') {
				component.set('v.contentCategories', data)
				component.set('v.isAppLoading', false)
			} else {
				let PopToast = component.getEvent('PS_PopToast')
				PopToast.setParams({
					title: 'Error!',
					message:
						'There was a hiccup getting your content categories. ' + state,
					type: 'error',
					duration: 2000
				})
				PopToast.fire()
			}
		})
		$A.enqueueAction(action)
	},

	handleGetContentCategoryWithAttachments: function(args) {
		let [component, event, helper] = args
		component.set('v.isMainSceneLoading', true)

		let contentCategoryId =
			event.getParam('contentCategoryId') ||
			(component.get('v.activeContentCategory') &&
			component.get('v.activeContentCategory').ContentCategory
				? component.get('v.activeContentCategory').ContentCategory.Id
				: null)

		if (!contentCategoryId) {
			component.set('v.isMainSceneLoading', false)
			return
		}
		let action = component.get('c.getContentCategoryWithAttachments')
		action.setParams({
			contentCategoryId: contentCategoryId
		})
		action.setCallback(this, function(response) {
			let state = response.getState()
			let contentCategory = response.getReturnValue()
			if (state === 'SUCCESS') {
				contentCategory.files.reverse()
				console.log('contentCategory: ', contentCategory)
				component.set('v.activeContentCategory', contentCategory)
				component.set('v.isMainSceneLoading', false)
			} else {
				let PopToast = component.getEvent('PS_PopToast')
				component.set('v.isMainSceneLoading', false)
				PopToast.setParams({
					title: 'Error!',
					message: 'There was a hiccup getting your content category. ' + state,
					type: 'error',
					duration: 2000
				})
				PopToast.fire()
			}
		})
		$A.enqueueAction(action)
	},

	handleUpdateContentCategoryParent: function(args) {
		let [component, event, helper] = args
		let action = component.get('c.updateContentCategoryParent')
		let dataTransfer = event.getParams()
		action.setParams({
			targetId: dataTransfer.targetId,
			sourceId: dataTransfer.sourceId
		})
		action.setCallback(this, function(response) {
			let state = response.getState()
			let data = response.getReturnValue()
			if (state === 'SUCCESS') {
				let list = component.get('v.contentCategories')

				let currentNode = helper.findNode(args, list, 1, data.Id)
				currentNode.ContentCategory.Closer__Parent_Content_Category__c =
					data.Closer__Parent_Content_Category__c

				if (data.Closer__Parent_Content_Category__c) {
					let parentNode = helper.findNode(
						args,
						list,
						1,
						data.Closer__Parent_Content_Category__c
					)
					helper.addNode(list, parentNode, currentNode, false)
				} else {
					helper.addNode(list, null, currentNode, true)
				}

				let previousParentNode = helper.findNode(
					args,
					list,
					1,
					dataTransfer.sourceParentId
				)
				if (previousParentNode) {
					helper.removeNode(args, previousParentNode.children, data.Id)
				} else {
					helper.removeNode(args, list, data.Id)
				}

				component.set('v.contentCategories', list)
				let PopToast = component.getEvent('PS_PopToast')
				PopToast.setParams({
					title: 'Success!',
					message: "We've updated your content category.",
					type: 'success',
					duration: 500
				})
				PopToast.fire()
			} else {
				let PopToast = component.getEvent('PS_PopToast')
				PopToast.setParams({
					title: 'Error!',
					message:
						"We've run into a problem while updating your content category.",
					type: 'error',
					duration: 2000
				})
				PopToast.fire()
			}
		})
		$A.enqueueAction(action)
	},

	addNode: function(list, parentNode, node, topLevel) {
		topLevel ? list.push(node) : parentNode.children.unshift(node)
	},

	findNode: function(args, list, depth, recordId) {
		let [component, event, helper] = args
		for (var i = 0, len = list.length; i < len; i++) {
			if (list[i].ContentCategory.Id === recordId) {
				let node = list[i]
				return node
			} else {
				let foundNode = helper.findNode(
					args,
					list[i].children,
					depth + 1,
					recordId
				)
				if (foundNode) return foundNode
			}
		}
		return null
	},

	removeNode: function(args, list, recordId) {
		for (let i = 0; i < list.length; i++) {
			if (list[i].ContentCategory.Id === recordId) {
				list.splice(i, 1)
				return list
			}
		}
	}
})