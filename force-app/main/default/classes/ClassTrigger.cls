public with sharing class ClassTrigger {

    private static List<Product__c> getProductsToUpdate(List<Product_Price__c> prices){
        Set<String> productsIdSet = new Set<String>();
        for(Product_Price__c price : prices){
            productsIdSet.add(price.Product__c);
        }

        return !isQueryable() ? null : [
            SELECT Id, Stock__c, Related_Price__c,
                (SELECT Id, Quantity__c FROM Product_Prices__r ORDER BY Id DESC)
            FROM Product__c
            WHERE Id IN : productsIdSet
        ];
    }

    private static Boolean isQueryable (){
        return Schema.sObjectType.Product__c.isQueryable() && Schema.sObjectType.Product_Price__c.isQueryable();
    }

    public static void deletePrices(List<Product_Price__c> oldPrices){
        List<Product__c> products = getProductsToUpdate(oldPrices);
        for(Product__c product : products){
            product.Related_Price__c = product.Product_Prices__r[0].Id;
        }

        if ( Schema.sObjectType.Product__c.isUpdateable() ){
            update(products);
        }
    }


    public static void addProductStock(List<Product_Price__c> prices){
        List<Product__c> products = getProductsToUpdate(prices);

        Decimal stockToAdd;
        for(Product__c product : products){
            product.Related_Price__c = product.Product_Prices__r[0].Id;
            stockToAdd = 0;
            for(Product_Price__c price : product.Product_Prices__r){
                stockToAdd += price.Quantity__c;
            }

            product.Stock__c += stockToAdd;
        }

        if ( Schema.sObjectType.Product__c.isUpdateable() ){
            update(products);
        }
    }

    public static void updateProductStock(List<Product_Price__c> prices){
        for(Product_Price__c price : prices){
            price.addError('Los precios no pueden ser actualizados, intente crear uno nuevo.');
        }
    }
}