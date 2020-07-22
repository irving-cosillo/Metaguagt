public with sharing class QuoteController {
    public Quote__c quote {get;set;}
    public Contact contact {get;set;}
    public Account account {get;set;}
    public List<Quote_Line__c> childLines {get;set;}
    public List<Quote_Line__c> fatherLines {get;set;}
    public Company_Information__mdt company {get;set;}
    public List<Integer> rowspanList {get; set;}
    public String todaysDate {get; set;}
    
    public QuoteController(ApexPages.StandardController stdController) {
        Id quoteId = stdController.getRecord().Id;
        quote = [SELECT Name, 
                        Discount__c, 
                        Currency_Code__c, 
                        Account__c, 
                        Contact__c, 
                        Total__c,
                        Total_GTQ__c,
                        Total_USD__c,
                        Total_In_Letters__c,
                        Delivery_Time__c,
                        Offer_Time__c,
                        Payment__c,
                        Delivery_Address__c,
                        Sales_User__c 
                 FROM Quote__c WHERE Id =: quoteId LIMIT 1];
        account = [SELECT Name, 
                          ShippingAddress, 
                          Phone,
                          NIT__c
                   FROM Account WHERE Id =: quote.Account__c LIMIT 1];
        contact = [SELECT Name FROM Contact WHERE Id =: quote.Contact__c LIMIT 1];
        fatherLines = [SELECT Name, 
                             Delivery_Time__c, 
                             Description__c, 
                             Quantity__c,
                             Subtotal_GTQ__c, 
                             Subtotal_USD__c, 
                             Type__c,
                             Product__c,
                             Product__r.Name,
                             Product__r.Price_USD__c, 
                             Product__r.Price_GTQ__c
                      FROM Quote_Line__c 
                      WHERE Quote__c =: quoteId AND Type__c != 'Child'
                      ORDER BY Index__c ASC];
        childLines = [SELECT Name, 
                             Delivery_Time__c, 
                             Description__c, 
                             Quantity__c,
                             Subtotal_GTQ__c, 
                             Subtotal_USD__c, 
                             Type__c,
                             Product__c,
                             Product__r.Price_USD__c, 
                             Product__r.Price_GTQ__c
                      FROM Quote_Line__c 
                      WHERE Quote__c =: quoteId AND Type__c = 'Child'
                      ORDER BY Index__c ASC];
        company = [SELECT Legal_Name__c, 
                          Phone__c, 
                          Address__c, 
                          NIT__c 
                   FROM Company_Information__mdt LIMIT 1];

       List<String> months = new List<String>{'enero', 'febrero', 'marzo', 'abril', 
       'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'};

       Integer day = System.today().day();
       String month = months[System.today().month() - 1];
       Integer year = System.today().year();
       todaysDate = String.valueOf(day) + ' de ' + month + ' de ' + String.valueOf(year);
    }
}