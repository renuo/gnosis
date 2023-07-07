### CI Status
|main|
|:---:|
|[![Build Status](https://renuo.semaphoreci.com/badges/gnosis/branches/main.svg?style=shields)](https://renuo.semaphoreci.com/projects/gnosis)|

# gnosis

Welcome to gnosis!
This is a Redmine Plugin with the goal of making your development process easier to keep an overview of.

## What does this plugin do?
Gnosis is able to show you GitHub Pull Requests and Deployments that belong to a Redmine issue, all in its "details"
page.  
To make this magic work there are only a few steps you have to follow and certain conventions to keep in mind.

### GitHub Webhooks configuration
To configure the GitHub Webhooks, go to github.com/your_org/your_repo/settings/hooks. There you click on
"Add Webhook". The "Payload URL" is your Redmine URL + /github_webhook. The secret is up for you to decide. It's
important that this string is complex and secure. Then, you get into your `config/application.yml`, where you add the
key as your `GITHUB_WEBHOOK_SECRET`. Click "Let me select individual events." and choose "Pull Requests".  
You should now be good to go!

### SemaphoreCI Webhooks configuration
**Important:** The GitHub notifications work without the SemaphoreCI setup. If you don't use a CI or just a different
you can skip this step.
To set up the SemaphoreCI Webhook go to your_org.semaphoreci.com/notifications and click on "New Notification".
Attributes like "Name of the notification" can be chosen freely. What you need to setup is: Listing your project under
"in projects", having `/.*-deploy\.yml/` under Pipelines (this just tells the notification to send data every time a
deploy script is done running), adding your Redmine URL + /semaphore_webhook to "Endpoint" and typing `WEBHOOK_SECRET`
into the "Secret name" field.
Then go to your_org.semaphoreci.com/notifications and click on "New Secret". The "Name of the Secret" should be
`WEBHOOK_SECRET`. Then you create an environment variable with the "Variable Name" `WEBHOOK_SECRET`. The "Value" is the
secret. This should match the `SEMAPHORE_WEBHOOK_SECRET` in your `config/application.yml`.  
This should now also work just fine!

### GitHub Access Token
This app needs to query your repository every now and then, so its able to know which deployment belongs to which pull
request. For that you need to set the `GITHUB_ACCESS_TOKEN` in your `config/application.yml`. To create it, go to
github.com/settings/tokens and click on "Generate new token". There click the "(classic)" option. It only needs "repo"
access to work.
If you make a deploy, it should correctly show now.

### Conventions you need to keep
The plugin needs information on which Pull Requests belong to which issues, which is why there are set conventions for
branch naming. When you create a branch that is connected to a certain Issue it should be named as follows:
something/issue_number-description. The only important part of this is the /issue_number as that's how
the plugin is able to connect PRs to issues.

