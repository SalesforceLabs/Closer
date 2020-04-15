public with sharing class ContentCategorySharing {
  
  public class ContentGuideException extends Exception {}

  @AuraEnabled
  public static Boolean shareContentCategories (String userId, string recordId) {
    try{
      if(userId == null) throw new ContentGuideException('USER_NOT_FOUND');
      content_category__c record = [select id, name from content_category__c where id = :recordId];
      List<content_category__c> contentCategoriesToShare = new List<content_category__c>{record};
      contentCategoriesToShare.addAll(getDescendents(new content_category__c[]{record}));

      ContentCategorySharing.checkAccess('Closer__content_category__c', record, 'read');
      ContentCategorySharing.checkAccess('Closer__content_category__c', record, 'create');

      return createContentCategoryShares(contentCategoriesToShare, userId);
    }catch(exception e){
      throw new AuraHandledException(e.getMessage());
    }
  }


  @AuraEnabled
  public static void unShareContentCategories (String userId, string recordId) {
    try{
      if(userId == null) throw new ContentGuideException('USER_NOT_FOUND');
      
      content_category__c record = [select id, name from content_category__c where id = :recordId];

      ContentCategorySharing.checkAccess('Closer__content_category__c', record, 'read');
      ContentCategorySharing.checkAccess('Closer__content_category__c', record, 'delete');

      List<content_category__c> contentCategoriesToUnShare = new List<content_category__c>{record};
      contentCategoriesToUnShare.addAll(getDescendents(new content_category__c[]{record}));
      delete [select id from content_category__Share where ParentId in :contentCategoriesToUnShare and UserOrGroupId = :userId];
    }catch(exception e){
      throw new AuraHandledException(e.getMessage()); 
    }
  }


  public static List<content_category__c> getDescendents (content_category__c[] recordIds) {

  List<content_category__c> contentCategories = [select id, name from content_category__c where Parent_Content_Category__c in :recordIds];

  if(contentCategories.size() == 0){
    return contentCategories;
  } else {
    contentCategories.addAll(getDescendents(contentCategories));
    return contentCategories;
  }
  }
  
  
  public static UserRecordAccess[] getAlreadySharedUserRecordAccess (content_category__c[] contentCategoriesToShare, string userOrGroupId) {

    // UserRecordAccess queries do not permit OFFSET clause and can only return 200 results. Because UserRecordAccess records are uniqe with respect to
    // UserId and RecordId, slicing the 'contentCategoryIds' into batches of 200 inside a loop accomplishes the same goal as OFFSET.
    List<content_category__c[]> batchedCategories = sliceCategoriesToShare(contentCategoriesToShare);
    UserRecordAccess[] allSharedRecords = new UserRecordAccess[]{};

    for(content_category__c[] batch : batchedCategories){
      //must pass set or list of ids to this query
      Set<Id> contentCategoryIds = (new Map<Id,content_category__c>(batch)).keySet();
      UserRecordAccess[] sharedRecordBatch = [
      SELECT RecordId
      FROM UserRecordAccess
      WHERE UserId = :userOrGroupId
      AND RecordId in :contentCategoryIds
      AND HasReadAccess = true
      ];

      allSharedRecords.addAll(sharedRecordBatch);

    }
    
    return allSharedRecords;
     
  }


  public static List<content_category__c[]> sliceCategoriesToShare(content_category__c[] categoriesToShare){
    List<content_category__c[]> batchedCategories = new List<content_category__c[]> {};
    integer added = 0;
      integer startIdx = 0;
    while(added < categoriesToShare.size()){

      List<content_category__c> subResult = new List<content_category__c> {};
      for(integer i = startIdx; i < startIdx + 200 && i < categoriesToShare.size() ; i++){
        subResult.add(categoriesToShare[i]);
        added++;
      }

      startIdx = startIdx + 200;
      batchedCategories.add(subResult);
    }

    
    return batchedCategories;
  }
    
  public static boolean createContentCategoryShares(content_category__c[] contentCategoriesToShare, string userOrGroupId){
    content_category__Share[] shareRecords = new content_category__Share[]{};

    UserRecordAccess[] alreadySharedUserRecordAccess = getAlreadySharedUserRecordAccess(contentCategoriesToShare, userOrGroupId);
    Set<Id> alreadySharedContentCategoryIds = (new Map<Id,UserRecordAccess>(alreadySharedUserRecordAccess)).keySet();
    

    for(content_category__c c : contentCategoriesToShare ){

      if(alreadySharedContentCategoryIds.contains(c.Id)) continue;
      // Create new sharing object for the custom object Job.
      content_category__Share contentCategoryShare  = new content_category__Share();

      // Set the ID of record being shared.
      contentCategoryShare.ParentId = c.Id;
        
      // Set the ID of user or group being granted access.
      contentCategoryShare.UserOrGroupId = userOrGroupId;
        
      // Set the access level.
      contentCategoryShare.AccessLevel = 'Edit';
        
      // Set rowCause to 'manual' for manual sharing.
      // This line can be omitted as 'manual' is the default value for sharing objects.
      contentCategoryShare.RowCause = Schema.content_category__share.RowCause.Manual;
      shareRecords.add(contentCategoryShare);
    }
      
    // Insert the sharing record and capture the save result. 
    // The false parameter allows for partial processing if multiple records passed 
    // into the operation.

    if(shareRecords.size() > 0) ContentCategorySharing.checkAccess('Closer__content_category__Share', shareRecords[0], 'create');
    Database.SaveResult[] srs = Database.insert(shareRecords,false);

  boolean success = true;
  for(Database.SaveResult sr : srs){

    // Process the save results.
    if(!sr.isSuccess()){
        // Get first save result error.
        Database.Error err = sr.getErrors()[0];
        throw new AuraHandledException(err.getMessage());
        // Check if the error is related to trival access level.
        // Access level must be more permissive than the object's default.
        // These sharing records are not required and thus an insert exception is acceptable. 
        if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
                err.getMessage().contains('AccessLevel')){
          // Indicates success.
          continue;
        }
        else{
          // Indicates failure.
          success = false;
          break;
        }
      }
  }
  return success;
  }

    @AuraEnabled
    public static List<List<sObject>> userSearch (String query) {    
      try{
      string userId = UserInfo.getUserId();
      ContentCategorySharing.checkAccess('User', new String[]{'Name', 'Title', 'FullPhotoUrl', 'Id'}, 'read');      
      List<List<sObject>> users = search.query('Find \''+ query + '\' in Name Fields returning User (Name, Title, Manager.Name, FullPhotoUrl where ID != \''+ userId + '\' )');
      return users;
      }
      catch(exception e){
        throw new AuraHandledException(e.getMessage());
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
		ContentCategorySharing.checkAccess(sobjectName, fieldList, accessType);
	}


}