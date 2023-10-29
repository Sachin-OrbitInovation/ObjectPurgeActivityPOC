/* 
Name : SobjectPurgeController
CreatedDate : 12-OCT-2023
CreatedBy Name : Sachin Gaikwad
Description : Handling the data communication between Apex and cmp_SobjectPurgeData LWC components. 
Date           Developer Name    Description
29-Oct-2023    Sachin Gaikwad    Adding comment for Git Push Demo Using UI.
29-Oct-2023    Sachin Gaikwad    Adding comment for Git Push Demo USing Command.
*/


public with sharing class SobjectPurgeController {

    //Fetch current record Data based on recordid from lwc and return data to lwc.
    @AuraEnabled
    public static sobjectPurgeWrapper fetchSObjectPurgeRecordDetail(Id recordId){
        sobjectPurgeWrapper sobjectPurgeWrap= new sobjectPurgeWrapper();
        Boolean isUpdate = false;
        SobjectPurgeConfiguration__c SobjPurgeConfig;
        SobjPurgeConfig = [Select id,Query__c,Name,Schedule_Job_Id__c,Parent_SobjectPurgeConfiguration__c from SobjectPurgeConfiguration__c where id =: recordId Limit 1];

        String JobName = SobjPurgeConfig.Name+'-'+SobjPurgeConfig.Id;
        List<CronTrigger> cronTrigRec =  [SELECT Id,CronJobDetail.Name,CronJobDetail.Id,State,NextFireTime,CreatedBy.Name,CronExpression 
         FROM CronTrigger where CronJobDetail.Name =: JobName Limit 1];
         if(cronTrigRec.size()> 0){
             System.debug('cronTrigRec-->'+cronTrigRec);
             
             for(CronTrigger cronTrig : cronTrigRec){
                sobjectPurgeWrap.sobjPurgeconfigRec = SobjPurgeConfig;
                sobjectPurgeWrap.scheduleJobName = cronTrig.CronJobDetail.Name;
                sobjectPurgeWrap.scheduleJobState = cronTrig.State;
                sobjectPurgeWrap.scheduleJobNextRun = String.valueOf(cronTrig.NextFireTime);
                sobjectPurgeWrap.scheduleCreatedBy = cronTrig.CreatedBy.Name;
                sobjectPurgeWrap.isParent = String.isBlank(SobjPurgeConfig.Parent_SobjectPurgeConfiguration__c) ? true : false;

                 if(string.isBlank(SobjPurgeConfig.Schedule_Job_Id__c) ||  SobjPurgeConfig.Schedule_Job_Id__c != cronTrig.Id){
                    SobjPurgeConfig.Schedule_Job_Id__c = cronTrig.Id;
                    isUpdate = true;
                }
            }
        }else{
         sobjectPurgeWrap.sobjPurgeconfigRec = SobjPurgeConfig;
         sobjectPurgeWrap.scheduleJobName = 'NA';
         sobjectPurgeWrap.scheduleJobState = 'NA';
         sobjectPurgeWrap.scheduleJobNextRun = 'NA';
         sobjectPurgeWrap.scheduleCreatedBy = 'NA';
         sobjectPurgeWrap.isParent = String.isBlank(SobjPurgeConfig.Parent_SobjectPurgeConfiguration__c) ? true : false;
         if(string.isNotBlank(SobjPurgeConfig.Schedule_Job_Id__c)){
            SobjPurgeConfig.Schedule_Job_Id__c = '';
            isUpdate = true;
         }
         }

         if(isUpdate){
            update SobjPurgeConfig;
         }

        return sobjectPurgeWrap;
        
    }

    //schedule Job once click on schdeule Button
    @AuraEnabled
    public static scheduledJobWrapper scheduleApexJob(Id recordId){
        scheduledJobWrapper scheduledJobWrap = new scheduledJobWrapper();
        SobjectPurgeConfiguration__c SobjPurgeConfigRec;
        List<SobjectPurgeConfiguration__c> SobjPurgeConfigLst;
        Boolean isError = false;
        SobjPurgeConfigLst = [Select id,Query__c,Name,Batch_Size__c,Child_Relationship_Names__c,Limit_Query_Rows__c,Schedule_Time__c,SObject_API_Name__c,Parent_SobjectPurgeConfiguration__c from SobjectPurgeConfiguration__c where id =: recordId or Parent_SobjectPurgeConfiguration__c =: recordId];
        for(SobjectPurgeConfiguration__c SobjPurgeConfig: SobjPurgeConfigLst){
            if(String.isBlank(SobjPurgeConfig.Parent_SobjectPurgeConfiguration__c)){
                SobjPurgeConfigRec = SobjPurgeConfig;
            }
        if(String.isNotBlank( SobjPurgeConfig.Query__c) && SobjPurgeConfig.Query__c.endsWithIgnoreCase('limit')){
            scheduledJobWrap.status = 'ERROR';
            scheduledJobWrap.message =  'Please check Query is correct or Not. Might its end with LIMIT keyword Record Name : '+SobjPurgeConfig.Name;
            isError = true;
        }else if(String.isNotBlank(SobjPurgeConfig.Query__c)){
            List<SObject> reclist = new List<SObject>();
            String query = SobjPurgeConfig.Query__c + 'Limit 1';
            try{
                reclist =  database.query(SobjPurgeConfig.Query__c);
            }catch(Exception e){
                scheduledJobWrap.status = 'ERROR';
                scheduledJobWrap.message =  e.getMessage()+ ' Record Name : '+SobjPurgeConfig.Name;
                isError = true;
            }
        }
        if(isError){
            break;
        }
    }

        if(!isError){
        SobjectPurgeScheduler sobjPurgeSch = new SobjectPurgeScheduler();
        system.schedule(SobjPurgeConfigRec.Name+'-'+SobjPurgeConfigRec.id,SobjPurgeConfigRec.Schedule_Time__c, sobjPurgeSch);
        scheduledJobWrap.status = 'SUCCESS';
        scheduledJobWrap.message =  'Job Scheduled Successfully...';
        }

        return scheduledJobWrap;
    }

    //unschdeule Schedule Job once click on unSchedule.
    @AuraEnabled
    public static string unScheduleApexJob(Id scheduleJobId){
        if(String.isNotBlank( scheduleJobId)){
            System.abortJob(scheduleJobId);
        }
        return 'Job unscheduled successfully...';
    }

    public class sobjectPurgeWrapper{
        @AuraEnabled public string scheduleJobName;
        @AuraEnabled public string scheduleJobState;
        @AuraEnabled public string scheduleJobNextRun;
        @AuraEnabled public string scheduleCreatedBy;
        @AuraEnabled public SobjectPurgeConfiguration__c sobjPurgeconfigRec;
        @AuraEnabled public Boolean isParent;
    }

    public class scheduledJobWrapper{
        @AuraEnabled public string status;
        @AuraEnabled public string message;
    }

}