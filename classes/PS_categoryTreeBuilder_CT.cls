public with sharing class PS_categoryTreeBuilder_CT {
	public class ContentCategoryWrapper {
		@AuraEnabled public Content_Category__c ContentCategory {get; set;}
		@AuraEnabled public Object[] children {get; set;}
		@AuraEnabled public ContentVersion[] files {get; set;}
		@AuraEnabled public ContentVersion banner {get; set;}
		@AuraEnabled public ContentVersion tile {get; set;}
	}

	public class DirectChildReturnWrapper {
		public Content_Category__c[] nodes {get;set;}
		public ContentCategoryWrapper[] children {get;set;}
	}

	@AuraEnabled
	public static ContentVersion upsertFile(String base64data, String contentDocumentId, String contentVersionId, String customImageType, String fileTitle, String contentCategoryId) {
		Blob image = EncodingUtil.base64Decode(base64data);
		try {
			ContentVersion cv = new ContentVersion();
			ContentVersion newCv = new ContentVersion();
			if(contentDocumentId != 'new' && contentVersionId != 'new') {
				cv = [SELECT Id, Title, PathOnClient, VersionData, IsMajorVersion FROM ContentVersion WHERE Id = :contentVersionId];
				newCv.ContentDocumentId = contentDocumentId;
				newCv.Title = cv.Title;
				newCv.PathOnClient = cv.PathOnClient;
				newCv.VersionData = image;
				newCv.IsMajorVersion = true;
				checkAccess('ContentVersion', newCv, 'create');
				insert newCv;
			} else if(contentDocumentId == 'new' || contentVersionId == 'new') {
				newCv.Title = fileTitle;
				newCv.PathOnClient = fileTitle;
				newCv.VersionData = image;
				newCv.IsMajorVersion = true;
				if(customImageType == 'tile') {
					newCv.is_tile__c = true;
				} else if(customImageType == 'banner'){
					newCv.is_banner__c = true;
				}
				checkAccess('ContentVersion', newCv, 'create');
				insert newCv;

				ContentDocumentLink cdl = new ContentDocumentLink();
				cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :newCv.Id].ContentDocumentId;
				cdl.LinkedEntityId = contentCategoryId;
				cdl.ShareType = 'I';
				checkAccess('ContentDocumentLink', cdl, 'create');
				insert cdl;
			}
			ContentVersion updatedContentVersion = [SELECT 	Id,
															ContentDocument.Title,
															is_banner__c,
															is_tile__c,
															FileExtension,
															FileType
													FROM ContentVersion
													WHERE Id = :newCv.Id];
			return updatedContentVersion;
		} catch(Exception error) {
			AuraHandledException e = new AuraHandledException('Error: ' + error.getMessage());
			throw e;
		}
	}

	@AuraEnabled
	public static Content_Category__c updateContentCategoryParent(String targetId, String sourceId) {
		Content_Category__c source = [SELECT Id, Parent_Content_Category__c FROM Content_Category__c WHERE Id = :sourceId];
		checkAccess('Closer__Content_Category__c', source, 'update');
		if(targetId == 'top') {
			source.Parent_Content_Category__c = null;
		} else {
			source.Parent_Content_Category__c = targetId;
		}
		try {
			checkAccess('Closer__Content_Category__c', source, 'update');
			update source;
			return source;
		} catch(Exception error) {
			AuraHandledException e = new AuraHandledException('Error: ' + error.getMessage());
			throw e;
		}
	}

	@AuraEnabled(cacheable=false)
	public static ContentCategoryWrapper getContentCategoryWithAttachments(String contentCategoryId) {
		Content_Category__c[] contentCategories = [SELECT Id, Name, Parent_Content_Category__c, Parent_Content_Category__r.Name FROM Content_Category__c WHERE Id = :contentCategoryId];
		if(!contentCategories.isEmpty()) {
      checkAccess('Closer__Content_Category__c', new String[]{'Id', 'Name', 'Closer__Parent_Content_Category__c'}, 'read');

			ContentDocumentLink[] allCdl = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :contentCategories[0].Id];
			String[] contentDocumentLinkIds = new List<String>();
			for(ContentDocumentLink cdl : allCdl) {
				contentDocumentLinkIds.add(cdl.ContentDocumentId);
			}
			ContentVersion[] contentVersions = [SELECT 	Id,
														ContentDocument.Title,
														is_banner__c,
														is_tile__c,
														FileExtension,
														FileType
												FROM ContentVersion
												WHERE ContentDocumentId IN :contentDocumentLinkIds AND IsLatest = true
												ORDER BY is_banner__c, is_tile__c ASC];
			ContentCategoryWrapper wrapper = new ContentCategoryWrapper();
			wrapper.ContentCategory = contentCategories[0];
			wrapper.files = new List<ContentVersion>();
			for(ContentVersion cv : contentVersions) {
				if(cv.is_banner__c) {
					wrapper.banner = cv;
				} else if(cv.is_tile__c) {
					wrapper.tile = cv;
				} else {
					wrapper.files.add(cv);
				}
			}
			return wrapper;
		}
		AuraHandledException e = new AuraHandledException('No record(s) found with ID: ' + contentCategoryId);
		throw e;
	}

	@AuraEnabled
	public static ContentCategoryWrapper[] getAllContentCategories() {
		ContentCategoryWrapper[] wrappers = new List<ContentCategoryWrapper>();
		Content_Category__c[] allNodes = [SELECT Id, Name, Parent_Content_Category__c FROM Content_Category__c ORDER BY Name ASC];
    
    checkAccess('Closer__Content_Category__c', new String[]{'Id', 'Name', 'Closer__Parent_Content_Category__c'}, 'read');

		for(Content_Category__c node : allNodes) {
			if(node.Parent_Content_Category__c == null) {
				ContentCategoryWrapper topLevelWrapper = new ContentCategoryWrapper();
				topLevelWrapper.ContentCategory = node;
				ContentCategoryWrapper[] children = findChildren(node, allNodes);
				topLevelWrapper.children = children;
				wrappers.add(topLevelWrapper);
			}
		}
		return wrappers;
	}

	@TestVisible
	private static ContentCategoryWrapper[] findChildren(Content_Category__c parentNode, Content_Category__c[] remainingNodes) {
		Content_Category__c[] children = new list<Content_Category__c>();
		Content_Category__c[] newRemainingNodes = new list<Content_Category__c>();

		for(Content_Category__c child : remainingNodes) {
			if(child.Parent_Content_Category__c == parentNode.Id) {
				children.add(child);
			} else {
				newRemainingNodes.add(child);
			}
		}
		
		if(children.size() <= 0) {
			return new List<ContentCategoryWrapper>();
		} else {
			ContentCategoryWrapper[] wrappers = new List<ContentCategoryWrapper>();
			for(Content_Category__c node : children) {
				ContentCategoryWrapper childWrapper = new ContentCategoryWrapper();
				childWrapper.ContentCategory = node;
				ContentCategoryWrapper[] grandChildren = findChildren(node, newRemainingNodes);
				childWrapper.children = grandChildren;
				wrappers.add(childWrapper);
			}
			return wrappers;
		}
	}


	//Everything that gets returned or inserted/updated/deleted has to pass FLS checks. 
	//These are convenience methods I made for this. You can just do it once for at the top of the function with a list of all the fields that might be passed. 
	//The second function will accept an sObject you are passing back for insert/update and do the checks without needing to list all the fields explicitly.
	@TestVisible
	private static void checkAccess(string sobjectName, String[] fields, string accessType){

		SObjectType sobj = Schema.getGlobalDescribe().get(sobjectName);
		if(sobj == null) {
			AuraHandledException e = new AuraHandledException('Access to one or more necessary objects is restricted for the current user: ' + sobjectName);
			e.setMessage('Access to one or more necessary objects is restricted for the current user: ' + sobjectName);
			throw e;
		}

		Map<String,Schema.SObjectField> sobjectfields = sobj.getDescribe().fields.getMap();
		String[] systemFields = new String[] {
			'Id',
			'IsDeleted',
			'CreatedBy',
			'CreatedById',
			'CreatedDate',
			'LastModifiedBy',
			'LastModifiedById',
			'LastModifiedDate',
			'SystemModstamp'
		};



		if(accessType == 'create') {
			for (String field : fields) {
				// Check if the user has access to field
				if(systemFields.indexOf(field) > -1 || sobjectfields.get(field).getDescribe().isCalculated() || sobjectfields.get(field).getDescribe().isAutoNumber()) continue;
				if (!sobjectfields.get(field).getDescribe().isCreateable()) {
					// Pass error to client
					// Due to a quirk with AuraHandledException, the message is only passed to the client when the message is set in both ways
					// as it is below.
					AuraHandledException e = new AuraHandledException('Access to one or more necessary fields is restricted for the current user: ' + field);
					e.setMessage('Access to one or more necessary fields is restricted for the current user: ' + field);
					throw e;
				}
			}
		} else if(accessType == 'read') {
			for (String field : fields) {
				if (!sobjectfields.get(field).getDescribe().isAccessible()) {
					AuraHandledException e = new AuraHandledException('Access to one or more necessary fields is restricted for the current user: ' + field);
					e.setMessage('Access to one or more necessary fields is restricted for the current user: ' + field);
					throw e;

				}
			}
		} else if(accessType == 'update') {
			for (String field : fields) {
				if(systemFields.indexOf(field) > -1 || sobjectfields.get(field).getDescribe().isCalculated() || sobjectfields.get(field).getDescribe().isAutoNumber()) continue;
				if (!sobjectfields.get(field).getDescribe().isUpdateable()) {
					AuraHandledException e = new AuraHandledException('Access to one or more necessary fields is restricted for the current user: ' + field);
					e.setMessage('Access to one or more necessary fields is restricted for the current user: ' + field);
					throw e;
				}
			}
		} else if(accessType == 'delete') {
			if (!sobj.getDescribe().isDeletable()) {
				AuraHandledException e = new AuraHandledException('Access to one or more necessary objects is restricted for the current user.');
				e.setMessage('Access to one or more necessary objects is restricted for the current user.');
				throw e;
			}
		}

	}

	//for updates of sObjects passed from client
	@TestVisible
	private static void checkAccess(string sobjectName, sObject objectToCheck, string accessType){

		SObjectType sobj = Schema.getGlobalDescribe().get(sobjectName);
		if(sobj == null) {
			AuraHandledException e = new AuraHandledException('Access to one or more necessary objects is restricted for the current user: ' + sobjectName);
			e.setMessage('Access to one or more necessary objects is restricted for the current user: ' + sobjectName);
			throw e;
		}
		Map<String,Schema.SObjectField> sobjectfields = sobj.getDescribe().fields.getMap();

		Map<String, Object> fieldMap = objectToCheck.getPopulatedFieldsAsMap();
		Set<string> fields = fieldMap.keySet();
		string[] fieldList = new string[] {};
		for( string field : fields ) {
			if(field.indexOf('__r') > -1) field = field.replace('__r', '__c');
			fieldList.add(field);
		}
		//RFP_MainController.checkAccess(sobjectName, fieldList, accessType);
	}
}