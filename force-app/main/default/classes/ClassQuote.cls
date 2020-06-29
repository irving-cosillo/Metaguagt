public with sharing class ClassQuote {
    @AuraEnabled
    public static Quote__c getQuote(String quoteId) {
        return [SELECT Name, Currency_Code__c, Discount__c, Total_In_Letters__c, Converted__c
                FROM Quote__c WHERE Id =: quoteId];
    }

    @AuraEnabled
    public static List<Quote_Line__c> getQuoteLines(String quoteId) {
        return [SELECT  Id,
                        Quote__c,
                        Product__c,
                        Index__c,
                        Description__c,
                        Time__c,
                        Quantity__c,
                        Type__c,
                        Time_In_Days__c,
                        Delivery_Time__c,
                        Brand__c,
                        Family__c,
                        Subfamily__c,
                        Unit__c,
                        Material__c,
                        Dimensions__c
                FROM Quote_Line__c
                WHERE Quote__c =: quoteId
                ORDER BY Index__c ASC];
    }

    @AuraEnabled
    public static List<Quote_Line__c> getProductsOfLines(String quoteId) {
        return [SELECT  Product__r.Id,
                        Product__r.Name,
                        Product__r.Old_Code__c,
                        Product__r.Description__c,
                        Product__r.Brand__c,
                        Product__r.Family__c,
                        Product__r.Subfamily__c,
                        Product__r.Unit__c,
                        Product__r.Material__c,
                        Product__r.Dimensions__c,
                        Product__r.Stock__c,
                        Product__r.Inventory_State__c,
                        Product__r.Price_GTQ__c,
                        Product__r.Price_USD__c
                FROM Quote_Line__c
                WHERE Quote__c =: quoteId
                ORDER BY Index__c ASC];
    }

    @AuraEnabled
    public static void saveQuote(Quote__c quote, List<Quote_Line__c> data) {
        String userId = UserInfo.getUserId();
        User user = [SELECT Discount_Max__c FROM User WHERE Id =: userId];

        if(user.Discount_Max__c < quote.Discount__c){
            throw new AuraHandledException('El descuento ingresado excede el rango que usted está autorizado.');
        }
        if(quote.Discount__c < 0){
            throw new AuraHandledException('El descuento ingresado no puede ser menor a 0.');
        }

        List<Quote_Line__c> linesToDelete = [
            SELECT Id
            FROM Quote_Line__c
            WHERE Id NOT IN : data AND Quote__c =: quote.Id];

        delete(linesToDelete);
        upsert(quote);
        upsert(data);
    }
}