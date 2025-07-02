/**
 * @description Apex class to integrate customer invoices from Revenova TMS managed package with QuickBooks
 * @author Salesforce Administrator
 * @date 2024
 */
public class QuickBooksInvoiceIntegration {
    
    private static final String QB_BASE_URL = 'callout:QuickBooks_NC/v3/company/';
    private static final String INVOICE_ENDPOINT = '/invoice';
    private static final String CUSTOMER_ENDPOINT = '/customer';
    
    /**
     * @description Wrapper class for QuickBooks invoice response
     */
    public class QBInvoiceResponse {
        public QBInvoice Invoice;
        public String time;
        public String QueryResponse;
    }
    
    /**
     * @description Wrapper class for QuickBooks invoice
     */
    public class QBInvoice {
        public String Id;
        public String SyncToken;
        public String TxnDate;
        public QBCustomerRef CustomerRef;
        public List<QBLineItem> Line;
        public Decimal TotalAmt;
        public Decimal Balance;
    }
    
    /**
     * @description Wrapper class for QuickBooks customer reference
     */
    public class QBCustomerRef {
        public String value;
        public String name;
    }
    
    /**
     * @description Wrapper class for QuickBooks line item
     */
    public class QBLineItem {
        public String Id;
        public String Description;
        public Decimal Amount;
        public String DetailType;
        public QBSalesItemLineDetail SalesItemLineDetail;
    }
    
    /**
     * @description Wrapper class for QuickBooks sales item line detail
     */
    public class QBSalesItemLineDetail {
        public QBItemRef ItemRef;
        public Decimal Qty;
        public Decimal UnitPrice;
    }
    
    /**
     * @description Wrapper class for QuickBooks item reference
     */
    public class QBItemRef {
        public String value;
        public String name;
    }
    
    /**
     * @description Synchronize a single invoice to QuickBooks
     * @param invoiceId The Salesforce Invoice ID to synchronize
     * @return String The QuickBooks Invoice ID if successful, error message if failed
     */
    public static String syncInvoiceToQuickBooks(Id invoiceId) {
        try {
            // Get the invoice data from Salesforce
            // Note: This assumes standard or custom Invoice object exists in Revenova TMS
            List<SObject> invoices = Database.query(
                'SELECT Id, Name, Account__c, Account__r.Name, Account__r.QuickBooks_Customer_Id__c, ' +
                'Total_Amount__c, Invoice_Date__c, Status__c ' +
                'FROM Invoice__c WHERE Id = :invoiceId LIMIT 1'
            );
            
            if (invoices.isEmpty()) {
                return 'Error: Invoice not found with ID: ' + invoiceId;
            }
            
            SObject invoice = invoices[0];
            
            // Check if customer exists in QuickBooks, create if not
            String qbCustomerId = ensureCustomerExists(invoice);
            if (qbCustomerId.startsWith('Error:')) {
                return qbCustomerId;
            }
            
            // Create QuickBooks invoice payload
            QBInvoice qbInvoice = buildQuickBooksInvoice(invoice, qbCustomerId);
            
            // Send to QuickBooks
            String result = sendInvoiceToQuickBooks(qbInvoice);
            
            if (!result.startsWith('Error:')) {
                // Update Salesforce record with QuickBooks ID
                updateSalesforceInvoice(invoiceId, result);
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error in syncInvoiceToQuickBooks: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }
    
    /**
     * @description Batch synchronize multiple invoices to QuickBooks
     * @param invoiceIds List of Salesforce Invoice IDs to synchronize
     * @return Map<Id, String> Map of Invoice ID to result (QB ID or error message)
     */
    public static Map<Id, String> batchSyncInvoicesToQuickBooks(List<Id> invoiceIds) {
        Map<Id, String> results = new Map<Id, String>();
        
        for (Id invoiceId : invoiceIds) {
            String result = syncInvoiceToQuickBooks(invoiceId);
            results.put(invoiceId, result);
        }
        
        return results;
    }
    
    /**
     * @description Ensure customer exists in QuickBooks, create if necessary
     * @param invoice The Salesforce invoice record
     * @return String The QuickBooks Customer ID or error message
     */
    private static String ensureCustomerExists(SObject invoice) {
        try {
            // Check if QB Customer ID is already stored in Salesforce
            String existingQBId = (String) invoice.getSObject('Account__r')?.get('QuickBooks_Customer_Id__c');
            if (String.isNotBlank(existingQBId)) {
                return existingQBId;
            }
            
            // Create customer in QuickBooks
            String customerName = (String) invoice.getSObject('Account__r')?.get('Name');
            String realmId = getRealmId();
            
            Map<String, Object> customerData = new Map<String, Object>{
                'DisplayName' => customerName,
                'Name' => customerName
            };
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(QB_BASE_URL + realmId + CUSTOMER_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setBody(JSON.serialize(customerData));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> queryResponse = (Map<String, Object>) responseData.get('QueryResponse');
                List<Object> customers = (List<Object>) queryResponse.get('Customer');
                
                if (customers != null && !customers.isEmpty()) {
                    Map<String, Object> customer = (Map<String, Object>) customers[0];
                    String qbCustomerId = (String) customer.get('Id');
                    
                    // Update Account with QB Customer ID
                    Id accountId = (Id) invoice.get('Account__c');
                    SObject account = accountId.getSObjectType().newSObject(accountId);
                    account.put('QuickBooks_Customer_Id__c', qbCustomerId);
                    update account;
                    
                    return qbCustomerId;
                }
            }
            
            return 'Error: Failed to create customer in QuickBooks. Status: ' + res.getStatusCode();
            
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    
    /**
     * @description Build QuickBooks invoice from Salesforce data
     * @param invoice The Salesforce invoice record
     * @param qbCustomerId The QuickBooks customer ID
     * @return QBInvoice The QuickBooks invoice object
     */
    private static QBInvoice buildQuickBooksInvoice(SObject invoice, String qbCustomerId) {
        QBInvoice qbInvoice = new QBInvoice();
        
        // Set basic invoice properties
        Date invoiceDate = (Date) invoice.get('Invoice_Date__c');
        qbInvoice.TxnDate = invoiceDate != null ? invoiceDate.format() : Date.today().format();
        
        // Set customer reference
        qbInvoice.CustomerRef = new QBCustomerRef();
        qbInvoice.CustomerRef.value = qbCustomerId;
        qbInvoice.CustomerRef.name = (String) invoice.getSObject('Account__r')?.get('Name');
        
        // Set total amount
        qbInvoice.TotalAmt = (Decimal) invoice.get('Total_Amount__c');
        qbInvoice.Balance = qbInvoice.TotalAmt;
        
        // Create line items
        qbInvoice.Line = new List<QBLineItem>();
        
        // For simplicity, create a single line item with the total amount
        // In a real implementation, you'd query related line items
        QBLineItem lineItem = new QBLineItem();
        lineItem.Description = 'Invoice: ' + (String) invoice.get('Name');
        lineItem.Amount = qbInvoice.TotalAmt;
        lineItem.DetailType = 'SalesItemLineDetail';
        
        // Set sales item line detail
        lineItem.SalesItemLineDetail = new QBSalesItemLineDetail();
        lineItem.SalesItemLineDetail.ItemRef = new QBItemRef();
        lineItem.SalesItemLineDetail.ItemRef.value = '1'; // Default item ID
        lineItem.SalesItemLineDetail.ItemRef.name = 'Services';
        lineItem.SalesItemLineDetail.Qty = 1;
        lineItem.SalesItemLineDetail.UnitPrice = qbInvoice.TotalAmt;
        
        qbInvoice.Line.add(lineItem);
        
        return qbInvoice;
    }
    
    /**
     * @description Send invoice to QuickBooks
     * @param qbInvoice The QuickBooks invoice object
     * @return String The QuickBooks Invoice ID or error message
     */
    private static String sendInvoiceToQuickBooks(QBInvoice qbInvoice) {
        try {
            String realmId = getRealmId();
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(QB_BASE_URL + realmId + INVOICE_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setBody(JSON.serialize(qbInvoice));
            req.setTimeout(120000); // 2 minutes timeout
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('QuickBooks Response: ' + res.getBody());
            
            if (res.getStatusCode() == 200) {
                QBInvoiceResponse responseObj = (QBInvoiceResponse) JSON.deserialize(
                    res.getBody(), QBInvoiceResponse.class
                );
                
                if (responseObj.Invoice != null) {
                    return responseObj.Invoice.Id;
                }
            }
            
            return 'Error: Failed to create invoice in QuickBooks. Status: ' + res.getStatusCode() + ', Body: ' + res.getBody();
            
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    
    /**
     * @description Update Salesforce invoice with QuickBooks ID
     * @param invoiceId The Salesforce invoice ID
     * @param qbInvoiceId The QuickBooks invoice ID
     */
    private static void updateSalesforceInvoice(Id invoiceId, String qbInvoiceId) {
        try {
            SObject invoice = invoiceId.getSObjectType().newSObject(invoiceId);
            invoice.put('QuickBooks_Invoice_Id__c', qbInvoiceId);
            invoice.put('QuickBooks_Sync_Status__c', 'Synced');
            invoice.put('QuickBooks_Sync_Date__c', DateTime.now());
            update invoice;
        } catch (Exception e) {
            System.debug('Error updating Salesforce invoice: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get the QuickBooks Realm ID from custom settings or metadata
     * @return String The realm ID
     */
    private static String getRealmId() {
        // This should be stored in custom metadata or custom settings
        // For this example, using a default value
        return '9341454816381446';
    }
    
    /**
     * @description Future method for asynchronous invoice synchronization
     * @param invoiceIds Set of invoice IDs to synchronize
     */
    @future(callout=true)
    public static void syncInvoicesAsync(Set<Id> invoiceIds) {
        List<Id> invoiceList = new List<Id>(invoiceIds);
        Map<Id, String> results = batchSyncInvoicesToQuickBooks(invoiceList);
        
        // Log results
        for (Id invoiceId : results.keySet()) {
            String result = results.get(invoiceId);
            System.debug('Invoice ' + invoiceId + ' sync result: ' + result);
        }
    }
}