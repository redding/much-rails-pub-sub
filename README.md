# MuchRailsPubSub

A Pub/Sub API/framework for MuchRails using ActiveJob.

## Setup

### Add an ActiveJob to publish events

In e.g. `app/jobs/pub_sub_publish_job.rb`:

```ruby
class PubSubPublishJob < ApplicationJob
  include MuchRailsPubSub::PublishJobBehaviors

  # add any additional desired ActiveJob configurations
  queue_as :critical
end
```

### Add a config file for event subscriptions

Create an empty config file named e.g. `config/pub_sub.rb`. This file will hold the configured event subscriptions.

### Add an initializer

This will configure the PubSubPublishJob and load subscriptions in `config/pub_sub.rb`. In e.g. `config/initializers/pub_sub.rb`:

```ruby
MuchRailsPubSub.configure do |config|
  config.publish_job = PubSubPublishJob
  config.logger = Rails.logger
end

# `MuchRailsPubSub` needs to load subscriptions after the Rails app has
# been initialized. This allows initialization callbacks to configure
# `ActiveJob` before pub/sub job classes are required and evaluated by
# loading subscriptions.
Rails.application.config.after_initialize do
  MuchRailsPubSub.load_subscriptions(Rails.root.join("config/pub_sub.rb"))
end
```

## Usage

### Add an event handler job

In e.g. `app/jobs/events/thing/create_v1_job.rb`:

```ruby
class Events::Thing::CreatedV1Job < ApplicationJob
  def perform(params)
    puts "do something when a Thing is created ..."
    puts "params: #{params.inspect}"
  end
end
```

### Subscribe the event handler job to an event

In e.g. `config/pub_sub.rb`:

```ruby
MuchRailsPubSub.subscribe "thing.created.v1",
                          job: Events::Thing::CreatedV1Job
```

### Publish the event in your code

E.g.:

```ruby
MuchRailsPubSub.publish("thing.created.v1", key: "value")
```

In the Rails logger:

```
Enqueued PubSubPublishJob (Job ID: fc834ce6-2f2d-4953-bb83-e9a272bf2a08) to Sidekiq(critical) with arguments: {"event_id"=>"5aaa5129-69b5-46fe-bff3-2e60c9749d62", "event_name"=>"thing.created.v1", "event_params"=>{:key=>"value"}}
2021-06-16T13:14:15.116Z pid=31539 tid=mxn INFO: [MuchRailsPubSub] Published "thing.created.v1":
  ID: "5aaa5129-69b5-46fe-bff3-2e60c9749d62"
  PARAMS: {:key=>"value"}

2021-06-16T13:14:15.117Z pid=31902 tid=e62 class=PubSubPublishJob jid=1e73eeee286bebe1f57a0e97 INFO: start
2021-06-16T13:14:15.126Z pid=31902 tid=e0y class=Events::Thing::CreatedV1Job jid=f22958c1fa80a4aee91b2731 INFO: start
2021-06-16T13:14:15.127Z pid=31902 tid=e62 class=PubSubPublishJob jid=1e73eeee286bebe1f57a0e97 INFO: [MuchRailsPubSub] Dispatched 1 subscription job(s) for "thing.created.v1" (5aaa5129-69b5-46fe-bff3-2e60c9749d62):
  - Events::Thing::CreatedV1Job
2021-06-16T13:14:15.127Z pid=31902 tid=e62 class=PubSubPublishJob jid=1e73eeee286bebe1f57a0e97 elapsed=0.01 INFO: done
do something when a Thing is created ...
params: {:key=>"value"}
2021-06-16T13:14:15.129Z pid=31902 tid=e0y class=Events::Thing::CreatedV1Job jid=f22958c1fa80a4aee91b2731 elapsed=0.002 INFO: done
```

## Testing

### Event Handler Jobs

These are just ActiveJobs; test them like you would test any other ActiveJob.

### Event publishes

MuchRailsPubSub comes with a `TestPublisher` and `TestingPublishedEvents` classes that produce the same side-effects of publishing an event without _actually_ publishing the event. You can then test for these side-effects, in e.g. unit tests, to verify event publishes are happening as expected.

This example assumes you are using [Assert](https://github.com/redding/assert) as your test framework. However, this can be adapted to whatever framework you use.

In e.g. `test/helper.rb`

```ruby
require "test/support/fake_logger"
require "much-rails-pub-sub"

MuchRailsPubSub.setup_test_publishing
MuchRailsPubSub.config.logger = FakeLogger.new

Assert::Context.teardown do
  MuchRailsPubSub.published_events.clear
end
```

In a test:

```ruby
MuchRailsPubSub.publish("thing.created.v1", key: "value")

latest_event = MuchRailsPubSub.published_events.last
assert_that(latest_event.name).equals("thing.created.v1")
assert_that(latest_event.params).equals(key: "value")
```

## Installation

Add this line to your application's Gemfile:

    gem "much-rails-pub-sub"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install much-rails-pub-sub

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Added some feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
