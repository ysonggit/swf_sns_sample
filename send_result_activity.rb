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

# **SendResultActivity** sends the result of the activity to the screen, and, if
# the user successfully registered using SNS, to the user using the SNS contact
# information collected.
class SendResultActivity < BasicActivity

  def initialize
    super('send_result_activity')
  end

  # confirm the SNS topic subscription
  def do_activity(task)
    if task.input.nil?
      @results = { :reason => "Didn't receive any input!", :detail => "" }
      return false
    end

    input = YAML.load(task.input)

    # get the topic, so we publish a message to it.
    topic = AWS::SNS::Topic.new(input[:topic_arn])

    if topic.nil?
      @results = {
        :reason => "Couldn't get SWF topic",
        :detail => "Topic ARN: #{topic.arn}" }
      return false
    end

    @results = "Thanks, you've successfully confirmed registration, and your workflow is complete!"

    # send the message via SNS, and also print it on the screen.
    topic.publish(@results)
    puts(@results)

    return true
  end
end

