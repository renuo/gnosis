# Gnosis
[![Build Status](https://renuo.semaphoreci.com/badges/gnosis/branches/main.svg?style=shields)](https://renuo.semaphoreci.com/projects/gnosis)

Gnosis connects GitHub pull requests and deployments to your Redmine issues via a custom webhook.

![](./docs/gnosis_ticket.png)

## Conventions

The plugin can do its magic if you follow one of these conventions:
* The git branch name contains the Redmine ticket number in the form `/\/\d+/`, e.g. `feature/1337-update-rails`
* The pull request description contains the Redmine ticket number in the form `/TICKET-\d+/`

Have a look at the [`NumberExtractor`](https://github.com/renuo/gnosis/blob/main/app/models/number_extractor.rb#L3) for details.

## GitHub pull request tracking

The plugin provides a webhook endpoint for GitHub to call on PR updates.
Follow these steps to configure it:
1. Go to <https://github.com/your_org/your_repo/settings/hooks>
2. Click on "Add Webhook"
3. Enter "Payload URL" to be Redmine URL + `/github_webhook`
4. The secret is up for you to decide. It's important that this string is complex and secure.
5. Click "Let me select individual events." and choose "Pull Requests".
6. Configure the env variable `GITHUB_WEBHOOK_SECRET` with the secret you chose.

You should now be good to go!

## SemaphoreCI deployment tracking

**Important:** This is optional. You can simply use pull request tracking ans skip this step.

### Configure SemaphoreCI

The plugin also provides a webhook to be called by SemaphoreCI.
Configure it like this:
1. Go to <https://your_org.semaphoreci.com/notifications>
2. Click on "New Notification"
3. Attributes like "Name of the notification" can be chosen freely. What you need to setup is: Listing your project under
"in projects", having `/.*-deploy\.yml/` under Pipelines (this just tells the notification to send data every time a
deploy script is done running), adding your Redmine URL + /semaphore_webhook to "Endpoint" and typing `WEBHOOK_SECRET`
into the "Secret name" field.
Then go to your_org.semaphoreci.com/notifications and click on "New Secret". The "Name of the Secret" should be
`WEBHOOK_SECRET`. Then you create an environment variable with the "Variable Name" `WEBHOOK_SECRET`. The "Value" is the
secret. This should match the `SEMAPHORE_WEBHOOK_SECRET` in your `config/application.yml`.  
This should now also work just fine!

### Configure GitHub access token

The plugin needs to query the GitHub API every now and then to match-up pull requests with deployments.
For that you need to set the `GITHUB_ACCESS_TOKEN` env variable. For example you can configure it like this:
1. Go to <https://github.com/settings/tokens>
2. Click on "Generate new token"
3. Click the "(classic)" option
4. Check only the "repo" box.

If you make a deployment, all should correctly work now.

## Development

You may want to add your own webhooks (e.g. if you have a different CI).
Have a look at [`webhooks_controller_test.rb`](test/functional/webhooks_controller_test.rb) for starters.

## Copyright

This work has been derived out of Anes Hodza's IPA at Renuo AG and is licensed under the MIT license.
You can find the full IPA documentation here: <https://github.com/aneshodza/ipa-documentation>.
