public with sharing class ClassProduct {

    @AuraEnabled (cacheable = true)
    public static List<Product__c> getProducts(String input){
        String check = input.replace(' ', '');
        String searchValue = check.length() <= 0 ? '' : '%' + input + '%';

        return [
            SELECT  Id,
                    Name,
                    Description__c,
                    Brand__c,
                    Family__c,
                    Subfamily__c,
                    Unit__c,
                    Stock__c,
                    Inventory_State__c,
                    Price_GTQ__c,
                    Price_USD__c,
                    Related_Price__c,
                    Related_Price__r.Unit_Price_GTQ__c,
                    Related_Price__r.Unit_Price_USD__c
            FROM Product__c
            WHERE Name LIKE : searchValue
            OR Description__c LIKE : searchValue
            LIMIT 20
        ];
    }
}