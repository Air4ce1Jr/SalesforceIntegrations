/**
 * @description Apex class to integrate customer invoices from Revenova TMS managed package with QuickBooks
 * Refactored to use service pattern for better separation of concerns
 * @author Salesforce Administrator
 * @date 2024
 */
public class QuickBooksInvoiceIntegration {
    
    // Service instance - can be swapped for testing or different implementations
    private static IQuickBooksService qbService = new QuickBooksService();
    
    /**
     * @description Set a custom service implementation (mainly for testing)
     * @param service The service implementation to use
     */
    @TestVisible
    private static void setService(IQuickBooksService service) {
        qbService = service;
    }
    
    /**
     * @description Sync a single invoice to QuickBooks
     * @param invoiceId The Salesforce Invoice ID to sync
     * @return QuickBooks Invoice ID if successful, error message if failed
     */
    public static String syncInvoiceToQuickBooks(Id invoiceId) {
        try {
            // Query the invoice with related account
            SObject invoice = getInvoiceWithAccount(invoiceId);
            
            if (invoice == null) {
                return 'Error: Invoice not found with ID: ' + invoiceId;
            }
            
            // Get the related account
            Id accountId = (Id) invoice.get('Account__c');
            Account account = [SELECT Id, Name, Phone, BillingStreet, BillingCity, BillingState, 
                              BillingPostalCode, BillingCountry, QuickBooks_Customer_Id__c 
                              FROM Account WHERE Id = :accountId];
            
            // Ensure customer exists in QuickBooks
            String qbCustomerId = ensureCustomerExists(account);
            if (qbCustomerId.startsWith('Error:')) {
                return qbCustomerId;
            }
            
            // Convert Salesforce invoice to QuickBooks format
            QuickBooksModels.QBInvoice qbInvoice = QuickBooksModels.convertSalesforceInvoice(invoice, account, qbCustomerId);
            
            // Create invoice in QuickBooks
            String result = qbService.createInvoice(qbInvoice);
            
            // Update Salesforce invoice with QuickBooks ID if successful
            if (!result.startsWith('Error:')) {
                updateInvoiceWithQuickBooksId(invoiceId, result);
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error syncing invoice: ' + e.getMessage());
            return 'Error: Invoice sync failed - ' + e.getMessage();
        }
    }
    
    /**
     * @description Sync multiple invoices to QuickBooks in batch
     * @param invoiceIds List of Invoice IDs to sync
     * @return Map of Invoice ID to result (QuickBooks ID or error message)
     */
    public static Map<Id, String> batchSyncInvoicesToQuickBooks(List<Id> invoiceIds) {
        Map<Id, String> results = new Map<Id, String>();
        
        if (invoiceIds == null || invoiceIds.isEmpty()) {
            return results;
        }
        
        // Process each invoice (QuickBooks API doesn't support batch operations)
        for (Id invoiceId : invoiceIds) {
            String result = syncInvoiceToQuickBooks(invoiceId);
            results.put(invoiceId, result);
        }
        
        return results;
    }
    
    /**
     * @description Asynchronously sync invoices to QuickBooks
     * @param invoiceIds Set of Invoice IDs to sync
     */
    @future(callout=true)
    public static void syncInvoicesAsync(Set<Id> invoiceIds) {
        if (invoiceIds == null || invoiceIds.isEmpty()) {
            return;
        }
        
        List<Id> invoiceList = new List<Id>(invoiceIds);
        Map<Id, String> results = batchSyncInvoicesToQuickBooks(invoiceList);
        
        // Log results
        for (Id invoiceId : results.keySet()) {
            String result = results.get(invoiceId);
            if (result.startsWith('Error:')) {
                System.debug('Failed to sync invoice ' + invoiceId + ': ' + result);
            } else {
                System.debug('Successfully synced invoice ' + invoiceId + ' to QuickBooks ID: ' + result);
            }
        }
    }
    
    /**
     * @description Ensure a customer exists in QuickBooks, create if necessary
     * @param account The Salesforce Account to sync
     * @return QuickBooks Customer ID or error message
     */
    public static String ensureCustomerExists(Account account) {
        try {
            // Check if we already have a QuickBooks Customer ID
            if (String.isNotBlank(account.QuickBooks_Customer_Id__c)) {
                return account.QuickBooks_Customer_Id__c;
            }
            
            // Convert Account to QuickBooks Customer format
            QuickBooksModels.QBCustomer customer = QuickBooksModels.convertAccountToCustomer(account);
            
            // Sync customer to QuickBooks
            String qbCustomerId = qbService.syncCustomer(customer);
            
            // Update Salesforce Account with QuickBooks Customer ID if successful
            if (!qbCustomerId.startsWith('Error:')) {
                updateAccountWithQuickBooksId(account.Id, qbCustomerId);
            }
            
            return qbCustomerId;
            
        } catch (Exception e) {
            System.debug('Error ensuring customer exists: ' + e.getMessage());
            return 'Error: Failed to ensure customer exists - ' + e.getMessage();
        }
    }
    
    /**
     * @description Test the QuickBooks connection
     * @return True if connection is successful, false otherwise
     */
    public static Boolean testQuickBooksConnection() {
        return qbService.testConnection();
    }
    
    /**
     * @description Get the QuickBooks realm ID
     * @return The configured realm ID
     */
    public static String getRealmId() {
        return qbService.getRealmId();
    }
    
    /**
     * @description Get invoice with account relationship
     * @param invoiceId The invoice ID to query
     * @return SObject representing the invoice with account data
     */
    private static SObject getInvoiceWithAccount(Id invoiceId) {
        try {
            // Dynamically build query based on available fields
            String query = 'SELECT Id, Name, Account__c';
            
            // Add optional fields if they exist
            Set<String> fieldsToCheck = new Set<String>{
                'Total_Amount__c', 'Invoice_Date__c', 'Due_Date__c', 'Description__c',
                'Status__c', 'QuickBooks_Invoice_Id__c', 'QuickBooks_Sync_Status__c'
            };
            
            Schema.SObjectType invoiceType = Schema.getGlobalDescribe().get('Invoice__c');
            if (invoiceType != null) {
                Map<String, Schema.SObjectField> fieldMap = invoiceType.getDescribe().fields.getMap();
                
                for (String fieldName : fieldsToCheck) {
                    if (fieldMap.containsKey(fieldName)) {
                        query += ', ' + fieldName;
                    }
                }
            }
            
            query += ' FROM Invoice__c WHERE Id = :invoiceId LIMIT 1';
            
            List<SObject> invoices = Database.query(query);
            return invoices.isEmpty() ? null : invoices[0];
            
        } catch (Exception e) {
            System.debug('Error querying invoice: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Update Salesforce invoice with QuickBooks invoice ID
     * @param invoiceId The Salesforce invoice ID
     * @param qbInvoiceId The QuickBooks invoice ID
     */
    private static void updateInvoiceWithQuickBooksId(Id invoiceId, String qbInvoiceId) {
        try {
            // Check if QuickBooks fields exist
            Schema.SObjectType invoiceType = Schema.getGlobalDescribe().get('Invoice__c');
            if (invoiceType != null) {
                Map<String, Schema.SObjectField> fieldMap = invoiceType.getDescribe().fields.getMap();
                
                SObject invoice = invoiceType.newSObject(invoiceId);
                
                if (fieldMap.containsKey('QuickBooks_Invoice_Id__c')) {
                    invoice.put('QuickBooks_Invoice_Id__c', qbInvoiceId);
                }
                
                if (fieldMap.containsKey('QuickBooks_Sync_Status__c')) {
                    invoice.put('QuickBooks_Sync_Status__c', 'Synced');
                }
                
                if (fieldMap.containsKey('QuickBooks_Sync_Error__c')) {
                    invoice.put('QuickBooks_Sync_Error__c', null);
                }
                
                update invoice;
            }
            
        } catch (Exception e) {
            System.debug('Error updating invoice with QuickBooks ID: ' + e.getMessage());
        }
    }
    
    /**
     * @description Update Salesforce account with QuickBooks customer ID
     * @param accountId The Salesforce account ID
     * @param qbCustomerId The QuickBooks customer ID
     */
    private static void updateAccountWithQuickBooksId(Id accountId, String qbCustomerId) {
        try {
            // Check if QuickBooks Customer ID field exists
            Schema.SObjectField qbField = Schema.Account.SObjectType.getDescribe().fields.getMap().get('QuickBooks_Customer_Id__c');
            
            if (qbField != null) {
                Account account = new Account(Id = accountId);
                account.QuickBooks_Customer_Id__c = qbCustomerId;
                update account;
            }
            
        } catch (Exception e) {
            System.debug('Error updating account with QuickBooks ID: ' + e.getMessage());
        }
    }
    
    // Legacy wrapper classes maintained for backward compatibility
    // These delegate to QuickBooksModels for actual implementation
    
    public class QBInvoiceResponse {
        public QuickBooksModels.QBInvoice Invoice;
        public String responseTime;
        public String QueryResponse;
    }
    
    public class QBInvoice {
        public String Id;
        public String SyncToken;
        public String TxnDate;
        public Decimal TotalAmt;
        public QuickBooksModels.QBCustomerRef CustomerRef;
        public List<QuickBooksModels.QBLineItem> Line;
        public String DocNumber;
        public String DueDate;
        public String PrivateNote;
        public String CustomerMemo;
    }
    
    public class QBCustomerRef {
        public String value;
        public String name;
    }
    
    public class QBLineItem {
        public String Id;
        public Decimal Amount;
        public String Description;
        public String DetailType;
        public QuickBooksModels.QBSalesItemLineDetail SalesItemLineDetail;
    }
    
    public class QBSalesItemLineDetail {
        public QuickBooksModels.QBItemRef ItemRef;
        public Decimal Qty;
        public Decimal UnitPrice;
    }
    
    public class QBItemRef {
        public String value;
        public String name;
    }
}