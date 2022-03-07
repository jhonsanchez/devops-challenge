# DevOps Challenge

## Index

* [Instructions](#instructions)
* [Current Architecture](#current-architecture)
* [Current Diagram](#current-diagram)
* [Proposed Architecture](#proposed-architecture)
* [Terraform Plan](#terraform-plan-terratest)
* [CICD - Automation (Bonus)](#cicd-automation-bonus)
* [Observability (Bonus)](#observability-bonus)
* [Permissions (Bonus)](#permissions-bonus)
* [Best Practices (Bonus)](#best-practices-bonus)
* [Disaster Recovery Plan (Bonus)](#disaster-recovery-plan-bonus)
* [Compliance (Bonus)](#compliance-bonus)
* [Migration](#migration)
* [Budget (Bonus)](#budget-bonus)
* [Next Steps](#next-steps)

## Instructions

This challenge poses to test your experience on DevOps and the usual technologies applied.The most important thing for us is that you show your expertise and best practices.

Read the case specified in the Current Architecture section, and perform the steps described. We expect to see Terraform code to provision at least part of your proposed Architecture. We will consider favorably all bonus points you complete.

We have added some example modules to begin the migration into Azure. You may use them or delete them.


## Current Architecture
<details>
<summary><b>Test Details</b></summary>

---

Let’s imagine that a Bank has a monolithic architecture to handle the enrollment for new credit cards.
A potential customer will enter a bunch of data through some online forms.
Once a day there will be a batch processing job that will process all this
data. The job will trigger a monolithic application that extracts the day’s
data and run the following tasks.

• It will verify if it’s an existing customer and if it is, it will verify any
potential loans or red flags in case the customer is not eligible for a
new credit card.

• It will verify the customer’s identity. We reach an external API (e.g.
Equifax) to verify all the provided details are accurate and also verify
if there is any red flag.

• It will calculate the amount limit assigned for the credit card. It will
also auto-generate a new Credit Card number so the customer can
start using it right away until the actual credit card is received.

All the data is currently persisted on an on-premise Oracle DB. This DB
holds all the personal data the user inputs in the forms and also additional
data that will help to calculate his/her credit rating.

#### The Goal
As a company-wide initiative, we’ve been asked to
1. Migrate all our systems to a cloud provider (You may plan for AWS, Google Cloud or Azure)
2. The company is shifting to event-driven architecture with microservices
</details>

<details>
<summary><b>Tasks</b></summary>

#### The Test

This test will mix some designs (text and diagrams are expected) and
some coding. We are absolutely not aiming to build this system. We just
want to test some relevant points we’ll explicitly point out.
1. Given the 2 goals we mentioned in the previous section, imagine a
new architecture including text, diagrams, and any other useful
resource.
2. How are you going to handle the migration of data? Design a
strategy (maybe using cloud resources o anything else?) and tell us
about it.
3. Let’s assume the current DB is a traditional Oracle relational DB.
Write all the necessary scripts to migrate this data to a new DB in
the cloud. There are several options. Please explain which one you
choose and why.
4. Given the new architecture you designed let’s assume we’ll provision
new resources through Terraform. Build some of the most important
infrastructure with Terraform and build the plan for it.
5. (Bonus) What kind of monitoring would be relevant to add? What kind of
resources would be helpful to achieve this?
6. (Bonus) Give special attention how to handle exceptions if the job
stops for any reason. How do we recover? How will the deployment
process will be? Also, think about permissions, how are we giving the
cloud resources permissions?

We are expecting:
1. A detailed explanation for each step
2. The reasons to choose each resource in the cloud.
3. Details on how those resources work. 
---
</details>

## Current Diagram
![alt text](/images/current_example.png "Current diagram")

## FAQ

<details>
<summary>User / Permissions Migration</summary>

```
Are the users using auth/authentication federated service? SSO auth?

User’s apply through filling out forms without the necessity of creating an account with the bank (it is open to anyone)
so there should be no auth involved.
In the future we might incorporate federated auth that will allow us to fill out some information that we currently
request to users. So any prep work for the future would be great.
```
</details>


## Proposed Architecture

According to the goals mentioned before: 

1. Migrate all our systems to a cloud provider (You may plan for AWS, Google Cloud or Azure)
2. The company is shifting to event-driven architecture with microservices

### Cloud provider

In general terms the three major public cloud providers(AWS, Google Cloud Platform and Azure) would have in their own set of services all the tools needed to deploy our application, a few things to consider on choosing the right cloud provider are:
* Security model
* PCI compliance
* Pricing structure
* Customer service
* SLA
* Reliability & Performance
* Exit plan

In this particular test we are going to use AWS as our public cloud provider as it has many services out of the box and assuming that we have considered all the criteria from the above.

### Understanding the problem

A potential costumer would fill a form with a bunch of data, at certain time during the day -commonly during the night- a process will be triggered and run a job inside the monolithic application and it's going to run the tasks shown in the diagram.

![alt text](/images/use_cases.jpeg "Use cases diagram")

now that we have detailed the uses cases needed to replace the legacy application, let's see how looks our monolithic application

### Monolithic application

It's well known that many old banks and old companies in general started their business using monolithic applications as it was the pattern to follow at that time, it was a good pattern according to the technology of that time and the techniques to scale were also well known even when that supposed to have a great impact in the budget.

![alt text](/images/legacy_architecure.jpeg "Use cases diagram")

As we can see we have a three tier architecture and a unique database Oracle in this case.

### Event driven

As the bank is moving towards Event driven architecture, there is going to be different approaches to ingest data and also how is going to be processed, every event will trigger an action and according to the [problem](#understanding-the-problem) so at least we are going to find three events:

* When the form is sent by the potential customer
* When the external service (Equifax, Experian, etc) has verified the information and credit reports
* When the Credit card has been issued

![alt text](/images/proposed_architecture.jpg "Proposed diagram")

### Components

#### AWS Control Tower

As this application belongs to a bank we are going to work with different accounts for different purposes for instance we wouldn't like a teams that has access to our workload organisation in production have the same access to our PCI environments, depending on the location of the bank may apply some regulations to [PII](https://www.dol.gov/general/ppii#:~:text=Personal%20Identifiable%20Information%20(PII)%20is,either%20direct%20or%20indirect%20means.) and [PCI](https://www.pcicomplianceguide.org/), so in order to have governance to account and apply policies to different AWS organisations we are going to use [AWS Control Tower](https://aws.amazon.com/controltower/features/) which is a set of tools to manage multiple accounts and also have a dashboard that is going to show us if our accounts are compliance with our policies.

To organise our accounts we are going to use the best practice in AWS Control Tower according to this [documentation](https://aws.amazon.com/blogs/mt/best-practices-for-organizational-units-with-aws-organizations/) where is essentially groups of organisations with a common porpuses.

![alt text](/images/aws-organisations.jpg "AWS Organisations")

#### Cloudfront

Cloudfront is a content delivery network service that is going to be near to our customers locations, our static content will be delivered faster and also we can restrict the content of our s3 bucket [Use Cases](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/IntroductionUseCases.html)
Cloudfront is also going to prevent against most frequently occurring network and transport layer DDoS attacks

#### WAF

AWS WAF is a Web Application Firewall that is going to protect our Web App and APIs against multiple web exploits. It's going to give us control over traffic that reaches our application [documentation](https://aws.amazon.com/waf/)

#### S3 Buckets

S3 buckets are going to serve our fontend application as we are moving towards event driven we have the opportunity to migrate to a microservice environment, we are suggesting using a [React](https://reactjs.org/docs/create-a-new-react-app.html) application  for our frontend and the backend we will covered in the next section.

#### API Gateway

AWS API Gateway is a service that is going to help with create, publish, mantain, monitor and secure our API, we are using PII and PCI information so we must be sure that we are having data encrypted **at rest** and **in transit** with this service we are covering the second requirement.
According to the [documentation](https://aws.amazon.com/api-gateway/) we can find the following benefits as well:

* Run multiple versions of the same API simultaneously
* Monitor performance metrics and information on API calls
* Authorize access to your APIs with AWS Identity and Access Management (IAM)
* Provide end users with the lowest possible latency for API requests and responses
* API Gateway provides a tiered pricing model for API requests
* Create RESTful APIs using HTTP APIs or REST APIs.

#### Lambda functions

As we mentioned earlier we are using a Microservice architecture, this kind of architecture comes with particular [complexity](https://martinfowler.com/articles/microservice-trade-offs.html) including monitoring, deploys, eventual consistency, etc. But give us control and flexibility over functionality or groups of functionality.

To deal with complexity in a Microservice environment we are suggesting two approaches that are going to help us with the design.

1. [12-factor app](https://12factor.net/)

    The twelve-factor app is a methodology for building software using Microservices

  * Use declarative formats for setup automation, to minimize time and cost for new developers joining the project;
  * Have a clean contract with the underlying operating system, offering maximum portability between execution environments;
  * Are suitable for deployment on modern cloud platforms, obviating the need for servers and systems administration;
  * Minimize divergence between development and production, enabling continuous deployment for maximum agility;
  * And can scale up without significant changes to tooling, architecture, or development practices

2. Domain Driven Design [Author](https://vaughnvernon.com/) and the [book](https://www.amazon.com/Implementing-Domain-Driven-Design-Vaughn-Vernon/dp/0321834577)

    this strategy help us to create highly cohesive domains within a context and also loosely coupled between them using different tools like: bounded context, ubiquitous language, entities, etc.

Lambda functions:

* ReceivedFillingForm, this function is used to process the form submitted by our potential costumer, it's behind our API Gateway and it's going to received the form and encrypt the information to send it to the SQS Queue **check_egilibility**. Depending on the programming language of preference of the bank we would suggest using Java, Node JS or Python.
* CheckEligibility, this function will run business rules related to eligibility to a Credit Card, as rules could vary often and depends on the context of the location, we suggest using Dependency Inversion of Control and Strategy Pattern to speed new rules as needed
* CheckBureau, this function will validate information filled by the potential customer and also to check for red flags that can prevent the bank from issuing a credit card, as this function is going to consume an external service (Equifax, Experian) it's recommended to use Facade pattern to replace bureau easily.
* CalculateAmountLimit, this function is used to calculate the amount limit in the credit card and also generates a number, cardholder name and cvv so can be used immediately by the issuer, as this function handle PCI information must reside in PCI Account, this account is going to be PCI Compliance according to the regulations (PCI, SOC2, etc).

#### Amazon SQS

This [service](https://aws.amazon.com/sqs/) is going to provide the desired event driven, we can decoupled lambda functions in the previous section and scale as needed.
We are going to deploy three queues:
* check_egilibility
* check_bureau
* calculate_amount_limit

#### Amazon DMS

This service will handle the data migration from the Oracle Database to our new DynamoDB hosted in our PCI Account, we are going to use this [pattern](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/migrate-from-an-on-premises-oracle-database-or-amazon-rds-for-oracle-to-amazon-dynamodb-using-aws-dms-and-aws-sct.html) to complete the migration and plan will be specified in the corresponded section, more info about how AWS Database Migration Works in the [link](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Introduction.html)

## Requirements

In this section it's listed the requirements needed to use this application:

* AWS account with AWS Control Tower in place
* AWS Codebuild, AWS Codepipeline, AWS Codedeploy and S3 buckets for CICD
* Terraform => v0.12
* AWS CLI with credentials configured
* For Terratest --> Go v0.13

## Constraints

* Backend for Terraform State must be shared between DevOps Engineers [configuration](https://www.terraform.io/language/settings/backends/s3)
* Due to PCI compliance we will use specific AWS Account to host services involved
* Due to GDPR PII and PCI data must be encrypted at rest and in transit
* Due to GDPR data  must reside in an specific locations


## Terraform plan / Terratest

(Shown as example)

Add Output of Terraform Plan
<details>
<summary>Summary</summary>
  
```

------------------------------------------------------------------------
------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Plan: xx to add, 0 to change, 0 to destroy.


------------------------------------------------------------------------
------------------------------------------------------------------------

```
</details>

## Observability (Bonus)
What things will you consider?

```
Latency

```
<details>
<summary>Summary</summary>
  
Latency
* What: How long something takes to respond or complete
* Why: Direct impact on customer experience
* How: The time between when API Gateway recieves a request from a client and when it return a response to the cliente. Time measure in Miliseconds

</details>

```
Availability

```
<details>
<summary>Summary</summary>
  
Availability
* What: The service being available and accesible to the clients during a time, calculated as percentage
* Why: Direct impact on customer experience
* How: API Gateway shows 4xxError and 5xxError

</details>

## CICD Automation (Bonus)

![alt text](/images/cicd.jpg "cicd")
This toolchain is going to help us to deploy to different environments in our AWS Control Tower, in this first version we are not going to consider some steps in the pipeline as their are not the main focus of this test. 

## Permissions (Bonus)

![alt text](/images/Amplify_Blogpost-1024x713.png "Permissions")

As we are using AWS services to give access to specific endpoint and also to authenticate and authorise backend services we can use AWS Cognito, AWS Amplify to deletegate those security concerns to them as described in this [post](https://aws.amazon.com/blogs/mobile/building-an-application-with-aws-amplify-amazon-cognito-and-an-openid-connect-identity-provider/) with a little change as we could use AWS Cognito as our Identity Provider.

## Best Practices (Bonus)

* Enable multi-factor authentication (MFA) for privileged users
* Use Vaults (CyberArk, Hashicorp Vault) to retrieve secrets
* PCI Compliance
* 12-factor app 
* Immutable infrastructure
* Core design principles for programming
* Domain Driven Design for designing microservices



## Disaster Recovery Plan (Bonus)

* Continous Backup will be enabled for our DynamoDB
* Procedure to restore database in another location must be documented.


## Compliance (Bonus)

* GDPR (data layer stored in location - Not applicable for al countries)
* SOC 2
* Environment PCI Compliance
* Tokenization as needed
* Encryption as needed
* Least priviledged for users and services
* Transport secured between all services

## Migration

![alt text](https://cdn-images-1.medium.com/max/1600/0*WW36nabYAh5wn2v3. "Migration").

What Migration Strategy would you choose?

According to the goals described before we need to change the whole architecture of our application, in that case the most suitable migration strategy would be refactoring, in the previous sections we explained all the services required to implement this new version of our app in the cloud.

In this section we are going to assume that our application is already in place (deployed and ready to be used) both (APP and database migration solution), and we are going to discuss how can we move transparently from one environment to another with minimal impact in our users.

We are also assuming that the APP and the Migration Solution have been tested in lower environments(DEV, QA, Pre Production) with positive results.

## App Migration Plan
Explain how would you do it

Assuming that our application is already deployed and ready to be used, all the features, functionality, UI are similar we only need messages to enter in our SQS Queue to start processing data from our customers.

What we are going to do is register our domain to Route53 in our Network Account and send the traffic to our new application AWS cloudfront and API Gateway.

As environments are different from each other, all the information received by the old version are going to be processed by the old version as well, so it can be migrated with the database later and decoupled from the APP.

## Database Migration Plan

Explain how would you do it.

![alt text](/images/migration_architecture.png "migration architecture")

Now that all the information is being registered by our new APP, we only need to migrate our Oracle Database to our new solution.

We are going to use AWS SCT (AWS Schema conversion tool) to map our old schema to our new schema, this tool will be used by AWS DMS service with replicas to capture, transform and migrate data to our Dynamo DB hosted in PCI Account [documentation](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/migrate-from-an-on-premises-oracle-database-or-amazon-rds-for-oracle-to-amazon-dynamodb-using-aws-dms-and-aws-sct.html).

Depending on the size of our Oracle DB the process will take some time to migrate, eventually all the information will be in our new database and after a perior of time (Determined by some sponsor) and after being sure that the old system is not going to be needed anymore the next step would be decommission.

## Budget (Bonus)

Calculation Report (Not covered)


# Next Steps

## Anything that we need to consider in the future?

* Due to GDPR PII data should have policies regarding data retention and data removal
* Include an artifact repository to promote artifact immutability and avoid fails during deployments
* CICD: tool chaing could be improved using tools to test performance, security, and provide secrets that would robust our CICD solution
* Use Event sourcing for transactions
