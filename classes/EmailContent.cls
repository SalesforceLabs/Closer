@RestResource(urlMapping='/email-content/*')
global with sharing class EmailContent {
    global class messageInfo{
        global string email;
        global string message;
        global string subject;
        global string[] contentVersionIds;
    }
    
    @HttpPost
    global static String doPost(messageInfo message) {
        try{
            
            string userName = UserInfo.getName();
            string userEmail = UserInfo.getUserEmail();
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            String[] toAddresses = new String[] {message.email};
                
            mail.setToAddresses(toAddresses);        
            
            // Specify the address used when the recipients reply to the email. 
            mail.setReplyTo(userEmail);
            
            // Specify the name used as the display name.
            mail.setSenderDisplayName(userName);
            
            // Specify the subject line for your email address.
            mail.setSubject(message.subject);
            
            // Set to True if you want to BCC yourself on the email.
            mail.setBccSender(true);
            
            // Optionally append the salesforce.com email signature to the email.
            // The email address of the user executing the Apex Code will be used.
            mail.setUseSignature(true);
            
            // Specify the text content of the email.
            mail.setPlainTextBody(message.message);
            
            mail.setEntityAttachments(message.contentVersionIds);
            
            // Send the email you have created.
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
            return 'success';
        }
        catch(exception e){
            return e.getMessage();
        }
    }
}