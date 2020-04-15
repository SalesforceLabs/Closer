@isTest
private class MobileContentGuideTest {
	
  @isTest static void shareContentCategories() {
    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
    User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
    LocaleSidKey='en_US', ProfileId = p.Id, 
    TimeZoneSidKey='America/Los_Angeles', UserName= Math.random() + '@testorg.com');
    insert u;
    

    content_category__c c = new content_category__c();
    c.name = 'test';
    insert c;

    System.runAs(u){
      try{
        ContentCategorySharing.shareContentCategories(u.Id, c.Id);
      }catch(exception e){
        System.assertEquals('Script-thrown exception', e.getMessage());
      }
    }


    user admin = [select id from user where profile.name = 'System Administrator' limit 1];
    system.runAs(admin){
      PermissionSet perm = [select id from permissionset where name = 'Closer']; 
      PermissionSetAssignment psa = new PermissionSetAssignment();
      psa.permissionSetId = perm.Id;
      psa.assigneeId = u.Id;
      insert psa;
    }


    

    UserRecordAccess[] access = new UserRecordAccess[]{};
    
      ContentCategorySharing.shareContentCategories(u.Id, c.Id);
      
      access = [
      SELECT RecordId
      FROM UserRecordAccess
      WHERE UserId = :u.Id
      AND RecordId = :c.Id
      AND HasReadAccess = true
      ];
      System.assertEquals(1, access.size());
    
    
    try{
      ContentCategorySharing.shareContentCategories(null, null);
    }catch(exception e){
      System.assertEquals('Script-thrown exception', e.getMessage());
    }
    
	}
  @isTest static void unShareContentCategories() {
    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
    User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
    LocaleSidKey='en_US', ProfileId = p.Id, 
    TimeZoneSidKey='America/Los_Angeles', UserName= Math.random() + '@testorg.com');
    insert u;
    content_category__c c = new content_category__c();
    c.name = 'test';
    insert c;
    
    ContentCategorySharing.shareContentCategories(u.Id, c.Id);

    System.runAs(u){
      try{
        ContentCategorySharing.unShareContentCategories(u.Id, c.Id);
      }catch(exception e){
        System.assertEquals('Script-thrown exception', e.getMessage());
      }
    }
    user admin = [select id from user where profile.name = 'System Administrator' limit 1];
    system.runAs(admin){
      PermissionSet perm = [select id from permissionset where name = 'Mobile_Content_Guide']; 
      PermissionSetAssignment psa = new PermissionSetAssignment();
      psa.permissionSetId = perm.Id;
      psa.assigneeId = u.Id;
      insert psa;
    }
    
    UserRecordAccess[] access = new UserRecordAccess[]{};
    
      ContentCategorySharing.shareContentCategories(u.Id, c.Id);
      ContentCategorySharing.unShareContentCategories(u.Id, c.Id);
      access = [
      SELECT RecordId
      FROM UserRecordAccess
      WHERE UserId = :u.Id
      AND RecordId = :c.Id
      AND HasReadAccess = true
      ];
      System.assertEquals(0, access.size());

    try{
      ContentCategorySharing.unShareContentCategories(null, null);
    }catch(exception e){
      System.assertEquals('Script-thrown exception', e.getMessage());
    }
    
	}


  @isTest static void userSearch() {
    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
    User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
    LocaleSidKey='en_US', ProfileId = p.Id, 
    TimeZoneSidKey='America/Los_Angeles', UserName= Math.random() + '@testorg.com');
    insert u;
    
    System.assertEquals(true, ContentCategorySharing.userSearch('test').size() > 0);

    
	}
	
	@isTest static void doPost() {
    EmailContent.messageInfo msg = new EmailContent.messageInfo();

    msg.email = 'test@test.test';
    msg.message = 'test';
    msg.subject = 'test';
    msg.contentVersionIds = new string[]{};

    EmailContent.doPost(msg);
    EmailContent.doPost(null);
	}

	@isTest static void upsertFile() {

    content_category__c cc = new content_category__c();
    insert cc;
    PS_categoryTreeBuilder_CT.upsertFile('R0lGODlhEAAQAMQAAORHHOVSKudfOulrSOp3WOyDZu6QdvCchPGolfO0o/XBs/fNwfjZ0frl3/zy7////wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAkAABAALAAAAAAQABAAAAVVICSOZGlCQAosJ6mu7fiyZeKqNKToQGDsM8hBADgUXoGAiqhSvp5QAnQKGIgUhwFUYLCVDFCrKUE1lBavAViFIDlTImbKC5Gm2hB0SlBCBMQiB0UjIQA7', 
    'new', 
    'new', 
    'banner', 
    'test', 
    cc.Id);

  }

	@isTest static void updateContentCategoryParent() {
    
		content_category__c cc1 = new content_category__c();
		content_category__c cc2 = new content_category__c();
		content_category__c cc3 = new content_category__c();
    cc1.name = 'cc1';
    cc2.name = 'cc2';
    cc3.name = 'cc3';

    // insert Parent_Content_Category__c
    insert new content_category__c[]{cc1, cc2, cc3};
    cc1.Parent_Content_Category__c = cc2.Id;
    update cc1;
    PS_categoryTreeBuilder_CT.updateContentCategoryParent(cc3.Id, cc1.Id);
    // System.AssertEquals(true, cc1.Parent_Content_Category__c == cc3.Id);
    PS_categoryTreeBuilder_CT.updateContentCategoryParent('top', cc1.Id);
    // System.AssertEquals(true, cc1.Parent_Content_Category__c == null);
	}
	@isTest static void getContentCategoryWithAttachments() {

		content_category__c cc1 = new content_category__c();
    insert cc1;
    PS_categoryTreeBuilder_CT.getContentCategoryWithAttachments(cc1.Id);
		
	}
	@isTest static void getAllContentCategories() {
    content_category__c cc1 = new content_category__c();
    content_category__c cc2 = new content_category__c();
    content_category__c cc3 = new content_category__c();
    cc1.name = 'cc1';
    cc2.name = 'cc2';
    cc3.name = 'cc3';

    // insert Parent_Content_Category__c
    insert new content_category__c[]{cc1, cc2, cc3};
		PS_categoryTreeBuilder_CT.getAllContentCategories();
	}
	@isTest static void checkAccess() {
    content_category__c cc1 = new content_category__c();
    cc1.Name = 'test';
    cc1.Parent_Content_Category__c = null;
    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
    User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
    LocaleSidKey='en_US', ProfileId = p.Id, 
    TimeZoneSidKey='America/Los_Angeles', UserName= Math.random() + '@testorg.com');
    insert u;
    System.runAs(u){

      try{
        PS_categoryTreeBuilder_CT.checkAccess( 'Closer__content_category__c',  new string[]{'name', 'Parent_Content_Category__c'}, 'read');
      }catch(exception e){
        System.assertEquals(true, e.getMessage().length() > 0);
      }
      try{
        PS_categoryTreeBuilder_CT.checkAccess( 'Closer__content_category__c',  new string[]{'name', 'Parent_Content_Category__c'}, 'create');
      }catch(exception e){
        System.assertEquals(true, e.getMessage().length() > 0);
      }
      try{
        PS_categoryTreeBuilder_CT.checkAccess( 'Closer__content_category__c',  new string[]{'name', 'Parent_Content_Category__c'}, 'update');
      }catch(exception e){
        System.assertEquals(true, e.getMessage().length() > 0);
      }
      try{
        PS_categoryTreeBuilder_CT.checkAccess( 'Closer__content_category__c',  new string[]{'name', 'Parent_Content_Category__c'}, 'delete');
      }catch(exception e){
        System.assertEquals(true, e.getMessage().length() > 0);
      }



      try{
        PS_categoryTreeBuilder_CT.checkAccess( 'Closer__content_category__c',  cc1, 'read');
      }catch(exception e){
        System.assertEquals(true, e.getMessage().length() > 0);
      }
      try{
        PS_categoryTreeBuilder_CT.checkAccess( 'Closer__content_category__c',  cc1, 'create');
      }catch(exception e){
        System.assertEquals(true, e.getMessage().length() > 0);
      }
      try{
        PS_categoryTreeBuilder_CT.checkAccess( 'Closer__content_category__c',  cc1, 'update');
      }catch(exception e){
        System.assertEquals(true, e.getMessage().length() > 0);
      }
      try{
        PS_categoryTreeBuilder_CT.checkAccess( 'Closer__content_category__c',  cc1, 'delete');
      }catch(exception e){
        System.assertEquals(true, e.getMessage().length() > 0);
      }
    }
	}
    
    @isTest
    static void testInstallScript() {
        PostInstallScript postinstall = new PostInstallScript();
        Test.testInstall(postinstall, null);
        Test.testInstall(postinstall, new Version(1,0), true);
    }
}