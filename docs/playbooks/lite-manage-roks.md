# MAS Core with Manage on IBM Cloud

This master playbook will drive the following playbooks in sequence:

- [Provision & setup OCP on IBM Cloud](ocp.md#provision) (20-30 minutes)
- Install dependencies:
    - [Install MongoDb (Community Edition)](dependencies.md#install-mongodb-ce) (15 minutes)
    - [Install SLS](dependencies.md#install-sls) (10 minutes)
    - [Install BAS](dependencies.md#install-bas) (35 minutes)
    - [Install Cloud Pak for Data Operator](cp4d.md#install-cp4d) (2 minutes)
    - Install Cloud Pak for Data Services:
        - [Db2 Warehouse](cp4d.md#db2-install) with [Db2 Management Console](cp4d.md#db2-install) (1-2 hours)
    - [Create Db2 Warehouse Cluster](cp4d.md#install-db2) (60 minutes)
    - [Additional Db2 configuration for Manage](mas.md#manage-db2-hack)
- Install & configure MAS:
    - [Configure Cloud Internet Services integration](mas.md#cloud-internet-services-integration) (Optional, 1 minute)
    - [Install & configure MAS](mas.md#install-mas) (20 minutes)
- Install Manage application:
    - [Install application](mas.md#install-mas-application)
    - [Configure workspace](mas.md#configure-mas-application)

All timings are estimates, see the individual pages for each of these playbooks for more information.

!!! warning
    There is a known problem with Manage v8.1.0 that will result in the system being unusable following a successful deployment.

    Refer to the following technote for more information: ["OpenID Connect client returned with status: SEND_401" when logging in to Manage after installation](https://www.ibm.com/support/pages/openid-connect-client-returned-status-send401-when-logging-manage-after-installation)


## Preparation
Before you run the playbook you need to configure a few things in your `MAS_CONFIG_DIR`:

### Copy your entitlement license key file
Copy the MAS license key file that you obtained from Rational License Key Server to `$MAS_CONFIG_DIR/entitlement.lic` (the file must have this exact name).  During the installation of SLS this license file will be automatically bootstrapped into the system.

!!! important
    Make sure you set `SLS_LICENSE_ID` to the correct value.  For full details on what configuration options are available with the SLS install refer to the [Install SLS](dependencies.md#install-sls) topic.

### Create a Workspace template
If you want the playbook to create a workspace in MAS you must create a file named `MAS_CONFIG_DIR/workspace.yml` (the exact filename does not matter, as long as the extension is `.yml` or `.yaml` it will be processed when configuring MAS) with the following content:

```yaml
apiVersion: core.mas.ibm.com/v1
kind: Workspace
metadata:
  name: "{{instance_id}}-masdev"
  namespace: "mas-{{instance_id}}-core"
  labels:
    mas.ibm.com/instanceId: "{{instance_id}}"
    mas.ibm.com/workspaceId: "masdev"
spec:
  displayName: "MAS Development"
```

If you do not want to use a workspace called `masdev` you **must**  customize the playbook, because it is configured by default to install and configure the Manage application in this workspace.

## Required environment variables
- `IBMCLOUD_APIKEY` The API key that will be used to create a new ROKS cluster in IBMCloud
- `CLUSTER_NAME` The name to assign to the new ROKS cluster
- `MAS_INSTANCE_ID` Declare the instance ID for the MAS install
- `MAS_ENTITLEMENT_KEY` Lookup your entitlement key from the [IBM Container Library](https://myibm.ibm.com/products-services/containerlibrary)
- `MAS_CONFIG_DIR` Directory where generated config files will be saved (you may also provide pre-generated config files here)
- `SLS_LICENSE_ID` The license ID must match the license file available in `$MAS_CONFIG_DIR/entitlement.lic`
- `SLS_ENTITLEMENT_KEY` Lookup your entitlement key from the [IBM Container Library](https://myibm.ibm.com/products-services/containerlibrary)
- `BAS_CONTACT_MAIL` Defines the email for person to contact for BAS
- `BAS_CONTACT_FIRSTNAME` Defines the first name of the person to contact for BAS
- `BAS_CONTACT_LASTNAME` Defines the last name of the person to contact for BAS
- `CPD_ENTITLEMENT_KEY` Lookup your entitlement key from the [IBM Container Library](https://myibm.ibm.com/


## Optional environment variables
- `IBMCLOUD_RESOURCEGROUP` creates an IBM Cloud resource group to be used, if none are passed, `Default` resource group will be used.
- `OCP_VERSION` to override the default version of OCP to use (latest 4.6 release)
- `W3_USERNAME` to enable access to pre-release development builds of MAS
- `ARTIFACTORY_APIKEY`  to enable access to pre-release development builds of MAS
- `MONGODB_NAMESPACE` overrides the Kubernetes namespace where the MongoDb CE operator will be installed, this will default to `mongoce`
- `BAS_USERNAME` BAS default username. If not provided, default username will be `basuser`
- `BAS_PASSWORD` Defines the password for your BAS instance. If not provided, a random 15 character password will be generated
- `BAS_GRAFANA_USERNAME` Defines the username for the BAS Graphana instance, default is `basuser`
- `BAS_GRAFANA_PASSWORD` Defines the password for BAS Graphana dashboard. If not provided, a random 15 character password will be generated
- `BAS_NAMESPACE` Defines the targetted cluster namespace/project where BAS will be installed. If not provided, default BAS namespace will be `ibm-bas`
- `MAS_CATALOG_SOURCE` to override the use of the IBM Operator Catalog as the catalog source
- `MAS_CHANNEL` to override the use of the `8.x` channel
- `MAS_DOMAIN` to set a custom domain for the MAS installation
- `MAS_ICR_CP` to override the value MAS uses for the IBM Entitled Registry (`cp.icr.io/cp`)
- `MAS_ICR_CPOPEN` to override the value MAS uses for the IBM Open Registry (`icr.io/cpopen`)
- `MAS_ENTITLEMENT_USERNAME` to override the username MAS uses to access content in the IBM Entitled Registry
- `CIS_CRN` to enable integration with IBM Cloud Internet Services (CIS) for DNS & certificate management
- `CIS_SUBDOMAIN` if you want to use a subdomain within your CIS instance

!!! tip
    `MAS_ICR_CP`, `MAS_ICR_CPOPEN`, & `MAS_ENTITLEMENT_USERNAME` are primarily used when working with pre-release builds in conjunction with `W3_USERNAME`, `ARTIFACTORY_APIKEY` and the `MAS_CATALOG_SOURCE` environment variables.



## Release build
The simplest configuration to deploy a release build of IBM Maximo Application Suite (core only) with dependencies is:
```bash
# IBM Cloud ROKS configuration
export IBMCLOUD_APIKEY=xxx
export CLUSTER_NAME=xxx

# MAS configuration
export MAS_INSTANCE_ID=$CLUSTER_NAME
export MAS_ENTITLEMENT_KEY=xxx

export MAS_CONFIG_DIR=~/masconfig

# CP4D configuration
export CPD_ENTITLEMENT_KEY=xxx

# SLS configuration
export SLS_ENTITLEMENT_KEY=xxx
export SLS_LICENSE_ID=xxx

# BAS configuration
export BAS_CONTACT_MAIL=xxx@xxx.com
export BAS_CONTACT_FIRSTNAME=xxx
export BAS_CONTACT_LASTNAME=xxx

ansible-playbook playbooks/lite-manage-roks.yml
```


## Pre-release build
The simplest configuration to deploy a pre-release build (only available to IBM employees) of IBM Maximo Application Suite (core only) with dependencies is:

```bash
# IBM Cloud ROKS configuration
export IBMCLOUD_APIKEY=xxx
export CLUSTER_NAME=xxx

# Allow development catalogs to be installed
export W3_USERNAME=xxx
export ARTIFACTORY_APIKEY=xxx

# MAS configuration
export MAS_CATALOG_SOURCE=ibm-mas-operators
export MAS_CHANNEL=m1dev87
export MAS_INSTANCE_ID=$CLUSTER_NAME

export MAS_ICR_CP=wiotp-docker-local.artifactory.swg-devops.com
export MAS_ICR_CPOPEN=wiotp-docker-local.artifactory.swg-devops.com
export MAS_ENTITLEMENT_USERNAME=$W3_USERNAME_LOWERCASE
export MAS_ENTITLEMENT_KEY=$ARTIFACTORY_APIKEY

export MAS_CONFIG_DIR=~/masconfig

# CP4D configuration
export CPD_ENTITLEMENT_KEY=xxx

# SLS configuration
export SLS_ENTITLEMENT_KEY=xxx
export SLS_LICENSE_ID=xxx

# BAS configuration
export BAS_CONTACT_MAIL=xxx@xxx.com
export BAS_CONTACT_FIRSTNAME=xxx
export BAS_CONTACT_LASTNAME=xxx

ansible-playbook playbooks/lite-manage-roks.yml
```
