import { LightningElement,api,track } from 'lwc';
import fetchSObjectPurgeRecord from '@salesforce/apex/SobjectPurgeController.fetchSObjectPurgeRecordDetail';
import scheduleApexJob from '@salesforce/apex/SobjectPurgeController.scheduleApexJob';
import unScheduleApexJob from '@salesforce/apex/SobjectPurgeController.unScheduleApexJob';
import { RefreshEvent } from 'lightning/refresh';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Cmp_sobjectPurgeData extends LightningElement {
    @api recordId
    @track isLoading = false;
    @track schedulerName;
    @track scheduleState;
    @track scheduleNextTime;
    @track scheduleCreatedBy;
    @track disabledRunBtn;
    @track disabledStopBtn;
    @track scheduleJobId;
    @track isParent;
    connectedCallback(){
        console.log('recordId-->'+this.recordId);
        this.fetchRecord();
    }

    fetchRecord(){
        this.isLoading = true;
    fetchSObjectPurgeRecord({ recordId: this.recordId })
		.then(result => {
			 console.log('result-->'+JSON.stringify(result));
             this.schedulerName = result.scheduleJobName;
             this.scheduleState = result.scheduleJobState;
             this.scheduleNextTime = result.scheduleJobNextRun;
             this.scheduleCreatedBy = result.scheduleCreatedBy;
             this.scheduleJobId = result.sobjPurgeconfigRec.Schedule_Job_Id__c;
             this.isParent = result.isParent;
             if(this.schedulerName != 'NA'){
                this.disabledRunBtn = true;
                this.disabledStopBtn = false;
             }else{
                this.disabledRunBtn = false;
                this.disabledStopBtn = true;
             }
			  this.isLoading = false;
		})
		.catch(error => {
			console.log('error-->'+JSON.stringify(error));
            this.isLoading = false;
		})
    }

    handleScheduleClick(e){
        this.isLoading = true;
        scheduleApexJob({ recordId: this.recordId })
		.then(result => {
            console.log('result-->'+result);
            this.isLoading = false;
            if(result.status == 'SUCCESS'){
                this.showToast('scheduled Job',result.message,'SUCCESS');
                this.fetchRecord();
                this.dispatchEvent(new RefreshEvent());
            }else{
                this.showToast('scheduled Job',result.message,'ERROR');
                this.fetchRecord();
                this.dispatchEvent(new RefreshEvent());
            }
        })
        .catch(error =>{
            console.log('error in handleScheduleClick-->'+JSON.stringify(error));
        });
    }

    handleUnScheduleClick(e){
        console.log('schdeuled Job Id'+this.scheduleJobId);
        unScheduleApexJob({ scheduleJobId : this.scheduleJobId})
        .then(res => {
            console.log('res-->'+res);
            if(res){
                this.showToast('Unscheduled Job',res,'SUCCESS');
                this.fetchRecord();
                this.dispatchEvent(new RefreshEvent());
            }
        })
        .catch(error => {
            onsole.log('error in handleUnScheduleClick-->'+JSON.stringify(error));
        })

    }

    // showToast Function to show to toast messages based on criteria
    showToast(title,message,variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            // mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}