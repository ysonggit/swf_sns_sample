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

# SampleWorkflow - the main workflow for the SWF/SNS Sample
#
# See the file called `README.md` for a description of what this file does.
class SampleWorkflow

  attr_accessor :name

  def initialize(task_list)

    # the domain to look for decision tasks in.
    @domain = init_domain

    # the task list is used to poll for decision tasks.
    @task_list = task_list

    # The list of activities to run, in order. These name/version hashes can be
    # passed directly to AWS::SimpleWorkflow::DecisionTask#schedule_activity_task.
    @activity_list = [
      { :name => 'get_contact_activity', :version => 'v1' },
      { :name => 'subscribe_topic_activity', :version => 'v1' },
      { :name => 'wait_for_confirmation_activity', :version => 'v1' },
      { :name => 'send_result_activity', :version => 'v1' },
    ].reverse! # reverse the order... we're treating this like a stack.

    register_workflow
  end

  # Registers the workflow
  def register_workflow
    workflow_name = 'swf-sns-workflow'
    @workflow_type = nil

    # a default value...
    workflow_version = '1'

    # Check to see if this workflow type already exists. If so, use it.
    @domain.workflow_types.each do | a |
      if (a.name == workflow_name) && (a.version == workflow_version)
        @workflow_type = a
      end
    end

    if @workflow_type.nil?
      options =  {
        :default_child_policy => :terminate,
        :default_task_start_to_close_timeout => 3600,
        :default_execution_start_to_close_timeout => 24 * 3600 }

      puts "registering workflow: #{workflow_name}, #{workflow_version}, #{options.inspect}"
      @workflow_type = @domain.workflow_types.register(workflow_name, workflow_version, options)
    end

    puts "** registered workflow: #{workflow_name}"
  end

  # poll for decision tasks
  def poll_for_decisions
    # first, poll for decision tasks...
    @domain.decision_tasks.poll(@task_list) do | task |
      task.new_events.each do | event |
        case event.event_type
          when 'WorkflowExecutionStarted'
            # schedule the last activity on the (reversed, remember?) list to
            # begin the workflow.
            puts "** scheduling activity task: #{@activity_list.last[:name]}"

            task.schedule_activity_task( @activity_list.last,
              { :task_list => "#{@task_list}-activities" } )

          when 'ActivityTaskCompleted'
            # we are running the activities in strict sequential order, and
            # using the results of the previous activity as input for the next
            # activity.
            last_activity = @activity_list.pop

            if(@activity_list.empty?)
              puts "!! All activities complete! Sending complete_workflow_execution..."
              task.complete_workflow_execution
              return true;
            else
              # schedule the next activity, passing any results from the
              # previous activity. Results will be received in the activity
              # task.
              puts "** scheduling activity task: #{@activity_list.last[:name]}"
              if event.attributes.has_key?('result')
                task.schedule_activity_task(
                  @activity_list.last,
                  { :input => event.attributes[:result],
                    :task_list => "#{@task_list}-activities" } )
              else
                task.schedule_activity_task(
                  @activity_list.last, { :task_list => "#{@task_list}-activities" } )
              end
            end

          when 'ActivityTaskTimedOut'
            puts "!! Failing workflow execution! (timed out activity)"
            task.fail_workflow_execution
            return false

          when 'ActivityTaskFailed'
            puts "!! Failing workflow execution! (failed activity)"
            task.fail_workflow_execution
            return false

          when 'WorkflowExecutionCompleted'
            puts "## Yesss, workflow execution completed!"
            task.workflow_execution.terminate
            return false
        end
      end
    end
  end

  def start_execution
    workflow_execution = @workflow_type.start_execution( {
      :task_list => @task_list } )
    poll_for_decisions
  end
end

# if the file was run from the command-line, instantiate the class and begin the
# workflow execution.
if __FILE__ == $0
  require 'securerandom'

  # Use a different task list name every time we start a new workflow execution.
  #
  # This avoids issues if our pollers re-start before SWF considers them closed,
  # causing the pollers to get events from previously-run executions.
  task_list = SecureRandom.uuid

  # Let the user start the activity worker first...

  puts ""
  puts "Amazon SWF Example"
  puts "------------------"
  puts ""
  puts "Start the activity worker, preferably in a separate command-line window, with"
  puts "the following command:"
  puts ""
  puts "> ruby swf_sns_activities.rb #{task_list}-activities"
  puts ""
  puts "You can copy & paste it if you like, just don't copy the '>' character."
  puts ""
  puts "Press return when you're ready..."

  i = gets

  # Now, start the workflow.

  puts "Starting workflow execution."
  sample_workflow = SampleWorkflow.new(task_list)
  sample_workflow.start_execution
end

