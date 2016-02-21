##
# Copyright 2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#  http://aws.amazon.com/apache2.0
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.
##

require 'yaml'
require_relative 'basic_activity.rb'

# **WaitForConfirmationActivity** waits for the user to confirm the SNS
# subscription.  When this action has been taken, the activity is complete. It
# might also time out...
class WaitForConfirmationActivity < BasicActivity

  # Initialize the class
  def initialize
    super('wait_for_confirmation_activity')
  end

  # confirm the SNS topic subscription
  def do_activity(task)
    if task.input.nil?
      @results = { :reason => "Didn't receive any input!", :detail => "" }.to_yaml
      return false
    end

    subscription_data = YAML.load(task.input)

    # get the SNS topic by using the ARN retrieved from the previous activity,
    # so we can check to see if the user has confirmed the subscription.
    topic = AWS::SNS::Topic.new(subscription_data[:topic_arn])

    if topic.nil?
      @results = {
        :reason => "Couldn't get SWF topic ARN",
        :detail => "Topic ARN: #{topic.arn}" }.to_yaml
      return false
    end

    # loop until we get some indication that a subscription was confirmed.
    subscription_confirmed = false
    while(!subscription_confirmed)
      topic.subscriptions.each do | sub |
        if subscription_data[sub.protocol.to_sym][:endpoint] == sub.endpoint
          # this is one of the endpoints we're interested in. Is it subscribed?
          if sub.arn != 'PendingConfirmation'
            subscription_data[sub.protocol.to_sym][:subscription_arn] = sub.arn
            puts "Topic subscription confirmed for (#{sub.protocol}: #{sub.endpoint})"
            @results = subscription_data.to_yaml
            return true
          else
            puts "Topic subscription still pending for (#{sub.protocol}: #{sub.endpoint})"
          end
        end
      end

      # send a heartbeat notification to SWF to keep the activity alive...
      task.record_heartbeat!(
        { :details => "#{topic.num_subscriptions_confirmed} confirmed, #{topic.num_subscriptions_pending} pending" })
      # sleep a bit.
      sleep(4.0)
    end

    # if nothing is confirmed, assume that the user did not authenticate.
    if (subscription_confirmed == false)
      @results = {
        :reason => "No subscriptions could be confirmed",
        :detail => "#{topic.num_subscriptions_confirmed} confirmed, #{topic.num_subscriptions_pending} pending" }.to_yaml
      return false
    end
  end
end
