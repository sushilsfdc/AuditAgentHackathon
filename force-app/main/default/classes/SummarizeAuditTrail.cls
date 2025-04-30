global class SummarizeAuditTrail {
  
    @InvocableMethod(label='Get setup audit trail' description='Retrieve setu p audit trail data for a specific user and date.')
     global static List<Response> getAuditTrailData(List<Request> requests) {
          Request input = requests[0];
           Date activityDate = Date.parse(input.Activity_Date);
           List<SetupAuditTrail> lstSetupAuditTrail = [select Action, Section, Display from SetupAuditTrail 
                                    where createdbyid = :input.User_Id
                                    and DAY_ONLY(createddate) = :activityDate];
         List<Response> responses = new List<Response>();
         Response output = new Response();
         responses.add(output);
         output.prompt = Json.serialize(lstSetupAuditTrail);
         return responses;
       
   }
     
 // Type and API Name of all variables must match the template
     global class Request {
         @InvocableVariable(required=true)
         public String User_Id;
         @InvocableVariable(required=true)
         public String Activity_Date;
     }
 
     global class Response {
         @InvocableVariable
         public String Prompt;
     }    
 }