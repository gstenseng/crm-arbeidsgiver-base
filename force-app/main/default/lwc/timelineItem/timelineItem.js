import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'

export default class TimelineItem extends NavigationMixin(LightningElement) {

	@api title;
	@api object;
	@api dateValue;
	// @api expandedFieldsToDisplay;
	@api recordId;
	@track expanded;
	// @api themeInfo;


	get hasIconName() {
		return null;
	} get objectThemeColor() {
		return `background-color: #444`;
	} get itemStyle() {
		return this.expanded ? "slds-timeline__item_expandable slds-is-open" : "slds-timeline__item_expandable";
	} get totalFieldsToDisplay() {
		return 2;
	} get isCase() {
		return this.object === "Case";
	} toggleDetailSection() {
		this.expanded = !this.expanded;
	}

	navigateToRecordViewPage() {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.recordId,
				objectApiName: this.object,
				actionName: 'view'
			}
		});
	}

}