public with sharing class ClassTrigger {
    public static void updateProductStock(List<Product_Price__c> prices, Boolean assign){   
        Set<String> productsIdList = new Set<String>();
        for(Product_Price__c price : prices){
            productsIdList.add(price.Product__c);
        }

        List<Product__c> products = [SELECT Id, Stock__c, Related_Price__c,
                                    (SELECT Id, Quantity__c FROM Product_Prices__r ORDER BY Id DESC) 
                                     FROM Product__c
                                     WHERE Id IN :productsIdList];
        
        for(Product__c product : products){
            product.Stock__c = 0;
            for(Product_Price__c price : product.Product_Prices__r){
                if(product.Stock__c == 0 && assign){
                    product.Related_Price__c = price.Id;
                }
                product.Stock__c += price.Quantity__c;
            }
        }
    
        update(products);
    }
}