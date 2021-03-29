public with sharing class ClassTrigger {

    private static Map<Id, Product__c> getProductsToUpdate(List<Product_Price__c> prices){
        Set<String> productsIdSet = new Set<String>();
        for(Product_Price__c price : prices){
            productsIdSet.add(price.Product__c);
        }

        Map<Id, Product__c> result = new Map<Id, Product__c>([
            SELECT
                Id,
                Stock__c,
                Related_Price__c,
                (SELECT Id, Quantity__c FROM Product_Prices__r ORDER BY Id DESC)
            FROM Product__c
            WHERE Id IN : productsIdSet
        ]);

        return !isQueryable() ? null : result;
    }

    private static Boolean isQueryable (){
        return Schema.sObjectType.Product__c.isQueryable() && Schema.sObjectType.Product_Price__c.isQueryable();
    }

    public static void deletePrices(List<Product_Price__c> oldPrices){
        Map<Id, Product__c> productsMap = getProductsToUpdate(oldPrices);
        List<Product__c> products = productsMap.values();

        for(Product__c product : products){
            product.Related_Price__c = product.Product_Prices__r[0].Id;
        }

        if ( Schema.sObjectType.Product__c.isUpdateable() ){
            update(products);
        }
    }


    public static void addProductStock(List<Product_Price__c> prices){
        Map<Id, Product__c> productsMap = getProductsToUpdate(prices);
        for(Product__c product : productsMap.values()){
            product.Related_Price__c = product.Product_Prices__r[0].Id;
        }

        for(Product_Price__c price : prices){
            productsMap.get(price.Product__c).Stock__c += price.Quantity__c;
        }

        if ( Schema.sObjectType.Product__c.isUpdateable() ){
            update(productsMap.values());
        }
    }

    public static void updateProductStock(List<Product_Price__c> prices){
        for(Product_Price__c price : prices){
            price.addError('Los precios no pueden ser actualizados, intente crear uno nuevo.');
        }
    }
}