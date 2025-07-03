/**
 * @description QuickBooks API service implementation
 * @author Salesforce Administrator
 * @date 2024
 */
public class QuickBooksService implements IQuickBooksService {
    
    private static final String QB_BASE_URL = 'callout:QuickBooks_NC/v3/company/';
    private static final String INVOICE_ENDPOINT = '/invoice';
    private static final String CUSTOMER_ENDPOINT = '/customer';
    private static final String QUERY_ENDPOINT = '/query';
    private static final String REALM_ID = '9341454816381446';
    
    // Backward compatibility - missing variable expected by existing production code
    public static String testBillingEmails = 'test@example.com,admin@example.com';
    
    /**
     * @description Backward compatibility - Customer result wrapper class expected by existing code
     */
    public class CustomerResult {
        public String customerId;
        public String id; // Backward compatibility - existing code expects 'id' property
        public String syncToken; // Backward compatibility - existing code expects 'syncToken' property
        public Boolean success;
        public String message;
        public String errorCode;
        public Map<String, Object> additionalData;
        
        public CustomerResult(String customerId, Boolean success, String message) {
            this.customerId = customerId;
            this.id = customerId; // Set both for backward compatibility
            this.syncToken = '0'; // Default sync token for backward compatibility
            this.success = success;
            this.message = message;
            this.additionalData = new Map<String, Object>();
        }
        
        public CustomerResult(String customerId, Boolean success, String message, String errorCode) {
            this(customerId, success, message);
            this.errorCode = errorCode;
        }
    }
    
    /**
     * @description Create or update a customer in QuickBooks
     * @param customer The customer data to sync
     * @return QuickBooks Customer ID or error message
     */
    public String syncCustomer(QuickBooksModels.QBCustomer customer) {
        try {
            // First, check if customer already exists
            String existingCustomerId = findCustomerByName(customer.Name);
            
            if (String.isNotBlank(existingCustomerId)) {
                // Update existing customer
                customer.Id = existingCustomerId;
                return updateCustomer(customer);
            } else {
                // Create new customer
                return createCustomer(customer);
            }
            
        } catch (Exception e) {
            System.debug('Error syncing customer: ' + e.getMessage());
            return 'Error: Failed to sync customer - ' + e.getMessage();
        }
    }
    
    /**
     * @description Find an existing customer in QuickBooks by name
     * @param customerName The customer name to search for
     * @return QuickBooks Customer ID if found, null otherwise
     */
    public String findCustomerByName(String customerName) {
        try {
            String query = 'SELECT * FROM Customer WHERE Name = \'' + customerName.replace('\'', '\\\'') + '\'';
            String endpoint = QB_BASE_URL + REALM_ID + QUERY_ENDPOINT + '?query=' + EncodingUtil.urlEncode(query, 'UTF-8');
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Accept', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> queryResponse = (Map<String, Object>) responseMap.get('QueryResponse');
                
                if (queryResponse != null && queryResponse.containsKey('Customer')) {
                    List<Object> customers = (List<Object>) queryResponse.get('Customer');
                    if (!customers.isEmpty()) {
                        Map<String, Object> customer = (Map<String, Object>) customers[0];
                        return String.valueOf(customer.get('Id'));
                    }
                }
            }
            
            return null;
            
        } catch (Exception e) {
            System.debug('Error finding customer: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Create a new customer in QuickBooks
     * @param customer The customer data to create
     * @return QuickBooks Customer ID or error message
     */
    private String createCustomer(QuickBooksModels.QBCustomer customer) {
        try {
            String endpoint = QB_BASE_URL + REALM_ID + CUSTOMER_ENDPOINT;
            String requestBody = JSON.serialize(customer);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setBody(requestBody);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                QuickBooksModels.QBCustomerResponse response = 
                    (QuickBooksModels.QBCustomerResponse) JSON.deserialize(res.getBody(), QuickBooksModels.QBCustomerResponse.class);
                
                if (response.Customer != null && !response.Customer.isEmpty()) {
                    return response.Customer[0].Id;
                }
            }
            
            return 'Error: Customer creation failed - HTTP ' + res.getStatusCode() + ': ' + res.getBody();
            
        } catch (Exception e) {
            System.debug('Error creating customer: ' + e.getMessage());
            return 'Error: Failed to create customer - ' + e.getMessage();
        }
    }
    
    /**
     * @description Update an existing customer in QuickBooks
     * @param customer The customer data to update
     * @return QuickBooks Customer ID or error message
     */
    private String updateCustomer(QuickBooksModels.QBCustomer customer) {
        try {
            // For updates, we need to get the current SyncToken first
            String endpoint = QB_BASE_URL + REALM_ID + CUSTOMER_ENDPOINT + '/' + customer.Id;
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Accept', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                QuickBooksModels.QBCustomerResponse getResponse = 
                    (QuickBooksModels.QBCustomerResponse) JSON.deserialize(res.getBody(), QuickBooksModels.QBCustomerResponse.class);
                
                if (getResponse.Customer != null && !getResponse.Customer.isEmpty()) {
                    customer.SyncToken = getResponse.Customer[0].SyncToken;
                    
                    // Now perform the update
                    String requestBody = JSON.serialize(customer);
                    
                    HttpRequest updateReq = new HttpRequest();
                    updateReq.setEndpoint(endpoint);
                    updateReq.setMethod('POST');
                    updateReq.setHeader('Content-Type', 'application/json');
                    updateReq.setHeader('Accept', 'application/json');
                    updateReq.setBody(requestBody);
                    
                    HttpResponse updateRes = http.send(updateReq);
                    
                    if (updateRes.getStatusCode() == 200) {
                        return customer.Id;
                    } else {
                        return 'Error: Customer update failed - HTTP ' + updateRes.getStatusCode() + ': ' + updateRes.getBody();
                    }
                }
            }
            
            return 'Error: Failed to get customer for update - HTTP ' + res.getStatusCode();
            
        } catch (Exception e) {
            System.debug('Error updating customer: ' + e.getMessage());
            return 'Error: Failed to update customer - ' + e.getMessage();
        }
    }
    
    /**
     * @description Create an invoice in QuickBooks
     * @param invoice The invoice data to create
     * @return QuickBooks Invoice ID or error message
     */
    public String createInvoice(QuickBooksModels.QBInvoice invoice) {
        try {
            String endpoint = QB_BASE_URL + REALM_ID + INVOICE_ENDPOINT;
            String requestBody = JSON.serialize(invoice);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setBody(requestBody);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                QuickBooksModels.QBInvoiceResponse response = 
                    (QuickBooksModels.QBInvoiceResponse) JSON.deserialize(res.getBody(), QuickBooksModels.QBInvoiceResponse.class);
                
                if (response.Invoice != null) {
                    return response.Invoice.Id;
                }
            }
            
            return 'Error: Invoice creation failed - HTTP ' + res.getStatusCode() + ': ' + res.getBody();
            
        } catch (Exception e) {
            System.debug('Error creating invoice: ' + e.getMessage());
            return 'Error: Failed to create invoice - ' + e.getMessage();
        }
    }
    
    /**
     * @description Update an existing invoice in QuickBooks
     * @param invoice The invoice data to update
     * @return QuickBooks Invoice ID or error message
     */
    public String updateInvoice(QuickBooksModels.QBInvoice invoice) {
        try {
            // Get current invoice to retrieve SyncToken
            String endpoint = QB_BASE_URL + REALM_ID + INVOICE_ENDPOINT + '/' + invoice.Id;
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Accept', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                QuickBooksModels.QBInvoiceResponse getResponse = 
                    (QuickBooksModels.QBInvoiceResponse) JSON.deserialize(res.getBody(), QuickBooksModels.QBInvoiceResponse.class);
                
                if (getResponse.Invoice != null) {
                    invoice.SyncToken = getResponse.Invoice.SyncToken;
                    
                    // Perform the update
                    String requestBody = JSON.serialize(invoice);
                    
                    HttpRequest updateReq = new HttpRequest();
                    updateReq.setEndpoint(endpoint);
                    updateReq.setMethod('POST');
                    updateReq.setHeader('Content-Type', 'application/json');
                    updateReq.setHeader('Accept', 'application/json');
                    updateReq.setBody(requestBody);
                    
                    HttpResponse updateRes = http.send(updateReq);
                    
                    if (updateRes.getStatusCode() == 200) {
                        return invoice.Id;
                    } else {
                        return 'Error: Invoice update failed - HTTP ' + updateRes.getStatusCode() + ': ' + updateRes.getBody();
                    }
                }
            }
            
            return 'Error: Failed to get invoice for update - HTTP ' + res.getStatusCode();
            
        } catch (Exception e) {
            System.debug('Error updating invoice: ' + e.getMessage());
            return 'Error: Failed to update invoice - ' + e.getMessage();
        }
    }
    
    /**
     * @description Delete an invoice in QuickBooks
     * @param invoiceId The QuickBooks Invoice ID to delete
     * @return Success message or error message
     */
    public String deleteInvoice(String invoiceId) {
        try {
            // QuickBooks doesn't support deleting invoices directly
            // Instead, we can void them or mark them as inactive
            return 'Error: Invoice deletion not supported by QuickBooks API. Use void operation instead.';
            
        } catch (Exception e) {
            System.debug('Error deleting invoice: ' + e.getMessage());
            return 'Error: Failed to delete invoice - ' + e.getMessage();
        }
    }
    
    /**
     * @description Get the QuickBooks company realm ID
     * @return The realm ID for API calls
     */
    public String getRealmId() {
        return REALM_ID;
    }
    
    /**
     * @description Test the connection to QuickBooks API
     * @return True if connection is successful, false otherwise
     */
    public Boolean testConnection() {
        try {
            String endpoint = QB_BASE_URL + REALM_ID + '/companyinfo/1';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Accept', 'application/json');
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            return res.getStatusCode() == 200;
            
        } catch (Exception e) {
            System.debug('Connection test failed: ' + e.getMessage());
            return false;
        }
    }
    
    // ========================================
    // BACKWARD COMPATIBILITY METHODS
    // ========================================
    // These methods provide compatibility with existing production code
    // that expects CustomerResult return types
    
    /**
     * @description Backward compatible customer sync method
     * @param customer The customer data to sync
     * @return CustomerResult object for backward compatibility
     */
    public CustomerResult syncCustomerResult(QuickBooksModels.QBCustomer customer) {
        String result = syncCustomer(customer);
        
        if (result.startsWith('Error:')) {
            return new CustomerResult(null, false, result, 'SYNC_ERROR');
        } else {
            return new CustomerResult(result, true, 'Customer synced successfully');
        }
    }
    
    /**
     * @description Backward compatible customer creation method
     * @param customerName Customer name
     * @param billingAddress Billing address
     * @param phone Phone number
     * @return CustomerResult object for backward compatibility
     */
    public CustomerResult createCustomerResult(String customerName, String billingAddress, String phone) {
        try {
            QuickBooksModels.QBCustomer customer = new QuickBooksModels.QBCustomer();
            customer.Name = customerName;
            customer.DisplayName = customerName;
            customer.CompanyName = customerName;
            customer.PrimaryPhone = phone;
            customer.Active = true;
            
            if (String.isNotBlank(billingAddress)) {
                customer.BillAddr = new QuickBooksModels.QBAddress();
                customer.BillAddr.Line1 = billingAddress;
            }
            
            String result = syncCustomer(customer);
            
            if (result.startsWith('Error:')) {
                return new CustomerResult(null, false, result, 'CREATE_ERROR');
            } else {
                return new CustomerResult(result, true, 'Customer created successfully');
            }
        } catch (Exception e) {
            return new CustomerResult(null, false, 'Exception: ' + e.getMessage(), 'EXCEPTION');
        }
    }
    
    /**
     * @description Backward compatible find customer method
     * @param customerName The customer name to search for
     * @return CustomerResult object for backward compatibility
     */
    public CustomerResult findCustomerResult(String customerName) {
        try {
            String customerId = findCustomerByName(customerName);
            
            if (String.isNotBlank(customerId)) {
                return new CustomerResult(customerId, true, 'Customer found');
            } else {
                return new CustomerResult(null, false, 'Customer not found', 'NOT_FOUND');
            }
        } catch (Exception e) {
            return new CustomerResult(null, false, 'Exception: ' + e.getMessage(), 'EXCEPTION');
        }
    }
    
    /**
     * @description Backward compatible method expected by existing production code
     * @param account The Salesforce Account to create/update in QuickBooks
     * @return CustomerResult object with sync results
     */
    public static CustomerResult createOrUpdateCustomer(Account account) {
        try {
            if (account == null) {
                System.debug('Account is null, cannot create/update customer');
                return new CustomerResult(null, false, 'Account is null', 'NULL_ACCOUNT');
            }
            
            // Create service instance to call instance methods
            QuickBooksService service = new QuickBooksService();
            QuickBooksModels.QBCustomer customer = QuickBooksModels.convertAccountToCustomer(account);
            String result = service.syncCustomer(customer);
            
            if (!result.startsWith('Error:')) {
                // Update the account with the QuickBooks Customer ID if successful
                if (String.isBlank(account.QuickBooks_Customer_Id__c)) {
                    account.QuickBooks_Customer_Id__c = result;
                    
                    try {
                        update account;
                    } catch (DmlException e) {
                        System.debug('Could not update account with QuickBooks Customer ID: ' + e.getMessage());
                    }
                }
                return new CustomerResult(result, true, 'Customer synced successfully');
            } else {
                System.debug('Error creating/updating customer in QuickBooks: ' + result);
                return new CustomerResult(null, false, result, 'SYNC_ERROR');
            }
        } catch (Exception e) {
            System.debug('Exception in createOrUpdateCustomer: ' + e.getMessage());
            return new CustomerResult(null, false, 'Exception: ' + e.getMessage(), 'EXCEPTION');
        }
    }
}