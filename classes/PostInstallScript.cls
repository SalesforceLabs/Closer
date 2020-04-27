global with sharing class PostInstallScript implements InstallHandler {
  global void onInstall(InstallContext context) {        
      User u = [Select Id, Email, Name from User where Id =:context.installerID()];
      Organization o = [Select Id, Name, organizationtype, issandbox from Organization where Id =:context.organizationId()];
      String toAddress= 'ryan.mcconnell@salesforce.com';
      String[] toAddresses = new String[]{toAddress};
      Messaging.SingleEmailMessage mail = 
        new Messaging.SingleEmailMessage();
      mail.setToAddresses(toAddresses);
      mail.setSubject('Closer installation');
      mail.setPlainTextBody(
          'User Name: ' + u.Name + '\n' +
          'User Email: ' + u.Email + '\n' + 
          'User Id: ' + u.Id + '\n\n' +
          'Org Name: ' + o.Name + '\n' +
          'Org Type: ' + o.organizationtype + '\n' +
          'Org Id: ' + o.Id + '\n' +
          'Org Is Sandbox: ' + o.issandbox + '\n' +
          'Is upgrade: ' + context.isUpgrade()
      );
      Messaging.sendEmail(new Messaging.Email[] { mail });
      }
  }
