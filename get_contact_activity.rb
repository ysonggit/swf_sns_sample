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

# **GetContactActivity** provides a prompt for the user to enter contact
# information. When the user successfully enters contact information, the
# activity is complete.
class GetContactActivity < BasicActivity

  # initialize the activity
  def initialize
    super('get_contact_activity')
  end

  # Get some data to use to subscribe to the topic.
  def do_activity(task)
    puts ""
    puts "Please enter either an email address or SMS message (mobile phone) number to"
    puts "receive SNS notifications. You can also enter both to use both address types."
    puts ""
    puts "If you enter a phone number, it must be able to receive SMS messages, and must"
    puts "be 11 digits (such as 12065550101 to represent the number 1-206-555-0101)."

    input_confirmed = false
    while !input_confirmed
      puts ""
      print "Email: "
      email = $stdin.gets.strip

      print "Phone: "
      phone = $stdin.gets.strip

      puts ""
      if (email == '') && (phone == '')
        print "You provided no subscription information. Quit? (y/n)"
         confirmation = $stdin.gets.strip.downcase
         if confirmation == 'y'
           return false
         end
      else
         puts "You entered:"
         puts "  email: #{email}"
         puts "  phone: #{phone}"
         print "\nIs this correct? (y/n): "
         confirmation = $stdin.gets.strip.downcase
         if confirmation == 'y'
           input_confirmed = true
         end
      end
    end

    # make sure that @results is a single string. YAML makes this easy.
    @results = { :email => email, :sms => phone }.to_yaml
    return true
  end
end

