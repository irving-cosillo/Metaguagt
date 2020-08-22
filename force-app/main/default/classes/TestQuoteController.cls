@IsTest
public with sharing class TestQuoteController {
    @IsTest
    static void quoteControllerTest(){
        Quote__c quote = TestSetup.createQuote();
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(quote);
        QuoteController quoteController = new QuoteController(sc);
        System.assertEquals(quote.Id, quoteController.quote.Id, 'Incorrect quote Id retrieved.');
        Test.stopTest();
    }
}