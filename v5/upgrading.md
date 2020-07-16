---
layout: en
title: Upgrading
gem_version: v5
redirect_from: "/upgrading.html"
---

## Upgrading Thinking Sphinx

The [release notes](https://github.com/pat/thinking-sphinx/releases) on GitHub are a good source for what notable changes have occured in each release - and especially breaking changes.

If you're using a version of Thinking Sphinx older than v3, please refer to [older documentation](../v3/upgrading.html).

The breaking changes since v3 are:

* Tasks that were specifically for real-time indices (`ts:generate` and `ts:regenerate`) have been removed - their functionality is covered by `ts:index` and `ts:rebuild`.
* Sphinx 2.0 is no longer supported. You must use Sphinx 2.1.2 or newer (and 2.2.11 is recommended).
* Ruby 2.1 (or older) is no longer supported. Arguably the code may still work in older Ruby versions, but it's only tested against 2.2+.
* Auto-typing of filter values no longer occurs. For all search filter values, please make sure you cast them to their appropriate types (rather than string values supplied by request params).

Significant new features:

* You can now [merge SQL-backed delta indices](deltas.html#merging-delta-indices) into their corresponding core index (rather than processing _all_ the indices again).
* You can now run your daemon [on a UNIX socket](advanced_config.html#hosting-via-a-unix-socket) instead of a TCP port.
* The underlying implementation for rake tasks is more modular, which allows the `flying-sphinx` gem to connect with the `ts` tasks - thus, they can be used as per normal on Flying Sphinx Heroku apps (rather than a similar-but-different set of commands).
