public with sharing class ClassBatch {
    @AuraEnabled
    public static void submitBatch(Price_Batch__c batch, List<Price_Batch_Line__c> batchLines){
        List<Price_Batch_Line__c> batchLinesToDelete = [SELECT Id
                                                    FROM Price_Batch_Line__c
                                                    WHERE Id NOT IN : batchLines AND Price_Batch__c =: batch.Id];
        delete batchLinesToDelete;
        upsert batchLines;

        batch.Converted__c = true;
        update batch;

        Product_Price__c price;
        List<Product_Price__c> prices = new List<Product_Price__c>();
        for(Price_Batch_Line__c batchLine : batchLines){
            price = new Product_Price__c();
            price.Quantity__c = batchLine.Quantity__c;
            price.Dollar_Cost__c = batch.Dollar_Cost__c;
            price.Unit_Cost_USD__c = batchLine.Unit_Cost_USD__c;
            price.Unit_Cost_GTQ__c = batchLine.Unit_Cost_GTQ__c;
            price.External_Shipping__c = batch.External_Shipping_GTQ__c * batchLine.Shipping__c / 100;
            price.External_Shipping_USD__c = batch.External_Shipping_USD__c * batchLine.Shipping__c / 100;
            price.Internal_Shipping__c = batch.Internal_Shipping__c * batchLine.Shipping__c / 100;
            price.Taxes__c = batch.Taxes__c * batchLine.Taxes__c / 100;
            price.Profit__c = batchLine.Profit__c;
            price.Unit_Price_GTQ__c = batchLine.Unit_Price_GTQ__c;
            price.Product__c = batchLine.Product__c;
            price.Price_Batch__c = batch.Id;
            prices.add(price);
        }

        insert(prices);
    }

    @AuraEnabled
    public static void saveBatch(Price_Batch__c batch, List<Price_Batch_Line__c> batchLines){
        List<Price_Batch_Line__c> batchLinesToDelete = [SELECT Id
                                                    FROM Price_Batch_Line__c
                                                    WHERE Id NOT IN : batchLines AND Price_Batch__c =: batch.Id];
        delete batchLinesToDelete;
        upsert batchLines;
    }

    @AuraEnabled
    public static Price_Batch__c getBatch(String batchId){
        return [SELECT  Taxes__c,
                        Converted__c,
                        Dollar_Cost__c,
                        Internal_Shipping__c,
                        External_Shipping_GTQ__c,
                        External_Shipping_USD__c
                FROM Price_Batch__c
                WHERE Id =: batchId];
    }

    @AuraEnabled
    public static List<Price_Batch_Line__c> getBatchLines(String batchId){
        return [SELECT  Id,
                        Quantity__c,
                        Unit_Cost_USD__c,
                        Unit_Cost_GTQ__c,
                        Shipping__c,
                        Taxes__c,
                        Profit__c,
                        Unit_Price_GTQ__c,
                        Product__c,
                        Product_Name__c,
                        Product_Description__c,
                        Price_Batch__c
                FROM Price_Batch_Line__c
                WHERE Price_Batch__c =: batchId];
    }
}
