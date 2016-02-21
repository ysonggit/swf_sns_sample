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

# **SubscribeTopicActivity** sends an SMS / email message to the user, asking for
# confirmation.  When this action has been taken, the activity is complete.
class SubscribeTopicActivity < BasicActivity

  def initialize
    super('subscribe_topic_activity')
  end

  # Create an SNS topic and return the ARN
  def create_topic(sns_client)
    topic_arn = sns_client.create_topic(:name => 'SWF_Sample_Topic')[:topic_arn]

    if topic_arn != nil
      # For an SMS notification, setting `DisplayName` is *required*. Note that
      # only the *first 10 characters* of the DisplayName will be shown on the
      # SMS message sent to the user, so choose your DisplayName wisely!
      sns_client.set_topic_attributes( {
        :topic_arn => topic_arn,
        :attribute_name => 'DisplayName',
        :attribute_value => 'SWFSample' } )
    else
      @results = {
        :reason => "Couldn't create SNS topic", :detail => "" }.to_yaml
      return nil
    end

    return topic_arn
  end

  # Attempt to subscribe the user to an SNS Topic.
  def do_activity(task)
    activity_data = {
      :topic_arn => nil,
      :email => { :endpoint => nil, :subscription_arn => nil },
      :sms => { :endpoint => nil, :subscription_arn => nil },
    }

    if task.input != nil
      input = YAML.load(task.input)
      activity_data[:email][:endpoint] = input[:email]
      activity_data[:sms][:endpoint] = input[:sms]
    else
      @results = { :reason => "Didn't receive any input!", :detail => "" }.to_yaml
      puts("  #{@results.inspect}")
      return false
    end

    # Create an SNS client. This is used to interact with the service. Set the
    # region to $SMS_REGION, which is a region that supports SMS notifications
    # (defined in the file `swf_sns_utils.rb`).
    sns_client = AWS::SNS::Client.new(
      :config => AWS.config.with(:region => $SMS_REGION))

    # Create the topic and get the ARN
    activity_data[:topic_arn] = create_topic(sns_client)

    if activity_data[:topic_arn].nil?
      return false
    end

    # Subscribe the user to the topic, using either or both endpoints.
    [:email, :sms].each do | x |
      ep = activity_data[x][:endpoint]
      # don't try to subscribe an empty endpoint
      if (ep != nil && ep != "")
        response = sns_client.subscribe( {
          :topic_arn => activity_data[:topic_arn],
          :protocol => x.to_s, :endpoint => ep } )
        activity_data[x][:subscription_arn] = response[:subscription_arn]
      end
    end

    # if at least one subscription arn is set, consider this a success.
    if (activity_data[:email][:subscription_arn] != nil) or (activity_data[:sms][:subscription_arn] != nil)
      @results = activity_data.to_yaml
    else
      @results = { :reason => "Couldn't subscribe to SNS topic", :detail => "" }.to_yaml
      puts("  #{@results.inspect}")
      return false
    end
    return true
  end
end
