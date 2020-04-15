({
	handleFileUploadEvent : function(component, files, targetElement) {
		if(files.length > 1) {
			let PopToast = component.getEvent("PS_PopToast");
			PopToast.setParams({
				"title": "Error!",
				"message": "Please upload only 1 file.",
				"type": "error",
				"duration": 2000
			});
			PopToast.fire();
		} else if(files.length == 1){
			component.set("v.isMainSceneLoading", true);
			let reader = new FileReader();
			reader.readAsDataURL(files[0]);
			reader.onload = function() {
				let base64data = reader.result.match(/,(.*)$/)[1];
				let upsertContentCategoryFileEvent = component.getEvent("UpsertContentCategoryFile");
				upsertContentCategoryFileEvent.setParams({
					"data": {"contentVersionId": targetElement.getAttribute("data-content-version-id"),
							 "contentDocumentId": targetElement.getAttribute("data-content-document-id"),
							 "customImageType": targetElement.getAttribute("data-custom-image-type"),
							 "contentCategoryId": targetElement.getAttribute("data-content-category-id"),
							 "fileTitle": files[0].name,
							 "base64data": base64data}
        });
				upsertContentCategoryFileEvent.fire();
				targetElement.childNodes[0].parentNode.style.background = "url(" + reader.result + ")";
			}
		}
	}
})