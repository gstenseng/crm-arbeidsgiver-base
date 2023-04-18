import { LightningElement, wire, api } from 'lwc';
import getBankAccountNumber from '@salesforce/apex/BankAccountController.getBankAccountNumber';

export default class BankAccountNumberViewer extends LightningElement {
    @api recordId;

    isClosed = false;
    isLoading = true;
    style = '';
    text;

    @wire(getBankAccountNumber, { recordId: '$recordId' })
    deWire(result) {
        if (result.data) {
            if (result.data.isSuccess) {
                this.text = result.data.kontonr;
            } else {
                this.text = result.data.feilmelding;
            }
            this.isLoading = false;
        } else if (result.error) {
            this.text = result.error.body.message;
            this.isLoading = false;
        }
    }


}
