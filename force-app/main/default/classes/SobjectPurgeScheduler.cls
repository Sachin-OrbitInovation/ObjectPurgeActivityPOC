/* 
Name : SobjectPurgeScheduler
CreatedDate : 13-OCT-2023
CreatedBy Name : Sachin Gaikwad
Description : Schedule a SobjectPurgeConfiguration__c record based on data from controller
*/

global with sharing class SobjectPurgeScheduler implements Schedulable{
    
    global void execute(SchedulableContext sc){
        string query;
        SobjectPurgeConfiguration__c SobjPurgeConfig;
        SobjPurgeConfig = [Select id,Query__c,Name,Batch_Size__c,Child_Relationship_Names__c,Limit_Query_Rows__c,Schedule_Time__c,SObject_API_Name__c from SobjectPurgeConfiguration__c where Schedule_Job_Id__c =:  sc.getTriggerId() Limit 1];
        if(string.isNotBlank(SobjPurgeConfig.Query__c)){
            query = SobjPurgeConfig.Query__c;
        }
        if(SobjPurgeConfig.Limit_Query_Rows__c != null && SobjPurgeConfig.Limit_Query_Rows__c >0){
            query = query + ' LIMIT '+SobjPurgeConfig.Limit_Query_Rows__c;
        }
        System.debug('query->'+query);

        SobjectPurgeBatchProcessor deleteSobjRecord = new SobjectPurgeBatchProcessor(query,SobjPurgeConfig.id,SobjPurgeConfig.Name,SobjPurgeConfig.Child_Relationship_Names__c);
        		Id batchProcessId = Database.executeBatch(deleteSobjRecord,SobjPurgeConfig.Batch_Size__c.intValue());
                System.debug('batchProcessId-->'+batchProcessId);
    }
}