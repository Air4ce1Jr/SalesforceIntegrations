/**
 * @description Test class for QuickBooks Integration with service architecture
 * @author Salesforce Administrator  
 * @date 2024
 */
@isTest
public class QuickBooksIntegrationTest {
    
    @testSetup
    static void setup() {
        Account acc = new Account(
            Name = 'Test Customer Account', 
            Type = 'Customer',
            Phone = '(555) 123-4567',
            BillingStreet = '123 Test Street',
            BillingCity = 'Test City',
            BillingState = 'CA',
            BillingPostalCode = '90210'
        );
        insert acc;
    }
    
    @isTest
    static void testSuccessfulCustomerSync() {
        Test.startTest();
        
        // Set up mock service for success
        QuickBooksInvoiceIntegration.setService(new QuickBooksMockService(false, null));
        
        Account acc = [SELECT Id, Name, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode FROM Account LIMIT 1];
        
        // Test customer sync
        String result = QuickBooksInvoiceIntegration.ensureCustomerExists(acc);
        
        Test.stopTest();
        
        // Verify success
        System.assert(!result.startsWith('Error:'), 'Customer sync should succeed');
        System.assert(result.startsWith('MOCK_CUSTOMER_'), 'Should return mock customer ID');
    }
    
    @isTest
    static void testFailedCustomerSync() {
        Test.startTest();
        
        // Set up mock service for failure
        QuickBooksInvoiceIntegration.setService(new QuickBooksMockService(true, 'Customer sync failed'));
        
        Account acc = [SELECT Id, Name, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode FROM Account LIMIT 1];
        
        // Test customer sync
        String result = QuickBooksInvoiceIntegration.ensureCustomerExists(acc);
        
        Test.stopTest();
        
        // Verify failure
        System.assert(result.startsWith('Error:'), 'Customer sync should fail');
        System.assert(result.contains('Customer sync failed'), 'Should contain error message');
    }
    
    @isTest
    static void testConnectionTest() {
        Test.startTest();
        
        // Test successful connection
        QuickBooksInvoiceIntegration.setService(new QuickBooksMockService(false, null));
        Boolean successResult = QuickBooksInvoiceIntegration.testQuickBooksConnection();
        
        // Test failed connection
        QuickBooksInvoiceIntegration.setService(new QuickBooksMockService(true, 'Connection failed'));
        Boolean failResult = QuickBooksInvoiceIntegration.testQuickBooksConnection();
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(true, successResult, 'Connection test should succeed');
        System.assertEquals(false, failResult, 'Connection test should fail');
    }
    
    @isTest
    static void testRealmIdRetrieval() {
        Test.startTest();
        
        QuickBooksInvoiceIntegration.setService(new QuickBooksMockService());
        String realmId = QuickBooksInvoiceIntegration.getRealmId();
        
        Test.stopTest();
        
        System.assertEquals('9341454816381446', realmId, 'Should return correct realm ID');
    }
    
    @isTest
    static void testBatchSyncEmptyList() {
        Test.startTest();
        
        QuickBooksInvoiceIntegration.setService(new QuickBooksMockService());
        
        // Test empty list handling
        Map<Id, String> result = QuickBooksInvoiceIntegration.batchSyncInvoicesToQuickBooks(new List<Id>());
        
        // Test null list handling
        Map<Id, String> nullResult = QuickBooksInvoiceIntegration.batchSyncInvoicesToQuickBooks(null);
        
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Empty list should return empty results');
        System.assertEquals(0, nullResult.size(), 'Null list should return empty results');
    }
    
    @isTest
    static void testAsyncWithEmptySet() {
        Test.startTest();
        
        QuickBooksInvoiceIntegration.setService(new QuickBooksMockService());
        
        // Test async method with empty set
        QuickBooksInvoiceIntegration.syncInvoicesAsync(new Set<Id>());
        
        // Test async method with null set
        QuickBooksInvoiceIntegration.syncInvoicesAsync(null);
        
        Test.stopTest();
        
        // If we get here without exception, the test passed
        System.assert(true, 'Async methods should handle empty/null sets without errors');
    }
    
    @isTest
    static void testAccountTriggerLogic() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Update account to trigger customer sync logic
        acc.Phone = '(555) 987-6543';
        acc.BillingStreet = '456 Updated Street';
        update acc;
        
        Test.stopTest();
        
        // Verify update completed successfully
        Account updatedAccount = [SELECT Phone, BillingStreet FROM Account WHERE Id = :acc.Id];
        System.assertEquals('(555) 987-6543', updatedAccount.Phone, 'Phone should be updated');
        System.assertEquals('456 Updated Street', updatedAccount.BillingStreet, 'Street should be updated');
    }
    
    @isTest
    static void testDataModelConversion() {
        Test.startTest();
        
        Account testAccount = [SELECT Id, Name, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account LIMIT 1];
        
        // Test Account to QuickBooks Customer conversion
        QuickBooksModels.QBCustomer customer = QuickBooksModels.convertAccountToCustomer(testAccount);
        
        Test.stopTest();
        
        // Verify conversion
        System.assertEquals(testAccount.Name, customer.Name, 'Customer name should match account name');
        System.assertEquals(testAccount.Phone, customer.PrimaryPhone, 'Phone should match');
        System.assertNotEquals(null, customer.BillAddr, 'Billing address should be set');
        System.assertEquals(testAccount.BillingCity, customer.BillAddr.City, 'City should match');
    }
    
    @isTest
    static void testWrapperClassSerialization() {
        Test.startTest();
        
        // Test wrapper class instantiation and serialization
        QuickBooksModels.QBInvoice invoice = new QuickBooksModels.QBInvoice();
        invoice.Id = 'TEST123';
        invoice.TotalAmt = 1000.00;
        
        QuickBooksModels.QBCustomerRef customerRef = new QuickBooksModels.QBCustomerRef();
        customerRef.value = 'CUST123';
        customerRef.name = 'Test Customer';
        
        invoice.CustomerRef = customerRef;
        
        // Test serialization
        String json = JSON.serialize(invoice);
        
        Test.stopTest();
        
        // Verify serialization
        System.assert(json.contains('TEST123'), 'JSON should contain invoice ID');
        System.assert(json.contains('1000'), 'JSON should contain total amount');
        System.assert(json.contains('Test Customer'), 'JSON should contain customer name');
    }
    
    @isTest
    static void testServiceInterface() {
        Test.startTest();
        
        // Test that we can use the interface
        IQuickBooksService service = new QuickBooksMockService();
        
        // Test all interface methods
        String realmId = service.getRealmId();
        Boolean connected = service.testConnection();
        String customerId = service.findCustomerByName('Test Customer');
        
        Test.stopTest();
        
        // Verify interface works
        System.assertNotEquals(null, realmId, 'Realm ID should not be null');
        System.assertEquals(true, connected, 'Connection should be true for mock');
        System.assertNotEquals(null, customerId, 'Should find test customer');
    }
    
    // ========================================
    // BACKWARD COMPATIBILITY TESTS
    // ========================================
    
    @isTest
    static void testSyncCustomerResult() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QuickBooksMockService());
        
        QuickBooksService service = new QuickBooksService();
        QuickBooksModels.QBCustomer customer = new QuickBooksModels.QBCustomer();
        customer.Name = 'Test Customer';
        customer.CompanyName = 'Test Company';
        
        QuickBooksService.CustomerResult result = service.syncCustomerResult(customer);
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.success, 'Should be successful');
        System.assertNotEquals(null, result.customerId, 'Customer ID should be set');
    }
    
    @isTest
    static void testCreateCustomerResult() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QuickBooksMockService());
        
        QuickBooksService service = new QuickBooksService();
        QuickBooksService.CustomerResult result = service.createCustomerResult(
            'Test Customer', 
            '123 Main St', 
            '555-1234'
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.success, 'Should be successful');
        System.assertEquals('Customer created successfully', result.message, 'Should have success message');
    }
    
    @isTest
    static void testFindCustomerResult() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QuickBooksMockService());
        
        QuickBooksService service = new QuickBooksService();
        QuickBooksService.CustomerResult result = service.findCustomerResult('Test Customer');
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.success, 'Should find customer');
        System.assertNotEquals(null, result.customerId, 'Should return customer ID');
    }
    
    @isTest
    static void testBackwardCompatibilityErrors() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QuickBooksMockService(true, 'Test error'));
        
        QuickBooksService service = new QuickBooksService();
        QuickBooksModels.QBCustomer customer = new QuickBooksModels.QBCustomer();
        customer.Name = 'Test Customer';
        
        QuickBooksService.CustomerResult result = service.syncCustomerResult(customer);
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.success, 'Should indicate failure');
        System.assertNotEquals(null, result.errorCode, 'Should have error code');
    }
    
    @isTest
    static void testBillingEmailsVariable() {
        Test.startTest();
        
        String emails = QuickBooksService.testBillingEmails;
        
        Test.stopTest();
        
        System.assertNotEquals(null, emails, 'testBillingEmails should not be null');
        System.assert(emails.contains('@'), 'testBillingEmails should contain email addresses');
    }
    
    @isTest
    static void testCustomerResultConstructors() {
        Test.startTest();
        
        QuickBooksService.CustomerResult result1 = new QuickBooksService.CustomerResult('123', true, 'Success');
        QuickBooksService.CustomerResult result2 = new QuickBooksService.CustomerResult('456', false, 'Error', 'ERR001');
        
        Test.stopTest();
        
        System.assertEquals('123', result1.customerId, 'Customer ID should match');
        System.assertEquals(true, result1.success, 'Success flag should match');
        System.assertEquals('Success', result1.message, 'Message should match');
        
        System.assertEquals('456', result2.customerId, 'Customer ID should match');
        System.assertEquals(false, result2.success, 'Success flag should match');
        System.assertEquals('Error', result2.message, 'Message should match');
        System.assertEquals('ERR001', result2.errorCode, 'Error code should match');
    }
    
    @isTest
    static void testFindCustomerNotFound() {
        Test.startTest();
        
        QuickBooksMockService mockService = new QuickBooksMockService();
        mockService.customerNotFound = true;
        Test.setMock(HttpCalloutMock.class, mockService);
        
        QuickBooksService service = new QuickBooksService();
        QuickBooksService.CustomerResult result = service.findCustomerResult('Nonexistent Customer');
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.success, 'Should not find customer');
        System.assertEquals('NOT_FOUND', result.errorCode, 'Should have NOT_FOUND error code');
    }
    
    @isTest
    static void testCreateOrUpdateCustomer() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new QuickBooksMockService());
        
        Account testAccount = [SELECT Id, Name, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode FROM Account LIMIT 1];
        
        QuickBooksService.CustomerResult result = QuickBooksService.createOrUpdateCustomer(testAccount);
        
        Test.stopTest();
        
        // Verify account was processed successfully
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.success, 'Should be successful');
        System.assertNotEquals(null, result.customerId, 'Customer ID should be returned');
        
        Account updatedAccount = [SELECT QuickBooks_Customer_Id__c FROM Account WHERE Id = :testAccount.Id];
        System.assertNotEquals(null, updatedAccount, 'Account should still exist');
    }
    
    @isTest
    static void testCreateOrUpdateCustomerNull() {
        Test.startTest();
        
        QuickBooksService.CustomerResult result = QuickBooksService.createOrUpdateCustomer(null);
        
        Test.stopTest();
        
        // Should handle null account gracefully
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.success, 'Should indicate failure');
        System.assertEquals('NULL_ACCOUNT', result.errorCode, 'Should have NULL_ACCOUNT error code');
    }
}