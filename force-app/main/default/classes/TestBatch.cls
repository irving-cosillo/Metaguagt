@IsTest
public class TestBatch {
    @TestSetup
    static void testSetup(){
        TestSetup.createProducts();
        Price_Batch__c batch = new Price_Batch__c();
        batch.Taxes__c = 0;
        batch.Dollar_Cost__c = 0;
        batch.Internal_Shipping__c = 0;
        batch.External_Shipping_GTQ__c = 0;
        batch.External_Shipping_USD__c = 0;
        insert batch;
    }

    static List<Price_Batch_Line__c> generateBatchLines(String batchId){
        List<Product__c> products = [SELECT Id FROM Product__c];
        List<Price_Batch_Line__c> batchLines = new List<Price_Batch_Line__c> ();
        Price_Batch_Line__c batchLine;

        batchLine = new Price_Batch_Line__c();
        batchLine.Price_Batch__c = batchId;
        batchLine.Shipping__c = 50;
        batchLine.Profit__c = 50;
        batchLine.Taxes__c = 50;
        batchLine.Quantity__c = 50;
        batchLine.Unit_Cost_USD__c = 0;
        batchLine.Unit_Cost_GTQ__c = 50;
        batchLine.Unit_Price_GTQ__c = 75;
        batchLine.Product__c = products[0].Id;
        batchLines.add(batchLine);

        batchLine = new Price_Batch_Line__c();
        batchLine.Price_Batch__c = batchId;
        batchLine.Shipping__c = 50;
        batchLine.Profit__c = 50;
        batchLine.Taxes__c = 50;
        batchLine.Quantity__c = 50;
        batchLine.Unit_Cost_USD__c = 0;
        batchLine.Unit_Cost_GTQ__c = 50;
        batchLine.Unit_Price_GTQ__c = 75;
        batchLine.Product__c = products[1].Id;
        batchLines.add(batchLine);

        return batchLines;
    }

    @IsTest
    static void saveBatch(){
        Price_Batch__c batch = [SELECT Id FROM Price_Batch__c LIMIT 1];
        List<Price_Batch_Line__c> batchLines = generateBatchLines(batch.Id);

        Test.startTest();
        ClassBatch.saveBatch(batch, batchLines);
        List<Price_Batch_Line__c> expectedBatchLines = [SELECT Id FROM Price_Batch_Line__c];
        System.assertEquals(expectedBatchLines.size(), batchLines.size(),'Incorrect number of lines created.');
        Test.stopTest();
    }

    @IsTest
    static void getBatch(){
        Price_Batch__c batch = [SELECT Id, Dollar_Cost__c FROM Price_Batch__c LIMIT 1];
        Test.startTest();
        Price_Batch__c expectedBatch = ClassBatch.getBatch(batch.Id);
        System.assertEquals(expectedBatch.Dollar_Cost__c, batch.Dollar_Cost__c, 'Incorrect batch retrieved.');
        Test.stopTest();
    }

    @IsTest
    static void getBatchLines(){
        Price_Batch__c batch = [SELECT Id, Dollar_Cost__c FROM Price_Batch__c LIMIT 1];
        List<Price_Batch_Line__c> batchLines = generateBatchLines(batch.Id);
        ClassBatch.saveBatch(batch, batchLines);
        Test.startTest();
        List<Price_Batch_Line__c> expectedBatchLines = ClassBatch.getBatchLines(batch.Id);
        System.assertEquals(expectedBatchLines.size(), batchLines.size(), 'Incorrect batch lines retrieved.');
        Test.stopTest();
    }

    @IsTest
    static void submitBatch(){
        Price_Batch__c batch = [
            SELECT Id, Taxes__c, Dollar_Cost__c, Internal_Shipping__c, External_Shipping_GTQ__c, External_Shipping_USD__c
            FROM Price_Batch__c
            LIMIT 1
        ];

        List<Price_Batch_Line__c> batchLines = generateBatchLines(batch.Id);
        Test.startTest();
        ClassBatch.submitBatch(batch, batchLines);
        batch = [SELECT Converted__c FROM Price_Batch__c LIMIT 1];
        System.assertEquals(true, batch.Converted__c, 'Batch not converted.');
        Test.stopTest();
    }
}