/* 
Name : SobjectPurgeBatchProcessor
CreatedDate : 13-OCT-2023
CreatedBy Name : Sachin Gaikwad
Description : Batch class to purge data based on scheduler data.
*/

global with sharing class SobjectPurgeBatchProcessor implements Database.Batchable<Sobject>, Database.stateful {

    public String query,schId, batchName,childObjectNames;

    global SobjectPurgeBatchProcessor(String q,String schId1,String BatchName1,String childObjectName){
        query = q;
        schId = schId1;
        batchName = BatchName1;
        childObjectNames = childObjectName;
        System.debug('query in com-->'+query);
        System.debug('schId in con-->'+schId);
        System.debug('batchName in con-->'+batchName);
        System.debug('childObjectNames in con-->'+childObjectNames);
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('query -->'+query);
        System.debug('schId in start-->'+schId);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Sobject> scope){
        System.debug('schId-->'+schId);
        System.debug('scope-->'+scope);
        Set<Id> setRecordIds = new Set<Id>();
        for(SObject ids:scope){
            setRecordIds.add(ids.id);
        }
        List<SobjectPurgeConfiguration__c> sobjLst = new List<SobjectPurgeConfiguration__c>();
        List<Sobject> sobjList = new List<Sobject>();
        Map<Integer,List<Sobject>> sobjMap = new Map<Integer,List<Sobject>>();

        sobjLst  = [Select id,Query__c,Name,Batch_Size__c,Limit_Query_Rows__c,Schedule_Time__c,SObject_API_Name__c from SobjectPurgeConfiguration__c where Parent_SobjectPurgeConfiguration__r.Id =:  schId];
        integer i = 0;
        //Need to add limit for child query if Limit_Query_Rows__c available.
        for(SobjectPurgeConfiguration__c sobj: sobjLst){
            String query = sobj.Query__c+' where '+sobj.SObject_API_Name__c+ ' IN: setRecordIds';
            if(sobj.Limit_Query_Rows__c != null && sobj.Limit_Query_Rows__c >0){
                query = query + ' LIMIT '+sobj.Limit_Query_Rows__c;
            }
            System.debug('query for child'+query);
            sobjList = database.query(query);
            sobjMap.put(i,sobjList);
            i++;
        }
        for(Integer key:sobjMap.keyset()){
            system.debug('sobjectdata-->'+sobjMap.get(key));
            //Database.delete(sobjMap.get(key),false);
        }
       // Database.delete(scope,false);
    }

    global void finish(Database.BatchableContext BC){
    }
}