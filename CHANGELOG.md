# Changelog

## Unreleased

### Deployments page lists every deployment

Main deployments without a ticket (depfu updates, small fixes pushed straight to `main`) now show up on the deployments page.
Their changes are listed under "No ticket" with the commit message.
A deployment belongs to a project when its repository has pull requests for tickets of that project.

Run the migration after updating the plugin. It backfills the existing deployments:

```sh
bundle exec rake redmine:plugins:migrate NAME=gnosis
```

## 2.0.0

### Breaking Changes

All models, controllers, and database tables are now namespaced under `Gnosis::` to avoid conflicts with Redmine 7, which introduces its own `/webhooks` endpoint and `WebhooksController`.

#### Webhook endpoints changed

Update your GitHub and SemaphoreCI webhook configurations:

| Before | After |
|---|---|
| `/github_webhook` | `/gnosis/github_webhook` |
| `/semaphore_webhook` | `/gnosis/semaphore_webhook` |
| `/sync_pull_requests` | `/gnosis/sync_pull_requests` |

#### Database tables renamed

Run the migration after updating the plugin:

```sh
bundle exec rake redmine:plugins:migrate NAME=gnosis
```

| Before | After |
|---|---|
| `pull_requests` | `gnosis_pull_requests` |
| `pull_request_deployments` | `gnosis_pull_request_deployments` |

#### Models renamed

If you reference Gnosis models in custom code, update them:

| Before | After |
|---|---|
| `PullRequest` | `Gnosis::PullRequest` |
| `PullRequestDeployment` | `Gnosis::PullRequestDeployment` |
| `NumberExtractor` | `Gnosis::NumberExtractor` |
| `WebhookHandler` | `Gnosis::WebhookHandler` |
| `PullRequestSyncService` | `Gnosis::PullRequestSyncService` |
| `SyncJob` | `Gnosis::SyncJob` |

## 1.0.0

Initial release.
