#!/bin/bash

SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $SCRIPT_PATH/..

# Check exit code function
error() {
    echo ""
    if [[ $1 -eq 0 ]]; then
        echo "Installation completed."
        echo ""
        exit $1
    else
        if [[ -n $2 ]]; then
            echo "$2"
            echo ""
        fi
        
        echo "Installation failed."
        echo ""
        exit $1
    fi
}

cleaningPreviousScratchOrg() {
    sf org delete scratch --no-prompt --target-org $org_alias &> /dev/null
}

creatingScratchOrg () {
    echo ""
    echo "Org Alias: $org_alias"
    echo ""

    if [[ -n $npm_config_org_duration ]]; then
        days=$npm_config_org_duration
    else
        days=7
    fi

    echo "Scratch org duration: $days days"
    sf org create scratch --set-default --definition-file config/project-scratch-def.json --duration-days "$days" --alias $org_alias || { error $? '"sf org create scratch" command failed.'; }
}

installDependencies() {
    keys=""
    for p in $(jq '.packageAliases | keys[]' sfdx-project.json -r);
    do
        keys+=$p":"$secret" ";
    done
    sf dependency install --installationkeys "${keys}" --targetusername "$org_alias" --targetdevhubusername "$devHubAlias" || { error $? '"sf dependency install" command failed.'; }
}

deployingMetadata() {
    if [[ $npm_config_without_deploy ]]; then
        echo "Skipping..."
    else
        sf project deploy start || { error $? '"sf project deploy start" command failed.'; }
    fi
}

assignPermission() {
    sf org assign permset \
    --name Create_reports_and_dashboards \
    --name Arbeidsgiver_WarningWrite \
    --name Arbeidsgiver_Create_and_share_reportfolders \
    --name Arbeidsgiver_Kampanje \
    --name Arbeidsgiver_NavApp \
    --name Arbeidsgiver_NavTask \
    --name Arbeidsgiver_Sykefravaer \
    --name Arbeidsgiver_arenaActivity \
    --name Arbeidsgiver_base \
    --name Arbeidsgiver_contract \
    --name Arbeidsgiver_opportunity \
    --name Arbeidsgiver_temporaryLayoffs \
    --name Arbeidsgiver_IA \
    --name ArbeidsgiverStillinger \
    --name CRM_LoginFlow \
    || { error $? '"sf org assign permset" command failed.'; }
}

insertingTestData() {
    # Creating temporary folder for test data files.
    echo "Moving test data to temp folder..."
    mkdir -p dummy-data/temp
    cp -r dummy-data/activityTimeline dummy-data/temp
    cp -r dummy-data/tag dummy-data/temp
    echo ""

    # Getting the Record Types from the new scratch org.
    echo "Getting Record Types..."
    sf data query --query "SELECT Id, SobjectType, DeveloperName FROM RecordType WHERE IsActive=true ORDER BY SObjectType, DeveloperName" --result-format json > dummy-data/temp/RecordTypes.json
    echo ""

    # Prepering Activity Timeline test data by replacing RecordType placeholders with correct Ids.
    echo "Prepering Activity Timeline test data..."
    echo "Prepering Account test data..."
    for p in $(jq '.result.records[] | select(.SobjectType=="Account") | .DeveloperName' dummy-data/temp/RecordTypes.json);
    do
        minTest=$(sed -e 's/^"//' -e 's/"$//' <<<"$p");
        replace="\$R{RecordType.Account.$(sed -e 's/^"//' -e 's/"$//' <<<"$p")}"
        replacewith=$(sed -e 's/^"//' -e 's/"$//' <<<"$(jq '.result.records[] | select(.SobjectType=="Account" and .DeveloperName=="'$minTest'") | .Id' dummy-data/temp/RecordTypes.json)");
        sed -i "" "s/$replace/$replacewith/g" "dummy-data/temp/activityTimeline/Account.json"
    done
    echo ""

    echo "Prepering Custom Opportunities test data..."
    for p in $(jq '.result.records[] | select(.SobjectType=="CustomOpportunity__c") | .DeveloperName' dummy-data/temp/RecordTypes.json);
    do
        minTest=$(sed -e 's/^"//' -e 's/"$//' <<<"$p");
        replace="\$R{RecordType.CustomOpportunity__c.$(sed -e 's/^"//' -e 's/"$//' <<<"$p")}"
        replacewith=$(sed -e 's/^"//' -e 's/"$//' <<<"$(jq '.result.records[] | select(.SobjectType=="CustomOpportunity__c" and .DeveloperName=="'$minTest'") | .Id' dummy-data/temp/RecordTypes.json)");
        sed -i "" "s/$replace/$replacewith/g" "dummy-data/temp/activityTimeline/CustomOpportunities.json"
    done
    echo ""
    echo "Activity Timeline test data prepared..."
    echo ""

    # Prepering Tag test data by replacing RecordType placeholders with correct Ids.
    echo "Prepering Tag test data..."
    echo "Prepering Account test data..."
    for p in $(jq '.result.records[] | select(.SobjectType=="Account") | .DeveloperName' dummy-data/temp/RecordTypes.json);
    do
        minTest=$(sed -e 's/^"//' -e 's/"$//' <<<"$p");
        replace="\$R{RecordType.Account.$(sed -e 's/^"//' -e 's/"$//' <<<"$p")}"
        replacewith=$(sed -e 's/^"//' -e 's/"$//' <<<"$(jq '.result.records[] | select(.SobjectType=="Account" and .DeveloperName=="'$minTest'") | .Id' dummy-data/temp/RecordTypes.json)");
        sed -i "" "s/$replace/$replacewith/g" "dummy-data/temp/tag/Accounts-B.json"
    done

    for p in $(jq '.result.records[] | select(.SobjectType=="Account") | .DeveloperName' dummy-data/temp/RecordTypes.json);
    do
        minTest=$(sed -e 's/^"//' -e 's/"$//' <<<"$p");
        replace="\$R{RecordType.Account.$(sed -e 's/^"//' -e 's/"$//' <<<"$p")}"
        replacewith=$(sed -e 's/^"//' -e 's/"$//' <<<"$(jq '.result.records[] | select(.SobjectType=="Account" and .DeveloperName=="'$minTest'") | .Id' dummy-data/temp/RecordTypes.json)");
        sed -i "" "s/$replace/$replacewith/g" "dummy-data/temp/tag/Accounts-J.json"
    done

    for p in $(jq '.result.records[] | select(.SobjectType=="Account") | .DeveloperName' dummy-data/temp/RecordTypes.json);
    do
        minTest=$(sed -e 's/^"//' -e 's/"$//' <<<"$p");
        replace="\$R{RecordType.Account.$(sed -e 's/^"//' -e 's/"$//' <<<"$p")}"
        replacewith=$(sed -e 's/^"//' -e 's/"$//' <<<"$(jq '.result.records[] | select(.SobjectType=="Account" and .DeveloperName=="'$minTest'") | .Id' dummy-data/temp/RecordTypes.json)");
        sed -i "" "s/$replace/$replacewith/g" "dummy-data/temp/tag/Accounts-O.json"
    done
    echo ""

    echo "Prepering Custom Opportunities test data..."
    for p in $(jq '.result.records[] | select(.SobjectType=="CustomOpportunity__c") | .DeveloperName' dummy-data/temp/RecordTypes.json);
    do
        minTest=$(sed -e 's/^"//' -e 's/"$//' <<<"$p");
        replace="\$R{RecordType.CustomOpportunity__c.$(sed -e 's/^"//' -e 's/"$//' <<<"$p")}"
        replacewith=$(sed -e 's/^"//' -e 's/"$//' <<<"$(jq '.result.records[] | select(.SobjectType=="CustomOpportunity__c" and .DeveloperName=="'$minTest'") | .Id' dummy-data/temp/RecordTypes.json)");
        sed -i "" "s/$replace/$replacewith/g" "dummy-data/temp/tag/CustomOpportunities.json"
    done
    echo ""

    echo "Tag test data prepared..."
    echo ""

    # Inserting the prepared test data
    echo "Inserting test data..."
    sf data import tree --plan  dummy-data/temp/activityTimeline/plan.json || { error $? '"sf data import tree" command failed.'; }
    sf data import tree --plan  dummy-data/temp/tag/plan.json || { error $? '"sf data import tree" command failed.'; }
    echo ""

    echo "Removing temporary files..."
    rm -rf dummy-data/temp
    echo ""
}

#runPostInstallScripts() {
#    sf apex run --file ./scripts/apex/activateMock.cls || { error $? '"sf apex run" command failed for Apex class: "activateMock".'; }
#    sf apex run --file ./scripts/apex/createPortalUser.cls || { error $? '"sf apex run" command failed for Apex class: "createPortalUser".'; }
#    sf apex run --file ./scripts/apex/createTestData.cls || { error $? '"sf apex run" command failed for Apex class: "createTestData".'; }
#}

#publishCommunity() {
#    if [[ $npm_config_without_publish ]]; then
#        echo "Skipping..."
#    else
#        sf community publish --name "arbeidsgiver-dialog" || { error $? '"sf community publish" command failed for community: "arbeidsgiver-dialog".'; }
#    fi
#}

openOrg() {
    if [[ -n $npm_config_open_in ]]; then
        sf org open --browser "$npm_config_open_in" --path "lightning/app/c__TAG_NAV_default" || { error $? '"sf org open" command failed.'; }
    else
        sf org open --path "lightning/app/c__TAG_NAV_default" || { error $? '"sf org open" command failed.'; }
    fi
}

info() {
    echo "Usage: npm run mac:build [options]"
    echo ""
    echo "Options:"
    echo "  --package-key=<key>         Package key to install - THIS IS REQUIRED"
    echo "  --org-alias=<alias>         Alias for the scratch org"
    echo "  --org-duration=<days>       Duration of the scratch org"
    echo "  --without-deploy            Skip deploy"
    #echo "  --without-publish           Skip publish of community: \"arbeidsgiver-dialog\""
    echo "  --open-in=<option>          Browser where the org opens."
    echo "                              <options: chrome|edge|firefox>"
    echo "  --start-step=<step-nummer>  Start from a specific step"
    echo "  --step=<step-nummer>        Run a specific step"
    #echo "                              <steps: clean=1|create=2|dependencies=3|deploy=4|permissions=5|test data=6|run scripts=7|publishing site=8|open=9>"
    echo "                              <steps: clean=1|create=2|dependencies=3|deploy=4|permissions=5|test data=6|open=7>"
    echo "  --info                      Show this help"
    echo ""
    exit 0
}

if [[ $npm_config_info ]]; then
    info
elif [[ -z $npm_config_package_key ]] && [[ -z $npm_config_step ]] && [[ -z $npm_config_start_step ]]; then
    echo "Package key is required."
    echo ""
    info
fi

sf plugins inspect @dxatscale/sfpowerscripts >/dev/null 2>&1 || { 
    echo >&2 "\"@dxatscale/sfpowerscripts\" is required, but it's not installed."
    echo "Run \"sf plugins install @dxatscale/sfpowerscripts\" to install it."
    echo ""
    echo "Aborting...."
    echo ""
    exit 1
}
sf plugins inspect sfdmu >/dev/null 2>&1 || {
    echo >&2 "\"sfdmu\" is required, but it's not installed."
    echo "Run \"sf plugins install sfdmu\" to install it."
    echo ""
    echo "Aborting..."
    echo ""
    exit 1
}

command -v jq >/dev/null 2>&1 || {
    echo >&2 "\"jq\" is required, but it's not installed."
    echo "Run \"brew install jq\" to install it if you have Homebrew installed."
    echo ""
    echo "Aborting..."
    echo ""
    exit 1
}

ORG_ALIAS="arbeidsgiver-base"
secret=$npm_config_package_key
devHubAlias=$(sf config get target-dev-hub --json | jq -r '.result[0].value')

if [[ -n $npm_config_org_alias ]]; then
    org_alias=$npm_config_org_alias
else
    org_alias=$ORG_ALIAS
fi

echo "Installing crm-arbeidsgiver-base scratch org ($org_alias)"
echo ""

operations=(
    cleaningPreviousScratchOrg
    creatingScratchOrg
    installDependencies
    deployingMetadata
    assignPermission
    insertingTestData
    #runPostInstallScripts
    #publishCommunity
    openOrg
)

operationNames=(
    "Cleaning previous scratch org"
    "Creating scratch org"
    "Installing dependencies"
    "Deploying/Pushing metadata"
    "Assigning permissions"
    "Inserting test data"
    #"Running post install scripts"
    #"Publishing arbeidsgiver-dialog site"
    "Opening org"
)

if  [[ -n $npm_config_step ]] && [[ -z $npm_config_start_step ]]; then
    if [[ "$npm_config_step" =~ ^[0-9]+$ ]] && [[ $npm_config_step -ge 1 ]]; then
        j=$((npm_config_step - 1))
    else
        echo "Invalid step number: $npm_config_step"
        exit 1
    fi

    echo "Running Step $npm_config_step/${#operations[@]}: ${operationNames[$j]}..."
    ${operations[$j]}
    echo ""
    exit 0
fi

for i in ${!operations[@]}; do
    echo "Step $((i+1))/${#operations[@]}: ${operationNames[$i]}..."
    if [[ $((i+1)) -ge $npm_config_start_step ]]; then
        ${operations[$i]}
    else
        echo "Skipping..."
    fi

    echo ""
done

error $?