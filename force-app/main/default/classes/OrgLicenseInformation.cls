public with sharing class OrgLicenseInformation {

    /**
     * Invocable method to retrieve a list of users who have a specific permission.
     * This method can be invoked from Agentforce Agent actions.
     */
    @InvocableMethod(label='Get Org Licenses' description='Retrieve org license usage information')
    public static List<Response> getUsersWithPermission(List<Request> licenseTypes) {
        // Ensure a permission name is provided
        if (licenseTypes == null || licenseTypes.isEmpty()) {
            return new List<Response>();
        }

        // Query to fetch users with the specified permission
        List<UserLicense> licenseList = Database.query(
            'SELECT Name,  TotalLicenses, UsedLicenses ' +
            'FROM UserLicense ' 
        );

        List<Response> responses = new List<Response>();
        Response output = new Response();
        responses.add(output);
   
        output.Prompt = JSON.serialize(licenseList);
        return responses;
    }

    public class Request {
        @InvocableVariable(label='License Type' description='The Type of the License to check for.')
        public String License_Type;
    }
    public class Response {
        @InvocableVariable
        public String Prompt;
    }
    

}