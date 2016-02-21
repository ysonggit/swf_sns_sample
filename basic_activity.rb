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

require_relative 'utils.rb'

# Base for activities in the SWF+SNS sample.
# Derived classes will define their own `initialize` and `do_activity` methods.
class BasicActivity

  attr_accessor :activity_type
  attr_accessor :name
  attr_accessor :results

  # Initializes a BasicActivity.
  def initialize(name, version = 'v1', options = nil)

    @activity_type = nil
    @name = name
    @results = nil

    # get the domain to use for activity tasks.
    @domain = init_domain

    # Check to see if this activity type already exists.
    @domain.activity_types.each do | a |
      if (a.name == @name) && (a.version == version)
        @activity_type = a
      end
    end

    if @activity_type.nil?
      # If no options were specified, use some reasonable defaults.
      if options.nil?
        options = {
          # All timeouts are in seconds.
          :default_task_heartbeat_timeout => 900,
          :default_task_schedule_to_start_timeout => 120,
          :default_task_schedule_to_close_timeout => 3800,
          :default_task_start_to_close_timeout => 3600 }
      end
      @activity_type = @domain.activity_types.register(@name, version, options)
    end
  end

  # Performs the activity.
  def do_activity(task)
    @results = task.input # may be nil
    return true
  end
end

