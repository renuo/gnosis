# TICKET-25565: Introduce a new page, per project, to show what tickets have been included in each release.

- Project: Redmine-Gnosis
- Author: Alessandro Rodi
- Status: Planned
- Priority: Normal
- Tracker: Feature
- Created: 2026-04-03T09:39:36Z
- Updated: 2026-04-03T09:39:36Z
- Ongoing: 0

## Description

gnosis already records "pull_request_deployments" and "pull_requests". This means it's possible to introduce a new page per project, where we visualize a list of deployments for each deploy branch. So in this page we group by deploy branch, visually, somehow, and for each we display a list of deployments. For each deployment we have of course a link and a timestamp, but also a list of pull requests that have been included. 
The goal is to make it possible to know what has been released on each deployment.
Also a summary of the tickets would be cool.