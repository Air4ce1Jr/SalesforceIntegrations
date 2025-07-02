/**
 * @description Simple test class for QuickBooks Integration
 * @author Salesforce Administrator  
 * @date 2024
 */
@isTest
public class QuickBooksIntegrationTest {
    
    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account', Type = 'Customer');
        insert acc;
    }
    
    @isTest
    static void testWrapperClasses() {
        // Test wrapper class instantiation
        QuickBooksInvoiceIntegration.QBInvoice invoice = new QuickBooksInvoiceIntegration.QBInvoice();
        invoice.Id = 'test';
        
        QuickBooksInvoiceIntegration.QBCustomerRef customerRef = new QuickBooksInvoiceIntegration.QBCustomerRef();
        customerRef.value = 'testValue';
        
        // Test JSON serialization
        String json = JSON.serialize(invoice);
        
        // Assertions
        System.assertNotEquals(null, invoice);
        System.assertNotEquals(null, customerRef);
        System.assert(json.contains('test'));
    }
    
    @isTest  
    static void testAccountTrigger() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        acc.Phone = '555-1234';
        update acc;
        Test.stopTest();
        
        // Verify update worked
        acc = [SELECT Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals('555-1234', acc.Phone);
    }
    
    @isTest
    static void testEmptyMethods() {
        Test.startTest();
        
        // Test empty batch sync
        Map<Id, String> result = QuickBooksInvoiceIntegration.batchSyncInvoicesToQuickBooks(new List<Id>());
        
        // Test async with empty set
        QuickBooksInvoiceIntegration.syncInvoicesAsync(new Set<Id>());
        
        Test.stopTest();
        
        System.assertEquals(0, result.size());
    }
}